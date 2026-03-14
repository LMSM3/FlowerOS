// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Network Routing System - C API
//  flower_network.h - C-compatible network interface
//
//  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWEROS_FLOWER_NETWORK_H
#define FLOWEROS_FLOWER_NETWORK_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// ═══════════════════════════════════════════════════════════════════════════
//  Version Information
// ═══════════════════════════════════════════════════════════════════════════

#define FLOWEROS_NETWORK_API_VERSION "1.3.0-EXPERIMENTAL"
#define FLOWEROS_NETWORK_EXPERIMENTAL 1

// ⚠️ RED WARNING: Status constants
#define FLOWEROS_NETWORK_STATUS_EXPERIMENTAL 0xFF
#define FLOWEROS_NETWORK_STATUS_PRODUCTION   0x00

// ═══════════════════════════════════════════════════════════════════════════
//  Node Types (Botanical)
// ═══════════════════════════════════════════════════════════════════════════

typedef enum {
    FLOWER_NODE_SEED = 0,       // New node
    FLOWER_NODE_SPROUT,         // Establishing
    FLOWER_NODE_PLANT,          // Established
    FLOWER_NODE_FLOWER,         // GPU-capable
    FLOWER_NODE_TREE,           // Master/coordinator
    FLOWER_NODE_WILTED,         // Disconnected
    FLOWER_NODE_UNKNOWN
} flower_node_type_t;

// ═══════════════════════════════════════════════════════════════════════════
//  Network Node Structure
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    char hostname[256];          // Node hostname
    char ip_address[64];         // IP address
    uint16_t port;               // Communication port
    flower_node_type_t type;     // Node type
    
    // Capabilities
    bool has_roots;              // Can route
    bool has_flowers;            // Has GPU
    bool has_seeds;              // Can distribute work
    uint32_t petal_count;        // GPU cores
    
    // Status
    uint64_t last_heartbeat;     // Last heartbeat time
    bool is_connected;           // Connection status
    uint32_t load;               // Load percentage
    
    // Version
    char version[64];            // FlowerOS version
} flower_network_node_t;

// ═══════════════════════════════════════════════════════════════════════════
//  Opaque Handle
// ═══════════════════════════════════════════════════════════════════════════

typedef struct flower_network_context* flower_network_t;

// ═══════════════════════════════════════════════════════════════════════════
//  Initialization / Cleanup
// ═══════════════════════════════════════════════════════════════════════════

// ⚠️ RED WARNING: Initialize experimental network routing
flower_network_t flower_network_init(uint16_t port);

// Shutdown network
void flower_network_shutdown(flower_network_t net);

// Check if experimental
bool flower_network_is_experimental(void);

// Get experimental warning message
const char* flower_network_get_warning(void);

// ═══════════════════════════════════════════════════════════════════════════
//  Network Discovery
// ═══════════════════════════════════════════════════════════════════════════

// Discover network (roots spreading)
bool flower_network_discover(flower_network_t net, const char* subnet);

// Get discovered nodes
int flower_network_get_nodes(flower_network_t net, 
                             flower_network_node_t* nodes, 
                             int max_nodes);

// ═══════════════════════════════════════════════════════════════════════════
//  Root Connections
// ═══════════════════════════════════════════════════════════════════════════

// Connect to another node (establish root)
bool flower_network_connect(flower_network_t net, const char* host, uint16_t port);

// Disconnect from node
bool flower_network_disconnect(flower_network_t net, const char* host);

// Check if rooted (connected to network)
bool flower_network_is_rooted(flower_network_t net);

// Get number of connected roots
uint32_t flower_network_get_root_count(flower_network_t net);

// ═══════════════════════════════════════════════════════════════════════════
//  Theme Synchronization (EXPERIMENTAL)
// ═══════════════════════════════════════════════════════════════════════════

// ⚠️ RED WARNING: Sync theme across network
bool flower_network_sync_theme(flower_network_t net, const char* theme_name);

// Receive theme from network
bool flower_network_receive_theme(flower_network_t net, const char* source_node);

// ═══════════════════════════════════════════════════════════════════════════
//  Distributed GPU Processing (EXPERIMENTAL)
// ═══════════════════════════════════════════════════════════════════════════

// ⚠️ RED WARNING: Submit batch to network GPU nodes
bool flower_network_submit_gpu_batch(flower_network_t net, 
                                      const char** files, 
                                      int file_count);

// Check for GPU batch results
bool flower_network_check_gpu_results(flower_network_t net);

// ═══════════════════════════════════════════════════════════════════════════
//  Cluster Management (EXPERIMENTAL)
// ═══════════════════════════════════════════════════════════════════════════

// ⚠️ RED WARNING: Form new cluster (become master/TREE)
bool flower_network_form_cluster(flower_network_t net, const char* cluster_name);

// Join existing cluster
bool flower_network_join_cluster(flower_network_t net, 
                                  const char* cluster_name,
                                  const char* master_ip);

// Leave cluster
bool flower_network_leave_cluster(flower_network_t net);

// Get cluster nodes
int flower_network_get_cluster_nodes(flower_network_t net,
                                      flower_network_node_t* nodes,
                                      int max_nodes);

// ═══════════════════════════════════════════════════════════════════════════
//  Node Information
// ═══════════════════════════════════════════════════════════════════════════

// Get local node type
flower_node_type_t flower_network_get_node_type(flower_network_t net);

// Set node type
void flower_network_set_node_type(flower_network_t net, flower_node_type_t type);

// Get local node information
bool flower_network_get_local_info(flower_network_t net, flower_network_node_t* node);

// ═══════════════════════════════════════════════════════════════════════════
//  Statistics
// ═══════════════════════════════════════════════════════════════════════════

// Get bytes sent
uint64_t flower_network_get_bytes_sent(flower_network_t net);

// Get bytes received
uint64_t flower_network_get_bytes_received(flower_network_t net);

// ═══════════════════════════════════════════════════════════════════════════
//  Debug Functions
// ═══════════════════════════════════════════════════════════════════════════

// Enable debug mode
void flower_network_enable_debug(flower_network_t net, bool enable);

// Dump routing table
void flower_network_dump_routing_table(flower_network_t net);

// Get experimental status
const char* flower_network_get_status(flower_network_t net);

// ═══════════════════════════════════════════════════════════════════════════
//  Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

// Convert node type to string
const char* flower_network_node_type_string(flower_node_type_t type);

// Get local IP address
const char* flower_network_get_local_ip(void);

// Get hostname
const char* flower_network_get_hostname(void);

// Validate IPv4 address
bool flower_network_is_valid_ip(const char* ip);

#ifdef __cplusplus
}
#endif

#endif // FLOWEROS_FLOWER_NETWORK_H

// ═══════════════════════════════════════════════════════════════════════════
//  ⚠️ RED WARNING NOTICE ⚠️
//
//  This network routing API is EXPERIMENTAL and NOT production ready.
//  
//  DO NOT USE in production environments!
//  
//  Features are incomplete and may not work as expected.
//  Network security is NOT implemented.
//  Data transmission is NOT encrypted.
//  Error handling is minimal.
//  
//  For production use, stick to FlowerOS v1.2.X stable branch.
// ═══════════════════════════════════════════════════════════════════════════
