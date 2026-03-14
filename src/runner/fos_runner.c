// ═══════════════════════════════════════════════════════════════════════════
//  fos_runner.c  —  flower-run  universal language runner
//
//  Build:    gcc -O2 -std=c11 -Wall -Wextra -I.. -o flower-run fos_runner.c
//  Install:  /opt/floweros/bin/flower-run
//
//  Usage:    flower-run [OPTIONS] <file> [-- extra args to pass through]
//
//    --hpc        Compile with -O3 -march=native -fopenmp, set OMP_NUM_THREADS
//    --gpu        Enable GPU path (nvcc for .cu, OpenCL flags for .c/.cpp)
//    --time       Show compile + run duration breakdown
//    --debug      Compile with -g -O0 (no HPC)
//    --verbose    Print the full compile / run command
//    --keep       Keep compiled binary after run (default: cleanup)
//    --list       Print supported language table and exit
//    --version    Print version string
//
//  Shell twin: lib/run.sh  (frun, frun_hpc, frun_time)
//  Header:     src/runner/fos_runner.h  (language table, GPU detection)
//
// ───────────────────────────────────────────────────────────────────────────
//  HPC contract
//  "--hpc" means REAL parallelism flags, not aesthetic.
//   • C/C++/Fortran:  -O3 -march=native -ffast-math -fopenmp
//                     OMP_NUM_THREADS=$(nproc)
//   • Python:         OMP_NUM_THREADS=$(nproc) for NumPy/SciPy BLAS
//   • Julia:          --threads $(nproc)
//   • Go:             GOMAXPROCS=$(nproc)
//   • CUDA (.cu):     nvcc --use_fast_math -O3
//
//  Architecture note (one line):
//    flower-run hello.c  →  same binary, any language, all tiers
// ═══════════════════════════════════════════════════════════════════════════

#define _POSIX_C_SOURCE 200809L

#include "../floweros.h"
#include "fos_runner.h"

#include <sys/stat.h>
#include <fcntl.h>
#include <libgen.h>

// ─────────────────────────────────────────────────────────────────────────
//  Runner context  (assembled from CLI args)
// ─────────────────────────────────────────────────────────────────────────

typedef struct {
    const char *filepath;         // source file path
    int         flags;            // FOS_RUN_* bitmask
    const char *extra_args;       // passed after -- to the program
    char        tmp_bin[512];     // path to compiled binary (temp)
    int         tmp_bin_used;     // 1 if tmp_bin was populated
} RunCtx;

// ─────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────

static void print_version(void) {
    printf(FOS_ACC "flower-run" FOS_RST " " FLOWEROS_VERSION
           "  (FlowerOS universal runner)\n");
}

static void print_help(void) {
    print_version();
    printf("\n"
        FOS_DIM "Usage:" FOS_RST "  flower-run [OPTIONS] <file> [-- program-args]\n\n"
        FOS_DIM "Options:" FOS_RST "\n"
        "  " FOS_ACC "--hpc" FOS_RST "       -O3 -march=native -fopenmp, OMP_NUM_THREADS=nproc\n"
        "  " FOS_ACC "--gpu" FOS_RST "       Enable GPU path (nvcc / OpenCL flags)\n"
        "  " FOS_ACC "--time" FOS_RST "      Show compile + run duration\n"
        "  " FOS_ACC "--debug" FOS_RST "     -g -O0, no HPC flags\n"
        "  " FOS_ACC "--verbose" FOS_RST "   Print full compile / run command\n"
        "  " FOS_ACC "--keep" FOS_RST "      Keep compiled binary after run\n"
        "  " FOS_ACC "--list" FOS_RST "      Print supported language table\n"
        "  " FOS_ACC "--version" FOS_RST "   Print version\n\n"
        FOS_DIM "Examples:" FOS_RST "\n"
        "  flower-run hello.c\n"
        "  flower-run --hpc simulate.c\n"
        "  flower-run --hpc --time model.py\n"
        "  flower-run --gpu particles.cu\n"
        "  flower-run --debug --verbose analysis.cpp\n"
        "  flower-run script.sh\n\n"
        FOS_DIM "Shell twin:" FOS_RST "  source lib/run.sh  &&  frun <file>\n\n");
}

static void print_list(void) {
    printf("\n" FOS_MAG FOS_BOLD "  flower-run  —  supported languages\n" FOS_RST);
    printf(FOS_DIM
        "  ─────────────────────────────────────────────────────────────\n"
        "  %-14s  %-12s  %-28s  %s\n"
        "  ─────────────────────────────────────────────────────────────\n"
        FOS_RST, "Extension(s)", "Language", "HPC flags", "GPU");

    for (int i = 0; FOS_LANG_TABLE[i].ext != NULL; i++) {
        const FosLang *L = &FOS_LANG_TABLE[i];
        printf("  " FOS_ACC "%-14s" FOS_RST "  %-12s  " FOS_DIM "%-28s" FOS_RST "  %s\n",
            L->ext,
            L->name,
            L->hpc_cflags  ? L->hpc_cflags  :
            L->hpc_env     ? L->hpc_env      : "—",
            L->gpu_compiler ? FOS_GRN "✓" FOS_RST : FOS_DIM "—" FOS_RST);
    }
    printf("\n");
}

// ─────────────────────────────────────────────────────────────────────────
//  Compile step  —  build temp binary, return 0 on success
// ─────────────────────────────────────────────────────────────────────────

static int do_compile(const RunCtx *ctx, const FosLang *L,
                      long long *compile_ns_out) {
    // Choose compiler: GPU override if --gpu and available
    const char *cc = L->compiler;
    const char *cflags;
    int hpc = ctx->flags & FOS_RUN_HPC;
    int dbg = ctx->flags & FOS_RUN_DEBUG;
    int gpu = ctx->flags & FOS_RUN_GPU;

    if (gpu && L->gpu_compiler) {
        cc = L->gpu_compiler;
        cflags = hpc ? L->gpu_flags : "-O2";
    } else if (dbg) {
        cflags = "-g -O0";
    } else if (hpc && L->hpc_cflags) {
        // base + HPC flags combined
        static char hpc_combined[512];
        snprintf(hpc_combined, sizeof(hpc_combined),
                 "%s %s",
                 L->base_cflags ? L->base_cflags : "",
                 L->hpc_cflags);
        cflags = hpc_combined;
    } else {
        cflags = L->base_cflags ? L->base_cflags : "";
    }

    // For Java: javac outputs .class files, not a binary
    int is_java = (strcmp(L->name, "Java") == 0);
    if (!is_java) {
        // Build temp binary path
        snprintf((char *)ctx->tmp_bin, 512, "/tmp/frun_%d", (int)getpid());
    }

    // Build compile command
    char cmd[4096];
    if (is_java) {
        // javac writes .class to the file's directory
        snprintf(cmd, sizeof(cmd), "%s %s",
                 cc, ctx->filepath);
    } else {
        snprintf(cmd, sizeof(cmd), "%s %s -o %s %s",
                 cc,
                 cflags,
                 ctx->tmp_bin,
                 ctx->filepath);
    }

    if (ctx->flags & FOS_RUN_VERBOSE)
        printf(FOS_DIM "  $ %s\n" FOS_RST, cmd);

    printf(FOS_ACC "✿" FOS_RST " [%s]  Compiling %s...\n", L->name,
           ctx->filepath);

    long long t0 = fos_time_ns();
    int rc = system(cmd);
    long long t1 = fos_time_ns();

    *compile_ns_out = t1 - t0;

    if (rc != 0) {
        fos_err("Compilation failed.");
        return 1;
    }
    if (ctx->flags & FOS_RUN_TIME)
        fos_print_duration("Compile", *compile_ns_out);
    fos_ok("Compiled.");
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Run step  —  exec the program, return its exit code
// ─────────────────────────────────────────────────────────────────────────

static int do_run(const RunCtx *ctx, const FosLang *L,
                  long long *run_ns_out) {
    int hpc  = ctx->flags & FOS_RUN_HPC;
    int ncpu = hpc ? fos_nproc() : 1;
    char cmd[4096] = {0};

    // ── HPC environment injection ─────────────────────────────────────
    // Set env vars BEFORE the command string (sh -c "VAR=X cmd")
    char env_prefix[256] = {0};
    if (hpc && L->hpc_env) {
        snprintf(env_prefix, sizeof(env_prefix),
                 "%s=%d ", L->hpc_env, ncpu);
    }

    // ── Build run command ─────────────────────────────────────────────
    if (L->compiler && strcmp(L->name, "Java") != 0) {
        // Compiled binary — run directly
        snprintf(cmd, sizeof(cmd), "%s%s %s",
                 env_prefix,
                 ctx->tmp_bin,
                 ctx->extra_args ? ctx->extra_args : "");

    } else if (strcmp(L->name, "Java") == 0) {
        // Strip path and .class extension to get class name
        char base[256];
        strncpy(base, ctx->filepath, sizeof(base) - 1);
        char *dot = strrchr(base, '.');
        if (dot) *dot = '\0';
        char *slash = strrchr(base, '/');
        const char *classname = slash ? slash + 1 : base;
        char dir[256];
        strncpy(dir, ctx->filepath, sizeof(dir) - 1);
        char *d = strrchr(dir, '/');
        if (d) *d = '\0'; else strncpy(dir, ".", sizeof(dir));
        snprintf(cmd, sizeof(cmd), "cd '%s' && %sjava %s %s",
                 dir, env_prefix, classname,
                 ctx->extra_args ? ctx->extra_args : "");

    } else if (strcmp(L->name, "Julia") == 0 && hpc) {
        // Julia HPC: inject --threads N into runner args
        char threads[64];
        snprintf(threads, sizeof(threads), "--threads %d", ncpu);
        snprintf(cmd, sizeof(cmd), "%s%s %s %s %s",
                 env_prefix, L->runner, threads,
                 ctx->filepath,
                 ctx->extra_args ? ctx->extra_args : "");

    } else {
        // Interpreted runner
        snprintf(cmd, sizeof(cmd), "%s%s %s %s",
                 env_prefix, L->runner,
                 ctx->filepath,
                 ctx->extra_args ? ctx->extra_args : "");
    }

    if (ctx->flags & FOS_RUN_VERBOSE)
        printf(FOS_DIM "  $ %s\n" FOS_RST, cmd);

    // HPC summary line
    if (hpc && L->is_hpc_capable)
        printf(FOS_GRN "✿" FOS_RST
               FOS_DIM "  HPC: %d threads" FOS_RST "\n", ncpu);

    printf(FOS_ACC "🌱 Running..." FOS_RST "\n");
    printf(FOS_DIM "────────────────────────────────\n" FOS_RST);

    long long t0 = fos_time_ns();
    int rc = system(cmd);
    long long t1 = fos_time_ns();
    *run_ns_out = t1 - t0;

    int exit_code = WIFEXITED(rc) ? WEXITSTATUS(rc) : 127;

    printf(FOS_DIM "────────────────────────────────\n" FOS_RST);

    if (ctx->flags & FOS_RUN_TIME)
        fos_print_duration("Run", *run_ns_out);

    if (exit_code == 0)
        fos_ok("Exit 0");
    else {
        char ebuf[64];
        snprintf(ebuf, sizeof(ebuf), "Exit %d", exit_code);
        fos_err(ebuf);
    }
    return exit_code;
}

// ─────────────────────────────────────────────────────────────────────────
//  Cleanup  —  remove temp binary unless --keep
// ─────────────────────────────────────────────────────────────────────────

static void do_cleanup(const RunCtx *ctx) {
    if (ctx->tmp_bin_used && !(ctx->flags & FOS_RUN_KEEP))
        unlink(ctx->tmp_bin);
}

// ─────────────────────────────────────────────────────────────────────────
//  GPU availability warning
// ─────────────────────────────────────────────────────────────────────────

static void check_gpu_flag(int flags, const FosLang *L) {
    if (!(flags & FOS_RUN_GPU)) return;
    FosGPUKind gpu = fos_detect_gpu();
    if (gpu == GPU_NONE) {
        fos_warn("--gpu set but no CUDA/OpenCL device detected.");
        fos_warn("Continuing with software fallback flags.");
    } else if (gpu == GPU_CUDA) {
        fos_ok("GPU: CUDA device detected.");
        if (!L->gpu_compiler)
            fos_warn("Language has no dedicated GPU compiler. HPC flags only.");
    } else {
        fos_ok("GPU: OpenCL device detected.");
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  main
// ─────────────────────────────────────────────────────────────────────────

int main(int argc, char **argv) {
    if (argc < 2) { print_help(); return 1; }

    RunCtx ctx = {0};
    int  i;

    // ── Parse args ──────────────────────────────────────────────────────
    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--help")    == 0 || strcmp(argv[i], "-h") == 0)
            { print_help();    return 0; }
        if (strcmp(argv[i], "--version") == 0) { print_version(); return 0; }
        if (strcmp(argv[i], "--list")    == 0) { print_list();    return 0; }
        if (strcmp(argv[i], "--hpc")     == 0) { ctx.flags |= FOS_RUN_HPC;     continue; }
        if (strcmp(argv[i], "--gpu")     == 0) { ctx.flags |= FOS_RUN_GPU;     continue; }
        if (strcmp(argv[i], "--time")    == 0) { ctx.flags |= FOS_RUN_TIME;    continue; }
        if (strcmp(argv[i], "--debug")   == 0) { ctx.flags |= FOS_RUN_DEBUG;   continue; }
        if (strcmp(argv[i], "--verbose") == 0) { ctx.flags |= FOS_RUN_VERBOSE; continue; }
        if (strcmp(argv[i], "--keep")    == 0) { ctx.flags |= FOS_RUN_KEEP;    continue; }
        if (strcmp(argv[i], "--")        == 0) { ctx.extra_args = argv[i+1]; break; }
        // First non-flag = source file
        if (!ctx.filepath) { ctx.filepath = argv[i]; continue; }
    }

    if (!ctx.filepath) {
        fos_err("No source file specified.");
        print_help();
        return 1;
    }

    if (access(ctx.filepath, R_OK) != 0) {
        fprintf(stderr, FOS_RED "✗" FOS_RST " Cannot read: %s\n", ctx.filepath);
        return 1;
    }

    // ── Language detection ────────────────────────────────────────────
    const FosLang *L = fos_lang_detect(ctx.filepath);
    if (!L) {
        fprintf(stderr, FOS_RED "✗" FOS_RST
                " Unknown extension: %s\n"
                FOS_DIM "  Run flower-run --list for supported languages.\n"
                FOS_RST, ctx.filepath);
        return 1;
    }

    // ── GPU check ────────────────────────────────────────────────────
    check_gpu_flag(ctx.flags, L);

    // ── HPC + debug conflict ─────────────────────────────────────────
    if ((ctx.flags & FOS_RUN_HPC) && (ctx.flags & FOS_RUN_DEBUG)) {
        fos_warn("--hpc and --debug are mutually exclusive. Using --debug.");
        ctx.flags &= ~FOS_RUN_HPC;
    }

    long long compile_ns = 0, run_ns = 0;
    int rc = 0;

    // ── Compile step (compiled languages only) ────────────────────────
    if (L->compiler) {
        rc = do_compile(&ctx, L, &compile_ns);
        if (rc != 0) return rc;
        ctx.tmp_bin_used = (strcmp(L->name, "Java") != 0);
    }

    // ── Run step ─────────────────────────────────────────────────────
    rc = do_run(&ctx, L, &run_ns);

    // ── Total timing ─────────────────────────────────────────────────
    if ((ctx.flags & FOS_RUN_TIME) && L->compiler)
        fos_print_duration("Total", compile_ns + run_ns);

    // ── Cleanup ───────────────────────────────────────────────────────
    do_cleanup(&ctx);

    return rc;
}
