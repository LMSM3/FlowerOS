// ═══════════════════════════════════════════════════════════════════════════
//  fos_runner.h  —  FlowerOS Universal Language Runner  (include-once header)
//
//  Include in any C file that needs to compile/run source in other languages.
//  The flower-run binary is the production CLI; this header is the engine.
//
//  Supported languages and HPC capabilities:
//
//  ext       Language      Compile?   HPC flags              GPU?
//  ────────  ────────────  ─────────  ─────────────────────  ────
//  c/h       C             gcc        -O3 -fopenmp           OpenCL host
//  cpp/cc    C++           g++        -O3 -fopenmp           OpenCL/CUDA
//  cu        CUDA          nvcc       -O3 --use_fast_math    ✓ native
//  py        Python        —          OMP_NUM_THREADS=N      via numpy/cupy
//  jl        Julia         —          --threads N            native
//  rs        Rust          rustc      -O (rayon in code)     —
//  go        Go            —          GOMAXPROCS=N           —
//  f90/f95   Fortran       gfortran   -O3 -fopenmp           —
//  hs        Haskell       —          +RTS -N                —
//  java      Java          javac      —                      —
//  js        JavaScript    —          --max-old-space-size   —
//  sh/bash   Shell         —          —                      —
//  rb        Ruby          —          —                      —
//  lua       Lua           —          —                      —
//  pl        Perl          —          —                      —
//  r         R             —          —                      —
//  m         Octave        —          --eval                 —
//
// ───────────────────────────────────────────────────────────────────────────
//  Shell twin:  lib/run.sh  (frun / frun_hpc / frun_time functions)
//  C binary:    src/runner/fos_runner.c  →  flower-run
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FOS_RUNNER_H
#define FOS_RUNNER_H

#define _POSIX_C_SOURCE 200809L

#include <stdlib.h>
#include <string.h>
#include <strings.h>   /* strcasecmp */
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

// ─────────────────────────────────────────────────────────────────────────
//  Runner flags  (bit-mask, passed to fos_runner_run())
// ─────────────────────────────────────────────────────────────────────────

#define FOS_RUN_DEFAULT   0x00   // -O2, no OpenMP, single thread
#define FOS_RUN_HPC       0x01   // -O3 -march=native -fopenmp, nproc threads
#define FOS_RUN_DEBUG     0x02   // -g -O0, no optimization
#define FOS_RUN_TIME      0x04   // print compile + run duration
#define FOS_RUN_VERBOSE   0x08   // print the full compile/run command
#define FOS_RUN_KEEP      0x10   // don't delete compiled binary after run
#define FOS_RUN_GPU       0x20   // enable GPU path (nvcc / OpenCL / CUDA flags)

// ─────────────────────────────────────────────────────────────────────────
//  Language descriptor
//  One row per language.  The table is terminated by a {NULL} sentinel.
//
//  Fields:
//    ext[]          - recognised file extensions (comma-separated, no dots)
//    name           - human display name
//    compiler       - compile command (NULL = interpreted, run directly)
//    base_cflags    - default compile flags
//    hpc_cflags     - extra flags added when FOS_RUN_HPC is set
//    runner         - interpreter command (NULL = run compiled binary)
//    hpc_env        - env var to set for HPC mode (e.g. "OMP_NUM_THREADS")
//    gpu_compiler   - GPU-specific compiler override (NULL = no GPU path)
//    gpu_flags      - GPU compile flags
//    is_hpc_capable - non-zero if this language has meaningful HPC flags
// ─────────────────────────────────────────────────────────────────────────

typedef struct {
    const char *ext;           // "c"  /  "cpp,cc,cxx"
    const char *name;
    const char *compiler;      // NULL = interpreted
    const char *base_cflags;
    const char *hpc_cflags;
    const char *runner;        // NULL = run compiled binary ./out
    const char *hpc_env;       // NULL = no env injection
    const char *gpu_compiler;  // NULL = no dedicated GPU path
    const char *gpu_flags;
    int         is_hpc_capable;
} FosLang;

// ─────────────────────────────────────────────────────────────────────────
//  The language table
//  Matches lib/run.sh LANG_TABLE exactly — both must stay in sync.
//  Real flags only — no visual-only approximations.
// ─────────────────────────────────────────────────────────────────────────

static const FosLang FOS_LANG_TABLE[] = {
    // ── Compiled ─────────────────────────────────────────────────────────
    {
        "c",
        "C",
        "gcc",
        "-O2 -std=c11 -Wall -Wextra",
        "-O3 -march=native -ffast-math -fopenmp",
        NULL,
        "OMP_NUM_THREADS",
        NULL,   // use clang-opencl or separate .cl file for GPU
        NULL,
        1,
    },
    {
        "cpp,cc,cxx",
        "C++",
        "g++",
        "-O2 -std=c++17 -Wall -Wextra",
        "-O3 -march=native -ffast-math -fopenmp",
        NULL,
        "OMP_NUM_THREADS",
        "nvcc",
        "--use_fast_math -O3 -Xcompiler -fopenmp",
        1,
    },
    {
        "cu",
        "CUDA",
        "nvcc",
        "-O2",
        "-O3 --use_fast_math -Xcompiler -fopenmp",
        NULL,
        "OMP_NUM_THREADS",
        "nvcc",    // cu is always GPU
        "--use_fast_math -O3",
        1,
    },
    {
        "rs",
        "Rust",
        "rustc",
        "-O",
        "-O",     // Rust parallelism is in the library (rayon); no CLI flag
        NULL,
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "f90,f95,f03,f08,for",
        "Fortran",
        "gfortran",
        "-O2 -Wall",
        "-O3 -march=native -ffast-math -fopenmp",
        NULL,
        "OMP_NUM_THREADS",
        NULL,
        NULL,
        1,
    },
    {
        "java",
        "Java",
        "javac",
        NULL,
        NULL,
        "java",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "hs",
        "Haskell",
        NULL,
        NULL,
        NULL,
        "runghc",
        NULL,
        NULL,
        NULL,
        0,
    },
    // ── Interpreted ───────────────────────────────────────────────────────
    {
        "py,pyw",
        "Python",
        NULL,
        NULL,
        NULL,
        "python3",
        "OMP_NUM_THREADS",   // used by NumPy/SciPy BLAS threading
        NULL,
        NULL,
        1,   // numpy/scipy/cupy respect OMP_NUM_THREADS and CUDA_VISIBLE_DEVICES
    },
    {
        "jl",
        "Julia",
        NULL,
        NULL,
        "--threads auto",    // injected into runner args in HPC mode
        "julia",
        NULL,
        NULL,
        NULL,
        1,
    },
    {
        "go",
        "Go",
        NULL,
        NULL,
        NULL,
        "go run",
        "GOMAXPROCS",        // set to nproc in HPC mode
        NULL,
        NULL,
        1,
    },
    {
        "sh,bash",
        "Shell",
        NULL,
        NULL,
        NULL,
        "bash",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "js,mjs",
        "JavaScript",
        NULL,
        NULL,
        NULL,
        "node",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "rb",
        "Ruby",
        NULL,
        NULL,
        NULL,
        "ruby",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "lua",
        "Lua",
        NULL,
        NULL,
        NULL,
        "lua",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "pl",
        "Perl",
        NULL,
        NULL,
        NULL,
        "perl",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "r",
        "R",
        NULL,
        NULL,
        NULL,
        "Rscript",
        NULL,
        NULL,
        NULL,
        0,
    },
    {
        "m",
        "Octave",
        NULL,
        NULL,
        NULL,
        "octave",
        NULL,
        NULL,
        NULL,
        0,
    },
    { NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0 }, // sentinel
};

// ─────────────────────────────────────────────────────────────────────────
//  fos_lang_detect  —  look up language by file extension
//  Returns pointer into FOS_LANG_TABLE or NULL if not recognised.
// ─────────────────────────────────────────────────────────────────────────

static inline const FosLang *fos_lang_detect(const char *filepath) {
    // Extract extension after the last dot
    const char *dot = strrchr(filepath, '.');
    if (!dot || dot[1] == '\0') return NULL;
    const char *ext = dot + 1;

    for (int i = 0; FOS_LANG_TABLE[i].ext != NULL; i++) {
        // ext field may be comma-separated ("cpp,cc,cxx")
        char buf[64];
        strncpy(buf, FOS_LANG_TABLE[i].ext, sizeof(buf) - 1);
        buf[sizeof(buf) - 1] = '\0';
        char *tok = strtok(buf, ",");
        while (tok) {
            if (strcasecmp(tok, ext) == 0) return &FOS_LANG_TABLE[i];
            tok = strtok(NULL, ",");
        }
    }
    return NULL;
}

// ─────────────────────────────────────────────────────────────────────────
//  fos_nproc  —  number of logical CPUs (for HPC thread count)
//  Reads /proc/cpuinfo on Linux; falls back to 1.
// ─────────────────────────────────────────────────────────────────────────

static inline int fos_nproc(void) {
    FILE *f = popen("nproc 2>/dev/null", "r");
    if (!f) return 1;
    int n = 1;
    fscanf(f, "%d", &n);
    pclose(f);
    return (n > 0) ? n : 1;
}

// ─────────────────────────────────────────────────────────────────────────
//  fos_has_gpu  —  detect CUDA or OpenCL device
//  Real detection via nvidia-smi / clinfo — not a visual approximation.
// ─────────────────────────────────────────────────────────────────────────

typedef enum { GPU_NONE = 0, GPU_CUDA, GPU_OPENCL } FosGPUKind;

static inline FosGPUKind fos_detect_gpu(void) {
    if (system("command -v nvidia-smi >/dev/null 2>&1") == 0 &&
        system("nvidia-smi >/dev/null 2>&1") == 0)
        return GPU_CUDA;
    if (system("command -v clinfo >/dev/null 2>&1") == 0)
        return GPU_OPENCL;
    return GPU_NONE;
}

// ─────────────────────────────────────────────────────────────────────────
//  fos_time_ns  —  monotonic nanosecond timestamp
// ─────────────────────────────────────────────────────────────────────────

static inline long long fos_time_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

static inline void fos_print_duration(const char *label, long long ns) {
    if (ns < 1000000LL)
        printf("  \033[38;5;245m%s:\033[0m  \033[38;5;229m%.3f µs\033[0m\n",
               label, (double)ns / 1000.0);
    else if (ns < 1000000000LL)
        printf("  \033[38;5;245m%s:\033[0m  \033[38;5;229m%.3f ms\033[0m\n",
               label, (double)ns / 1000000.0);
    else
        printf("  \033[38;5;245m%s:\033[0m  \033[38;5;229m%.3f s\033[0m\n",
               label, (double)ns / 1000000000.0);
}

#endif // FOS_RUNNER_H
