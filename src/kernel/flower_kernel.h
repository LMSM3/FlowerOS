// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Kernel - Core Operating System
//  v1.3.0 - Parasitic Attach Architecture
//
//  Security model: Thorns (defense subsystem)
//  Production: Parasitic integration with Debian/AlmaLinux host kernel
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWEROS_KERNEL_H
#define FLOWEROS_KERNEL_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// ═══════════════════════════════════════════════════════════════════════════
//  Kernel Version & Build Information
// ═══════════════════════════════════════════════════════════════════════════

#define FLOWEROS_VERSION_MAJOR 1
#define FLOWEROS_VERSION_MINOR 3
#define FLOWEROS_VERSION_PATCH 0
#define FLOWEROS_VERSION_STRING "1.3.0-hpc-demo"
#define FLOWEROS_KERNEL_NAME "FlowerOS-5.19.0-flower"

// Build types
#define FLOWEROS_BUILD_BARE_METAL  1  // True bare metal OS
#define FLOWEROS_BUILD_PARASITIC   2  // Parasitic on Debian/AlmaLinux (production)
#define FLOWEROS_BUILD_CONTAINER   3  // Container-based

#ifndef FLOWEROS_BUILD_TYPE
#define FLOWEROS_BUILD_TYPE FLOWEROS_BUILD_PARASITIC  // Default: Parasitic (secure)
#endif

// ═══════════════════════════════════════════════════════════════════════════
//  Plant Palette Configuration (Unicode Symbols)
// ═══════════════════════════════════════════════════════════════════════════

// Palette #1 - Primary botanical symbols
#define FLOWER_SYMBOL_SHAMROCK    "☘"   // Alt + 9752
#define FLOWER_SYMBOL_MAPLE       "🍁"  // Alt + 127809
#define FLOWER_SYMBOL_SEEDLING    "🌱"  // Alt + 127793
#define FLOWER_SYMBOL_EGGPLANT    "🍆"  // Alt + 127810
#define FLOWER_SYMBOL_WHEAT       "🌾"  // Alt + 127796
#define FLOWER_SYMBOL_HERB        "🌿"  // Alt + 127799 (dashed leaf)
#define FLOWER_SYMBOL_CACTUS      "🌵"  // Alt + 127797
#define FLOWER_SYMBOL_BRANCH      "🌿"  // Alt + 127807
#define FLOWER_SYMBOL_CLOVER      "🍀"  // Alt + 127808

// Palette #2 - Flower symbols
#define FLOWER_SYMBOL_FLOWER1     "✿"   // Alt + 10047
#define FLOWER_SYMBOL_FLOWER2     "⚘"   // Alt + 9880
#define FLOWER_SYMBOL_FLEUR       "⚜"   // Alt + 9884
#define FLOWER_SYMBOL_HEART_FLOWER "❦"  // Alt + 10046
#define FLOWER_SYMBOL_FLOWER3     "❁"   // Alt + 10049
#define FLOWER_SYMBOL_FLOWER4     "✾"   // Alt + 10046
#define FLOWER_SYMBOL_FLOWER5     "❀"   // Alt + 10048
#define FLOWER_SYMBOL_FLOWER6     "❃"   // Alt + 10051
#define FLOWER_SYMBOL_BLOSSOM     "🌼"  // Alt + 127804
#define FLOWER_SYMBOL_FLOWER7     "✽"   // Alt + 10045
#define FLOWER_SYMBOL_FLOWER8     "✻"   // Alt + 10043

// ═══════════════════════════════════════════════════════════════════════════
//  Color Palette Configuration (Root-level toggleable)
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    bool colors_enabled;
    bool unicode_enabled;
    uint8_t palette_id;  // 1 or 2
    
    // ANSI color codes
    const char* color_primary;    // Green (botanical)
    const char* color_secondary;  // Magenta (flowers)
    const char* color_accent;     // Cyan (water)
    const char* color_warning;    // Yellow
    const char* color_error;      // Red
    const char* color_success;    // Bright green
    const char* color_info;       // Blue
    const char* color_reset;      // Reset
} flower_palette_config_t;

// Default palette configuration
#define FLOWER_PALETTE_DEFAULT {     \
    .colors_enabled = true,          \
    .unicode_enabled = true,         \
    .palette_id = 1,                 \
    .color_primary = "\033[32m",     \
    .color_secondary = "\033[35m",   \
    .color_accent = "\033[36m",      \
    .color_warning = "\033[33m",     \
    .color_error = "\033[31m",       \
    .color_success = "\033[92m",     \
    .color_info = "\033[34m",        \
    .color_reset = "\033[0m"         \
}

// ═══════════════════════════════════════════════════════════════════════════
//  Kernel Subsystems (Plant-Themed Naming)
// ═══════════════════════════════════════════════════════════════════════════

// Germination - Boot process
typedef struct {
    uint64_t boot_time_ns;
    uint32_t hardware_seed;       // "Seeding" - Hardware RNG for initialization
    bool germinated;              // Boot complete
    const char* germination_log;  // Boot log
} flower_germination_t;

// Rooting - System integration (already exists in Rooter.hpp)
typedef struct {
    bool rooted;                  // System integrated
    const char* root_path;        // /opt/floweros
    const char* config_path;      // /etc/floweros
    uint32_t integration_level;   // Line 12, etc.
} flower_rooting_t;

// Photosynthesis - Resource management (CPU, RAM, GPU)
typedef struct {
    uint64_t cpu_cores;
    uint64_t ram_bytes;
    uint64_t gpu_vram_bytes;
    uint32_t gpu_count;
    
    // Resource conversion rates
    float energy_efficiency;      // "Photosynthesis" efficiency
    float compute_yield;          // Operations per watt
} flower_photosynthesis_t;

// Blooming - Process spawning
typedef struct {
    uint64_t process_id;
    const char* process_name;
    uint64_t bloom_time_ns;       // "Blooming" - Process creation time
    bool bloomed;                 // Process active
} flower_bloom_t;

// Wilting - Process termination
typedef struct {
    uint64_t process_id;
    uint64_t wilt_time_ns;        // "Wilting" - Process end time
    int32_t exit_code;
    const char* wilt_reason;      // Termination reason
} flower_wilt_t;

// Pollination - Inter-process communication
typedef struct {
    uint64_t source_pid;
    uint64_t dest_pid;
    void* pollen_data;            // "Pollination" - Data transfer
    size_t pollen_size;
    uint64_t pollination_time_ns;
} flower_pollination_t;

// Seeding - Secure hash/crypto initialization
typedef struct {
    uint32_t seed_value;          // "Seeding" - Hash initialization
    const char* seed_algorithm;   // SHA-256, etc.
    bool seeded;
    uint64_t entropy_bits;
} flower_seeding_t;

// Garden - Memory management
typedef struct {
    void* garden_base;            // "Garden" - Memory pool
    size_t garden_size;
    size_t garden_used;
    size_t garden_free;
    uint32_t garden_plots;        // Memory blocks
} flower_garden_t;

// Stem - Network stack (extends Rooter.hpp)
typedef struct {
    bool stem_active;             // "Stem" - Network connection
    uint32_t stem_bandwidth;      // Bandwidth (Gbps)
    const char* stem_protocol;    // TCP/IP, etc.
    uint64_t packets_sent;
    uint64_t packets_received;
} flower_stem_t;

// Petals - GPU compute units
typedef struct {
    uint32_t petal_id;            // "Petals" - Individual GPU cores
    bool petal_active;
    float petal_temperature;
    uint64_t petal_operations;
} flower_petal_t;

// ═══════════════════════════════════════════════════════════════════════════
//  Thorns - Security Subsystem (Defense Mechanisms)
//
//  Every graft boundary is an attack surface.  Thorns provides:
//    - Per-process capability masks (bloom_caps)
//    - Memory safety: stack canaries, zero-on-free, guard pages
//    - Host kernel integrity verification for parasitic builds
//    - IPC (pollination) access control
//    - Entropy quality enforcement for seeding
//
//  Design rule: defense is structural, not optional.  No flag disables
//  the core invariants; only debug builds may relax secondary checks.
// ═══════════════════════════════════════════════════════════════════════════

// Capability bits — per-bloom (per-process) permission mask
#define FLOWER_CAP_GARDEN_ALLOC   (1U << 0)   // May allocate memory
#define FLOWER_CAP_GARDEN_EXEC    (1U << 1)   // May mark pages executable
#define FLOWER_CAP_POLLINATE      (1U << 2)   // May send IPC
#define FLOWER_CAP_PETAL_ACCESS   (1U << 3)   // May use GPU
#define FLOWER_CAP_STEM_BIND      (1U << 4)   // May bind network ports
#define FLOWER_CAP_STEM_RAW       (1U << 5)   // May open raw sockets
#define FLOWER_CAP_ROOT_MODIFY    (1U << 6)   // May alter rooting config
#define FLOWER_CAP_SEED_ENTROPY   (1U << 7)   // May reseed entropy pool
#define FLOWER_CAP_KERNEL_QUERY   (1U << 8)   // May read kernel state
#define FLOWER_CAP_ALL            0x1FFU       // Full capability set

// Default: allocate + IPC + GPU + kernel query
#define FLOWER_CAP_DEFAULT \
    (FLOWER_CAP_GARDEN_ALLOC | FLOWER_CAP_POLLINATE | \
     FLOWER_CAP_PETAL_ACCESS | FLOWER_CAP_KERNEL_QUERY)

// Memory safety policy
typedef struct {
    bool zero_on_free;            // Scrub garden plots on deallocation
    bool guard_pages;             // Place inaccessible pages around allocs
    bool stack_canary;            // Per-bloom stack canary verification
    bool aslr;                    // Randomize garden base per bloom
    uint32_t canary_seed;         // Canary derivation seed (from seeding)
} flower_thorn_memory_t;

// Host integrity verification (parasitic builds only)
typedef struct {
    bool verified;                // Host kernel passed integrity check
    uint8_t host_hash[32];       // SHA-256 of host kernel image
    const char* host_version;    // e.g. "5.15.0-91-generic"
    uint64_t verify_time_ns;     // Timestamp of last verification
    bool enforce;                // Refuse boot on verification failure
} flower_thorn_graft_t;

// IPC (pollination) access control entry
typedef struct {
    uint64_t source_pid;          // Bloom allowed to send
    uint64_t dest_pid;            // Bloom allowed to receive
    uint32_t allowed_caps;        // Required caps for this channel
    size_t max_pollen_size;       // Maximum message size (bytes)
} flower_thorn_ipc_rule_t;

// Audit log entry
typedef struct {
    uint64_t timestamp_ns;
    uint64_t bloom_pid;           // Offending process
    uint32_t violation;           // Which cap was missing
    const char* detail;           // Human-readable description
} flower_thorn_audit_entry_t;

// Top-level security state
typedef struct {
    // Memory safety
    flower_thorn_memory_t memory;

    // Graft integrity (parasitic builds)
    flower_thorn_graft_t graft;

    // Per-bloom capability table (indexed by process slot)
    uint32_t* bloom_caps;         // Array[max_blooms] of cap masks
    uint32_t max_blooms;

    // IPC access control
    flower_thorn_ipc_rule_t* ipc_rules;
    uint32_t ipc_rule_count;
    uint32_t ipc_rule_capacity;

    // Audit ring buffer
    flower_thorn_audit_entry_t* audit_log;
    uint32_t audit_capacity;
    uint32_t audit_head;          // Next write index (wraps)

    // Entropy quality
    uint64_t min_entropy_bits;    // Minimum acceptable entropy
    bool entropy_adequate;        // Set by flower_thorn_check_entropy()

    // Global policy
    bool enforce;                 // true = deny violations; false = log only
    uint64_t violations_total;
} flower_thorns_t;

// Default security policy
#define FLOWER_THORNS_DEFAULT {                            \
    .memory = {                                            \
        .zero_on_free  = true,                             \
        .guard_pages   = true,                             \
        .stack_canary  = true,                             \
        .aslr          = true,                             \
        .canary_seed   = 0                                 \
    },                                                     \
    .graft = {                                             \
        .verified = false,                                 \
        .host_hash = {0},                                  \
        .host_version = NULL,                              \
        .verify_time_ns = 0,                               \
        .enforce = (FLOWEROS_BUILD_TYPE ==                  \
                    FLOWEROS_BUILD_PARASITIC)               \
    },                                                     \
    .bloom_caps = NULL,                                    \
    .max_blooms = 0,                                       \
    .ipc_rules = NULL,                                     \
    .ipc_rule_count = 0,                                   \
    .ipc_rule_capacity = 0,                                \
    .audit_log = NULL,                                     \
    .audit_capacity = 0,                                   \
    .audit_head = 0,                                       \
    .min_entropy_bits = 256,                               \
    .entropy_adequate = false,                             \
    .enforce = true,                                       \
    .violations_total = 0                                  \
}

// ═══════════════════════════════════════════════════════════════════════════
//  Kernel State Structure
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    // Kernel info
    const char* kernel_version;
    uint64_t kernel_uptime_ns;
    bool kernel_active;
    
    // Subsystems
    flower_germination_t germination;
    flower_rooting_t rooting;
    flower_photosynthesis_t photosynthesis;
    flower_garden_t garden;
    flower_stem_t stem;
    flower_thorns_t thorns;
    
    // Configuration
    flower_palette_config_t palette;
    
    // Statistics
    uint64_t blooms_total;        // Total processes spawned
    uint64_t wilts_total;         // Total processes terminated
    uint64_t pollinations_total;  // Total IPC events
    uint64_t petals_total;        // Total GPU cores
    
    // GPU array
    flower_petal_t* petals;       // Array of GPU cores
    uint32_t petal_count;
    
} flower_kernel_state_t;

// ═══════════════════════════════════════════════════════════════════════════
//  Kernel API (Plant-Themed Function Names)
// ═══════════════════════════════════════════════════════════════════════════

// Initialization
int flower_kernel_germinate(flower_kernel_state_t* kernel);
int flower_kernel_root(flower_kernel_state_t* kernel, const char* root_path);
int flower_kernel_seed_entropy(flower_kernel_state_t* kernel, uint32_t seed);

// Process management
uint64_t flower_process_bloom(flower_kernel_state_t* kernel, const char* name);
int flower_process_wilt(flower_kernel_state_t* kernel, uint64_t pid);

// Memory management
void* flower_garden_allocate(flower_kernel_state_t* kernel, size_t size);
void flower_garden_free(flower_kernel_state_t* kernel, void* ptr);

// IPC
int flower_pollinate(flower_kernel_state_t* kernel, uint64_t src, uint64_t dest, void* data, size_t size);

// GPU management
int flower_petal_activate(flower_kernel_state_t* kernel, uint32_t petal_id);
int flower_petal_deactivate(flower_kernel_state_t* kernel, uint32_t petal_id);

// Resource monitoring
float flower_photosynthesis_efficiency(flower_kernel_state_t* kernel);
uint64_t flower_garden_usage_bytes(flower_kernel_state_t* kernel);

// Display
void flower_kernel_print_status(flower_kernel_state_t* kernel);
void flower_kernel_print_garden(flower_kernel_state_t* kernel);
void flower_kernel_print_petals(flower_kernel_state_t* kernel);

// Configuration
int flower_palette_set(flower_kernel_state_t* kernel, uint8_t palette_id);
int flower_colors_toggle(flower_kernel_state_t* kernel, bool enable);
int flower_unicode_toggle(flower_kernel_state_t* kernel, bool enable);

// ═══════════════════════════════════════════════════════════════════════════
//  Thorns API (Security)
// ═══════════════════════════════════════════════════════════════════════════

// Initialise the thorns subsystem (must be called before first bloom)
int flower_thorns_init(flower_kernel_state_t* kernel, uint32_t max_blooms,
                       uint32_t audit_capacity);

// Verify host kernel integrity (parasitic builds)
int flower_thorn_verify_graft(flower_kernel_state_t* kernel,
                              const uint8_t expected_hash[32]);

// Capability management
int flower_thorn_set_caps(flower_kernel_state_t* kernel, uint64_t pid,
                          uint32_t caps);
int flower_thorn_check_cap(flower_kernel_state_t* kernel, uint64_t pid,
                           uint32_t required_cap);

// IPC access control
int flower_thorn_add_ipc_rule(flower_kernel_state_t* kernel,
                              uint64_t src, uint64_t dest,
                              uint32_t required_caps, size_t max_size);
int flower_thorn_check_ipc(flower_kernel_state_t* kernel,
                           uint64_t src, uint64_t dest, size_t size);

// Secure allocation (zero-initialised, optional guard pages)
void* flower_garden_allocate_secure(flower_kernel_state_t* kernel,
                                    size_t size);

// Entropy quality
int flower_thorn_check_entropy(flower_kernel_state_t* kernel);

// Audit
void flower_thorn_log(flower_kernel_state_t* kernel, uint64_t pid,
                      uint32_t violation, const char* detail);
void flower_thorn_print_audit(flower_kernel_state_t* kernel,
                              uint32_t max_entries);

// ═══════════════════════════════════════════════════════════════════════════
//  Kernel Macros
// ═══════════════════════════════════════════════════════════════════════════

// Get current symbol based on palette
#define FLOWER_GET_SYMBOL(kernel, name) \
    ((kernel)->palette.unicode_enabled ? \
        ((kernel)->palette.palette_id == 1 ? FLOWER_SYMBOL_##name : FLOWER_SYMBOL_FLOWER1) : \
        "*")

// Print with color
#define FLOWER_PRINT_COLOR(kernel, color, fmt, ...) \
    do { \
        if ((kernel)->palette.colors_enabled) { \
            printf("%s", (kernel)->palette.color_##color); \
            printf(fmt, ##__VA_ARGS__); \
            printf("%s", (kernel)->palette.color_reset); \
        } else { \
            printf(fmt, ##__VA_ARGS__); \
        } \
    } while(0)

// Print with symbol
#define FLOWER_PRINT_SYMBOL(kernel, symbol, fmt, ...) \
    do { \
        if ((kernel)->palette.unicode_enabled) { \
            printf("%s ", FLOWER_SYMBOL_##symbol); \
        } \
        printf(fmt, ##__VA_ARGS__); \
    } while(0)

#endif // FLOWEROS_KERNEL_H
