# FlowerOS Kernel - Internal Operating Code

## 🌸 Plant-Themed Operating System Core

This is the **internal operating code** for FlowerOS v1.3.0, demonstrating the kernel architecture with plant-themed terminology and botanical naming conventions.

---

## ⚠️ Important Notes

### Demo Kernel Only

This is a **demonstration kernel** and **NOT for production use**:
- Security considerations not fully implemented
- Educational/conceptual demonstration
- Shows FlowerOS internal architecture

### Production Deployment

For production use, FlowerOS operates in **parasitic mode**:
- Integrates with Debian/AlmaLinux as host OS
- Leverages host kernel for security and stability
- FlowerOS provides enhanced terminal layer + GPU compute

---

## 🌱 Plant Terminology

FlowerOS uses botanical terms throughout the codebase:

### Core Operations

| Term | Meaning | Traditional Equivalent |
|------|---------|----------------------|
| **Germination** | Boot process | System initialization |
| **Rooting** | System integration | Installation/mounting |
| **Seeding** | Hash initialization | Random seed, salt generation |
| **Blooming** | Process spawning | fork(), exec() |
| **Wilting** | Process termination | kill(), exit() |
| **Pollination** | Inter-process communication | IPC, pipes, sockets |
| **Photosynthesis** | Resource management | CPU/RAM/GPU allocation |
| **Garden** | Memory management | Heap, memory pool |
| **Petals** | GPU compute cores | CUDA cores, stream processors |
| **Stem** | Network stack | Network interface |

### User Hierarchy

| Role | Level | Permissions |
|------|-------|------------|
| **Seed** | 0 | New user, minimal access |
| **Sprout** | 1 | Basic user (read) |
| **Stem** | 2 | Standard user (read/write) |
| **Bloom** | 3 | Power user (read/write/execute) |
| **Gardener** | 4 | Administrator |
| **Root** | 5 | System administrator |

### Permission Flags

- `FLOWER_PERM_SPROUT` - Read access
- `FLOWER_PERM_GROW` - Write access
- `FLOWER_PERM_BLOOM` - Execute access
- `FLOWER_PERM_POLLINATE` - Network access
- `FLOWER_PERM_GARDEN` - Memory management
- `FLOWER_PERM_PETAL` - GPU access
- `FLOWER_PERM_ROOT` - Root access

---

## 🎨 Unicode Palettes

FlowerOS uses two Unicode symbol palettes for visual display:

### Palette #1 - Botanical Symbols

```
☘  Shamrock       (Alt + 9752)
🍁 Maple Leaf     (Alt + 127809)
🌱 Seedling       (Alt + 127793)
🍆 Eggplant       (Alt + 127810)
🌾 Wheat          (Alt + 127796)
🌿 Herb           (Alt + 127799)
🌵 Cactus         (Alt + 127797)
🌿 Branch         (Alt + 127807)
🍀 Four-leaf      (Alt + 127808)
```

### Palette #2 - Flower Symbols

```
✿  Flower 1       (Alt + 10047)
⚘  Flower 2       (Alt + 9880)
⚜  Fleur-de-lis   (Alt + 9884)
❦  Heart Flower   (Alt + 10046)
❁  Flower 3       (Alt + 10049)
✾  Flower 4       (Alt + 10046)
❀  Flower 5       (Alt + 10048)
❃  Flower 6       (Alt + 10051)
🌼 Blossom        (Alt + 127804)
✽  Flower 7       (Alt + 10045)
✻  Flower 8       (Alt + 10043)
```

### Configuration

Palettes are toggleable at root level:
```c
flower_palette_set(kernel, 1);        // Use Palette #1
flower_palette_set(kernel, 2);        // Use Palette #2
flower_colors_toggle(kernel, true);   // Enable colors
flower_unicode_toggle(kernel, true);  // Enable Unicode
```

---

## 📁 File Structure

```
kernel/
├── flower_kernel.h         # Kernel header (data structures, API)
├── flower_kernel.c         # Kernel implementation
├── flower_userdb.h         # User database (XML backend)
├── kernel_demo.c           # Demo application
├── Makefile                # Build system
└── README_KERNEL.md        # This file
```

---

## 🔧 Building

### Prerequisites

```bash
# Debian/Ubuntu
sudo apt-get install build-essential

# AlmaLinux/RHEL
sudo dnf groupinstall "Development Tools"
```

### Build Commands

```bash
# Build kernel demo (default: parasitic mode)
make

# Build with specific type
make BUILD_TYPE=PARASITIC   # Production (recommended)
make BUILD_TYPE=BARE_METAL  # Demo only
make BUILD_TYPE=CONTAINER   # Container-based

# Run demo
make run

# Clean build
make clean

# Show help
make help
```

---

## 🚀 Running the Demo

```bash
cd kernel
make clean && make && make run
```

### Demo Output

The demo demonstrates:
1. **Germination** - Kernel boot
2. **Rooting** - System integration
3. **Seeding** - Entropy initialization
4. **Photosynthesis** - Resource detection (CPU, RAM, GPU)
5. **Garden** - Memory management
6. **Petals** - GPU core initialization
7. **Blooming** - Process spawning
8. **Pollination** - Inter-process communication
9. **Wilting** - Process termination
10. **Configuration** - Palette and color toggling

---

## 🔐 Security Features

### Seeding (Hash Initialization)

FlowerOS uses "seeding" terminology for cryptographic operations:

```c
// Master seed for database
flower_userdb_seed(db, master_seed);

// User password seeding
flower_user_hash_password(password, salt, seed, hash_out);

// Salt generation (random seed)
flower_user_generate_salt(salt_out, seed);
```

### User Database XML Backend

Secure XML storage with:
- SHA-256 password hashing
- Random salt generation ("seeding")
- Per-user hash seeds
- Role-based access control
- Resource quotas (garden/petals)

Example XML structure:
```xml
<flower_garden database_version="1.3.0">
  <master_seed value="0x1A2B3C4D" />
  <users>
    <seed user_id="1" role="ROOT">
      <security>
        <password_hash algorithm="SHA-256">...</password_hash>
        <salt>random_salt</salt>
        <hash_seed value="0x9F8E7D6C" />
      </security>
      <resources>
        <garden quota="1099511627776" used="214748364800" />
        <petals quota="27648" used="6912" />
      </resources>
    </seed>
  </users>
</flower_garden>
```

---

## 🎯 Kernel Architecture

### Subsystems

```
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  (flower_gpu_batch, flower_banner, etc.)                │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                 FlowerOS System Calls                    │
│  (bloom, wilt, pollinate, garden_alloc, etc.)           │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                  FlowerOS Kernel Core                    │
│  • Germination (boot)                                   │
│  • Rooting (integration)                                │
│  • Photosynthesis (resources)                           │
│  • Garden (memory)                                      │
│  • Petals (GPU)                                         │
│  • Stem (network)                                       │
└─────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────┐
│                    Hardware Layer                        │
│  CPU | RAM | GPU | Storage | Network                    │
└─────────────────────────────────────────────────────────┘
```

### Key Structures

**Kernel State:**
```c
flower_kernel_state_t
├── germination      (boot info)
├── rooting          (system integration)
├── photosynthesis   (CPU/RAM/GPU)
├── garden           (memory management)
├── stem             (network stack)
├── palette          (colors & Unicode)
└── petals[]         (GPU cores array)
```

**User Database:**
```c
flower_userdb_t
├── users[]          (user array)
├── xml_path         (database file)
├── master_seed      (database seed)
├── session_seed     (current session)
└── statistics       (login counts, etc.)
```

---

## 📊 Example Usage

### Kernel Initialization

```c
#include "flower_kernel.h"

// Initialize kernel
flower_kernel_state_t kernel;
flower_kernel_germinate(&kernel);
flower_kernel_root(&kernel, "/opt/floweros");
flower_kernel_seed_entropy(&kernel, 0x12345678);

// Process lifecycle
uint64_t pid = flower_process_bloom(&kernel, "my_process");
// ... do work ...
flower_process_wilt(&kernel, pid);

// Memory management
void* mem = flower_garden_allocate(&kernel, 1024 * 1024);
// ... use memory ...
flower_garden_free(&kernel, mem);

// GPU operations
flower_petal_activate(&kernel, 0);
// ... compute on GPU ...
flower_petal_deactivate(&kernel, 0);
```

### User Management

```c
#include "flower_userdb.h"

// Initialize database
flower_userdb_t db;
flower_userdb_init(&db, "/etc/floweros/users.xml");
flower_userdb_seed(&db, 0xABCDEF01);

// Create user ("germinate seed")
flower_user_germinate(&db, "alice", "alice@example.com", "password123");

// Login ("bloom")
flower_user_bloom(&db, "alice", "password123");

// Grant permissions
flower_user_t* user = flower_user_find_by_name(&db, "alice");
flower_user_grant_permission(&db, user->user_id, FLOWER_PERM_PETAL);

// Allocate resources
flower_user_allocate_petals(&db, user->user_id, 1024);  // 1024 GPU cores
```

---

## 🌟 Design Philosophy

### Why Plant Terminology?

1. **Intuitive** - Natural metaphors (seeding, blooming, wilting)
2. **Memorable** - Easier to remember than technical jargon
3. **Poetic** - "Every GPU core is a flower in the garden"
4. **Consistent** - All naming follows botanical theme
5. **Friendly** - Approachable for non-experts

### Core Principles

1. **Simple functions** - Complex operations, simple interface
2. **Plant metaphors** - Consistent botanical naming
3. **Visual identity** - Unicode symbols and colors
4. **Performance** - GPU-first architecture
5. **Security** - Seeding, hashing, role-based access

---

## 🔮 Future Expansion

### Planned Features

- **Roots** - Filesystem layer (extends Rooter.hpp)
- **Canopy** - Process tree visualization
- **Nectar** - Data caching system
- **Pollen** - Distributed computing (extends Pollination)
- **Soil** - Persistent storage layer
- **Rain** - Resource cleanup/garbage collection
- **Seasons** - System state management
- **Harvest** - Batch job completion

### Additional Subsystems

- **Composting** - Memory recycling
- **Grafting** - Process migration
- **Pruning** - Resource optimization
- **Irrigation** - Data flow management
- **Fertilization** - Performance tuning

---

## 📖 API Reference

See `flower_kernel.h` for complete API documentation.

### Core Functions

- `flower_kernel_germinate()` - Initialize kernel
- `flower_kernel_root()` - Integrate system
- `flower_kernel_seed_entropy()` - Initialize RNG
- `flower_process_bloom()` - Spawn process
- `flower_process_wilt()` - Terminate process
- `flower_pollinate()` - IPC
- `flower_garden_allocate()` - Allocate memory
- `flower_garden_free()` - Free memory
- `flower_petal_activate()` - Activate GPU core
- `flower_petal_deactivate()` - Deactivate GPU core

### Configuration Functions

- `flower_palette_set()` - Switch Unicode palette
- `flower_colors_toggle()` - Enable/disable colors
- `flower_unicode_toggle()` - Enable/disable Unicode

---

## 🌸 Philosophy

> **Every GPU core is a flower in the garden.**  
> **Every computation is a bloom.**  
> **Every process is a seed that germinates.**  
> **Every user is a gardener tending the system.**

FlowerOS transforms computing into cultivation.

---

**FlowerOS Kernel v1.3.0 - "Root Integration"**  
*Where computation becomes cultivation* 🌸⚡

---

## 📚 See Also

- `../BARE_METAL_HPC.md` - Bare metal OS architecture
- `../GPU_FEATURES.md` - GPU batch processing
- `../VERSION_POLICY.md` - Version comparison
- `../PERMANENT_INSTALL.md` - System integration
- `flower_kernel.h` - Kernel API reference
- `flower_userdb.h` - User database API
