# 🔴 FlowerOS Network Routing System

## ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️

**This documentation describes EXPERIMENTAL features in FlowerOS v1.3.X development branch.**

**DO NOT USE IN PRODUCTION ENVIRONMENTS!**

---

## Overview

The FlowerOS Network Routing System ("Root Network") allows FlowerOS installations to discover and communicate with each other across a network, forming a distributed computational garden.

**Botanical Metaphor:**  
Like roots spreading through soil to connect plants, the Root Network spreads through your infrastructure to connect FlowerOS instances.

---

## 🔴 Experimental Status

| Feature | Status | Production Ready |
|---------|--------|------------------|
| Network Discovery | 🟡 Basic | ❌ NO |
| Root Connections | 🟡 Basic | ❌ NO |
| Message Routing | 🔴 Stub | ❌ NO |
| Theme Sync | 🔴 Stub | ❌ NO |
| Distributed GPU | 🔴 Not Implemented | ❌ NO |
| Cluster Management | 🟡 Basic | ❌ NO |
| Security | 🔴 None | ❌ NO |
| Encryption | 🔴 None | ❌ NO |

**Legend:**
- 🟢 Complete
- 🟡 Basic/Incomplete
- 🔴 Stub/Not Implemented

---

## Architecture

### Components

```
FlowerOS Root Network
├── Rooter.hpp          - C++ network routing header
├── Rooting.cpp         - Implementation (experimental)
├── flower_network.h    - C API wrapper
└── Makefile            - Build system (with warnings)
```

### Network Topology

```
         TREE (Master Node)
           |
      ╔════╩════╗
      ↓         ↓
   FLOWER    FLOWER  (GPU-capable nodes)
      ↓         ↓
   PLANT     PLANT   (Worker nodes)
      ↓         ↓
   SPROUT    SPROUT  (Connecting nodes)
      ↓         ↓
    SEED      SEED   (New nodes)
```

**Node Types (Botanical):**
- **SEED** - New node, not yet established
- **SPROUT** - Node establishing connections
- **PLANT** - Established worker node
- **FLOWER** - GPU-capable processing node
- **TREE** - Master/coordinator node
- **WILTED** - Disconnected/failed node

---

## Building

### ⚠️ Compilation

```bash
cd network/

# Build with RED WARNING
make all

# Install (experimental)
make install

# Clean
make clean
```

**Output:**
```
build/libflowernetwork.so     # Shared library
build/libflowernetwork.a      # Static library
```

---

## API Reference

### C++ API (Rooter.hpp)

#### Initialization

```cpp
#include "Rooter.hpp"

using namespace FlowerOS::Network;

// Create router
Rooter router;

// ⚠️ Initialize (experimental)
bool success = router.initialize(7777);  // Port 7777

// Shutdown
router.shutdown();
```

#### Network Discovery

```cpp
// Discover network (roots spreading)
router.discover_network();  // Auto-detect subnet

// Get discovered nodes
std::vector<NetworkNode> nodes = router.get_discovered_nodes();

for (const auto& node : nodes) {
    std::cout << "Found: " << node.hostname 
              << " (" << node.ip_address << ")" << std::endl;
}
```

#### Root Connections

```cpp
// Connect to another node
router.connect_to_root("192.168.1.100", 7777);

// Check if rooted (connected)
if (router.is_rooted()) {
    std::cout << "Connected to root network" << std::endl;
}

// Get connection count
uint32_t roots = router.get_connected_roots();
```

#### Message Routing

```cpp
// Create message
NetworkMessage msg;
msg.type = MessageType::THEME_SYNC;
msg.source_node = "host1";
msg.dest_node = "host2";
msg.timestamp = std::time(nullptr);

// Send message
router.send_message(msg);

// Broadcast to all
router.broadcast_message(msg);
```

#### ⚠️ Theme Synchronization (Experimental)

```cpp
// Sync theme across network
router.sync_theme_to_network("garden");

// ⚠️ WARNING: This is a stub implementation!
```

#### ⚠️ Distributed GPU (Experimental)

```cpp
// Submit GPU batch to network
std::vector<std::string> files = {"data1.bin", "data2.bin"};
router.submit_gpu_batch(files);

// ⚠️ WARNING: Not implemented yet!
```

#### Cluster Management

```cpp
// Form cluster (become TREE/master)
router.form_cluster("my_garden_cluster");

// Join existing cluster
router.join_cluster("my_garden_cluster", "192.168.1.100");

// Leave cluster
router.leave_cluster();

// Get cluster nodes
std::vector<NetworkNode> cluster = router.get_cluster_nodes();
```

#### Node Information

```cpp
// Get local node type
NodeType type = router.get_node_type();

// Set node type
router.set_node_type(NodeType::FLOWER);  // Mark as GPU-capable

// Get local info
NetworkNode local = router.get_local_node_info();
```

#### Statistics

```cpp
// Get network statistics
uint64_t sent = router.get_bytes_sent();
uint64_t received = router.get_bytes_received();
uint32_t roots = router.get_connected_roots();
```

#### Debug

```cpp
// Enable debug mode
router.enable_debug_mode(true);

// Dump routing table
router.dump_routing_table();

// Get experimental status
std::string status = router.get_experimental_status();
// Returns: "NOT_PRODUCTION_READY"
```

---

### C API (flower_network.h)

#### Initialization

```c
#include "flower_network.h"

// Check if experimental
if (flower_network_is_experimental()) {
    printf("⚠️  WARNING: %s\n", flower_network_get_warning());
}

// Initialize
flower_network_t net = flower_network_init(7777);

// Cleanup
flower_network_shutdown(net);
```

#### Network Discovery

```c
// Discover network
flower_network_discover(net, NULL);  // Auto-detect

// Get nodes
flower_network_node_t nodes[10];
int count = flower_network_get_nodes(net, nodes, 10);

for (int i = 0; i < count; i++) {
    printf("Node: %s (%s:%d)\n", 
           nodes[i].hostname, 
           nodes[i].ip_address, 
           nodes[i].port);
}
```

#### Root Connections

```c
// Connect
flower_network_connect(net, "192.168.1.100", 7777);

// Check if rooted
if (flower_network_is_rooted(net)) {
    printf("Connected to network\n");
}

// Get root count
uint32_t roots = flower_network_get_root_count(net);
```

#### Theme Sync

```c
// ⚠️ EXPERIMENTAL
flower_network_sync_theme(net, "garden");
```

#### Cluster Management

```c
// Form cluster
flower_network_form_cluster(net, "my_cluster");

// Join cluster
flower_network_join_cluster(net, "my_cluster", "192.168.1.100");

// Leave
flower_network_leave_cluster(net);
```

#### Node Information

```c
// Get node type
flower_node_type_t type = flower_network_get_node_type(net);

// Set type
flower_network_set_node_type(net, FLOWER_NODE_FLOWER);

// Get local info
flower_network_node_t local;
flower_network_get_local_info(net, &local);
```

---

## Network Protocol

### Message Format

```
┌──────────────────────────────────────┐
│ Message Type (4 bytes)               │
├──────────────────────────────────────┤
│ Sequence Number (4 bytes)            │
├──────────────────────────────────────┤
│ Timestamp (8 bytes)                  │
├──────────────────────────────────────┤
│ Source Node ID (variable)            │
├──────────────────────────────────────┤
│ Destination Node ID (variable)       │
├──────────────────────────────────────┤
│ Payload Size (4 bytes)               │
├──────────────────────────────────────┤
│ Payload (variable)                   │
├──────────────────────────────────────┤
│ Checksum (4 bytes)                   │
└──────────────────────────────────────┘
```

### Message Types

| Type | Code | Purpose | Status |
|------|------|---------|--------|
| ROOT_HELLO | 0x01 | Initial connection | 🟡 Basic |
| ROOT_GOODBYE | 0x02 | Disconnect | 🟡 Basic |
| ROOT_HEARTBEAT | 0x03 | Keep-alive | 🟡 Basic |
| ROOT_DISCOVERY | 0x04 | Network discovery | 🟡 Basic |
| THEME_SYNC | 0x10 | Theme sync | 🔴 Stub |
| CONFIG_SYNC | 0x11 | Config sync | 🔴 Not Impl |
| ASCII_TRANSFER | 0x12 | ASCII art | 🔴 Not Impl |
| GPU_BATCH_REQUEST | 0x20 | GPU batch | 🔴 Not Impl |
| GPU_BATCH_RESULT | 0x21 | GPU results | 🔴 Not Impl |
| KERNEL_REQUEST | 0x22 | Kernel op | 🔴 Not Impl |
| KERNEL_RESULT | 0x23 | Kernel result | 🔴 Not Impl |
| CLUSTER_JOIN | 0x30 | Join cluster | 🟡 Basic |
| CLUSTER_LEAVE | 0x31 | Leave cluster | 🟡 Basic |
| CLUSTER_STATUS | 0x32 | Status update | 🔴 Not Impl |
| ERROR | 0xFF | Error response | 🟡 Basic |

### Port Allocation

| Port | Purpose | Botanical Name |
|------|---------|----------------|
| 7777 | Root communication | Root Port |
| 8888 | Flower messages | Flower Port |
| 9999 | Seed distribution | Seed Port |

---

## Use Cases

### 1. Distributed Theme Synchronization

⚠️ **EXPERIMENTAL**

```cpp
// On master node
router.sync_theme_to_network("garden");

// On worker nodes (automatic)
// Theme propagates through root network
```

**Status:** 🔴 Stub implementation

### 2. Network GPU Batch Processing

⚠️ **EXPERIMENTAL - NOT IMPLEMENTED**

```cpp
// Submit batch to network
std::vector<std::string> large_dataset = {...};
router.submit_gpu_batch(large_dataset);

// Network routes to available FLOWER nodes
// Results aggregated and returned
```

**Status:** 🔴 Not implemented

### 3. Cluster Computing

⚠️ **EXPERIMENTAL**

```cpp
// Master node
router.form_cluster("research_cluster");

// Worker nodes join
router.join_cluster("research_cluster", "master_ip");

// Distribute work across cluster
```

**Status:** 🟡 Basic implementation

---

## Security Warnings

### 🔴 CRITICAL SECURITY ISSUES

**The network routing system has NO security:**

1. **No Encryption** - All data transmitted in plain text
2. **No Authentication** - Any node can join network
3. **No Authorization** - No access control
4. **No Validation** - Messages not validated
5. **No Rate Limiting** - Vulnerable to DoS
6. **No Input Sanitization** - Vulnerable to injection

**DO NOT USE ON UNTRUSTED NETWORKS!**

**DO NOT TRANSMIT SENSITIVE DATA!**

**DO NOT USE IN PRODUCTION!**

---

## Performance Considerations

### Network Overhead

- Heartbeat: Every 1 second
- Discovery: Every 30 seconds
- Message routing: Synchronous

**Performance Impact:**
- High network traffic
- CPU usage for threading
- Memory for routing table

### Scalability

⚠️ **NOT TESTED AT SCALE**

- Maximum nodes: Unknown
- Maximum throughput: Unknown
- Latency: Unknown

---

## Troubleshooting

### Connection Failures

```bash
# Check port availability
netstat -tlnp | grep 7777

# Check firewall
sudo ufw status
sudo ufw allow 7777/tcp

# Test connectivity
telnet 192.168.1.100 7777
```

### Discovery Issues

```bash
# Check subnet
ip addr show

# Verify broadcast
ping -b 192.168.1.255
```

### Debug Mode

```cpp
router.enable_debug_mode(true);
router.dump_routing_table();
```

---

## Limitations

### Current Limitations

1. **No IPv6 Support** - IPv4 only
2. **No Encryption** - Plain text only
3. **No Compression** - No data compression
4. **Synchronous I/O** - Blocking operations
5. **Limited Error Handling** - Minimal validation
6. **No Persistence** - Routing table not saved
7. **No Load Balancing** - No intelligent routing
8. **No Fault Tolerance** - Single point of failure

### Known Issues

- Memory leaks in message handling
- Race conditions in threading
- Socket cleanup incomplete
- Heartbeat may miss nodes
- Discovery unreliable on some networks

---

## Future Work

### Planned Features (Not Implemented)

- [ ] SSL/TLS encryption
- [ ] Authentication system
- [ ] Message compression
- [ ] Async I/O
- [ ] IPv6 support
- [ ] Load balancing
- [ ] Fault tolerance
- [ ] Persistent routing
- [ ] Web dashboard
- [ ] REST API

---

## Examples

### Basic Network Setup

```cpp
#include "Rooter.hpp"

using namespace FlowerOS::Network;

int main() {
    // Create router
    Rooter router;
    
    // Initialize
    if (!router.initialize(7777)) {
        std::cerr << "Failed to initialize" << std::endl;
        return 1;
    }
    
    // Discover network
    router.discover_network();
    
    // Wait for connections
    std::this_thread::sleep_for(std::chrono::seconds(10));
    
    // Show routing table
    router.dump_routing_table();
    
    // Cleanup
    router.shutdown();
    
    return 0;
}
```

### Cluster Formation

```cpp
// Master node
Rooter master;
master.initialize(7777);
master.form_cluster("my_cluster");

// Worker nodes
Rooter worker1;
worker1.initialize(7778);
worker1.join_cluster("my_cluster", "192.168.1.100");

Rooter worker2;
worker2.initialize(7779);
worker2.join_cluster("my_cluster", "192.168.1.100");
```

---

## Testing

### Unit Tests

⚠️ **NOT IMPLEMENTED**

### Integration Tests

⚠️ **NOT IMPLEMENTED**

### Network Tests

⚠️ **MANUAL TESTING ONLY**

---

## Compliance

### Production Use

**Status: NOT APPROVED FOR PRODUCTION**

- No security audit
- No penetration testing
- No load testing
- No failover testing
- No compliance certifications

### Industry Standards

**Does NOT comply with:**
- ISO 27001 (Information Security)
- NIST Cybersecurity Framework
- PCI DSS (Payment Card Industry)
- HIPAA (Health Insurance Portability)
- GDPR (Data Protection)

---

## Support

### Where to Get Help

- FlowerOS v1.3.X is **experimental**
- No official support
- Community forums only
- GitHub issues

### Reporting Issues

File issues with:
- FlowerOS version
- Network configuration
- Error messages
- Steps to reproduce

---

## Conclusion

The FlowerOS Network Routing System is an **experimental feature** that demonstrates distributed FlowerOS capabilities. 

**It is NOT ready for production use.**

For stable, reliable FlowerOS features, use **v1.2.X stable branch**.

---

## See Also

- `PERMANENT_INSTALL.md` - System installation
- `KERNEL_COMPLETE.md` - Kernel documentation
- `GPU_FEATURES.md` - GPU batch processing
- `RED_WARNING_SUMMARY.md` - All red warnings

---

**🔴 FlowerOS v1.3.0 - Network Routing System**  
**⚠️ EXPERIMENTAL - NOT PRODUCTION READY ⚠️**

*Where roots spread through networks, connecting gardens* 🌱→🌿→🌳
