// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Network Routing System - "Root Network"
//  Rooter.hpp - Network Routing Header
//
//  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
//
//  Botanical naming: "Roots" spread through network, connecting systems
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWEROS_ROOTER_HPP
#define FLOWEROS_ROOTER_HPP

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cstdint>
#include <netinet/in.h>

// ═══════════════════════════════════════════════════════════════════════════
//  Version and Build Information
// ═══════════════════════════════════════════════════════════════════════════

#define FLOWEROS_ROOTER_VERSION "1.3.0-EXPERIMENTAL"
#define FLOWEROS_ROOTER_BUILD "ROOT_NETWORK_ALPHA"

// ⚠️ RED WARNING: This is experimental code
#define FLOWEROS_NETWORK_EXPERIMENTAL 1
#define FLOWEROS_NETWORK_STATUS "NOT_PRODUCTION_READY"

// ═══════════════════════════════════════════════════════════════════════════
//  Network Configuration
// ═══════════════════════════════════════════════════════════════════════════

namespace FlowerOS {
namespace Network {

// Default ports (botanical themed)
constexpr uint16_t DEFAULT_ROOT_PORT = 7777;      // Root communication
constexpr uint16_t DEFAULT_FLOWER_PORT = 8888;    // Flower messages
constexpr uint16_t DEFAULT_SEED_PORT = 9999;      // Seed distribution

// Network timeouts (milliseconds)
constexpr int ROOT_TIMEOUT = 5000;                // Root connection timeout
constexpr int HEARTBEAT_INTERVAL = 1000;          // Heartbeat frequency
constexpr int DISCOVERY_INTERVAL = 30000;         // Network discovery

// ═══════════════════════════════════════════════════════════════════════════
//  Network Node Types (Botanical)
// ═══════════════════════════════════════════════════════════════════════════

enum class NodeType {
    SEED,           // New node, not yet established
    SPROUT,         // Node establishing connections
    PLANT,          // Established node
    FLOWER,         // Producing node (GPU capable)
    TREE,           // Master node (coordinator)
    WILTED,         // Disconnected/failed node
    UNKNOWN         // Unknown state
};

// ═══════════════════════════════════════════════════════════════════════════
//  Network Message Types
// ═══════════════════════════════════════════════════════════════════════════

enum class MessageType : uint32_t {
    // Discovery messages
    ROOT_HELLO = 0x01,          // Initial connection
    ROOT_GOODBYE = 0x02,        // Disconnect notification
    ROOT_HEARTBEAT = 0x03,      // Keep-alive
    ROOT_DISCOVERY = 0x04,      // Network discovery
    
    // Data transfer
    THEME_SYNC = 0x10,          // Theme synchronization
    CONFIG_SYNC = 0x11,         // Config synchronization
    ASCII_TRANSFER = 0x12,      // ASCII art transfer
    
    // Computation
    GPU_BATCH_REQUEST = 0x20,   // GPU batch processing
    GPU_BATCH_RESULT = 0x21,    // GPU results
    KERNEL_REQUEST = 0x22,      // Kernel operation
    KERNEL_RESULT = 0x23,       // Kernel result
    
    // Cluster management
    CLUSTER_JOIN = 0x30,        // Join cluster
    CLUSTER_LEAVE = 0x31,       // Leave cluster
    CLUSTER_STATUS = 0x32,      // Status update
    
    // Error messages
    ERROR = 0xFF                // Error response
};

// ═══════════════════════════════════════════════════════════════════════════
//  Network Node Representation
// ═══════════════════════════════════════════════════════════════════════════

struct NetworkNode {
    std::string hostname;           // Node hostname
    std::string ip_address;         // IP address
    uint16_t port;                  // Communication port
    NodeType type;                  // Node type
    
    // Capabilities (botanical themed)
    bool has_roots;                 // Can route traffic
    bool has_flowers;               // Has GPU capability
    bool has_seeds;                 // Can distribute work
    uint32_t petal_count;           // GPU core count
    
    // Status
    uint64_t last_heartbeat;        // Last heartbeat timestamp
    bool is_connected;              // Connection status
    uint32_t load;                  // Current load (0-100)
    
    // Metadata
    std::string version;            // FlowerOS version
    std::map<std::string, std::string> metadata;
};

// ═══════════════════════════════════════════════════════════════════════════
//  Network Message Structure
// ═══════════════════════════════════════════════════════════════════════════

struct NetworkMessage {
    MessageType type;               // Message type
    uint32_t sequence;              // Sequence number
    uint64_t timestamp;             // Timestamp
    
    std::string source_node;        // Source node ID
    std::string dest_node;          // Destination node ID
    
    std::vector<uint8_t> payload;   // Message payload
    uint32_t payload_size;          // Payload size
    
    // Checksum for integrity
    uint32_t checksum;
};

// ═══════════════════════════════════════════════════════════════════════════
//  Root Network Router (Main Class)
// ═══════════════════════════════════════════════════════════════════════════

class Rooter {
public:
    // Constructor/Destructor
    Rooter();
    ~Rooter();
    
    // ⚠️ RED WARNING: Experimental initialization
    bool initialize(uint16_t root_port = DEFAULT_ROOT_PORT);
    void shutdown();
    
    // Network discovery (roots spreading)
    bool discover_network(const std::string& subnet = "");
    std::vector<NetworkNode> get_discovered_nodes() const;
    
    // Root connections (establish network)
    bool connect_to_root(const std::string& host, uint16_t port);
    bool disconnect_from_root(const std::string& host);
    bool is_rooted() const;  // Connected to network
    
    // Message routing
    bool send_message(const NetworkMessage& msg);
    bool broadcast_message(const NetworkMessage& msg);
    std::vector<NetworkMessage> receive_messages();
    
    // Theme synchronization (experimental)
    bool sync_theme_to_network(const std::string& theme_name);
    bool receive_theme_from_network(const std::string& source_node);
    
    // Distributed GPU processing (experimental)
    bool submit_gpu_batch(const std::vector<std::string>& files);
    bool check_gpu_results();
    
    // Cluster management
    bool form_cluster(const std::string& cluster_name);
    bool join_cluster(const std::string& cluster_name, const std::string& master_ip);
    bool leave_cluster();
    std::vector<NetworkNode> get_cluster_nodes() const;
    
    // Node management
    NodeType get_node_type() const;
    void set_node_type(NodeType type);
    NetworkNode get_local_node_info() const;
    
    // Statistics
    uint32_t get_connected_roots() const;
    uint64_t get_bytes_sent() const;
    uint64_t get_bytes_received() const;
    
    // ⚠️ RED WARNING: Debug/experimental features
    void enable_debug_mode(bool enable);
    void dump_routing_table() const;
    std::string get_experimental_status() const;

private:
    // Internal state
    struct RooterImpl;
    std::unique_ptr<RooterImpl> impl_;
    
    // Socket management
    int root_socket_;
    std::map<std::string, int> node_sockets_;
    
    // Routing table (botanical: root network map)
    std::map<std::string, NetworkNode> routing_table_;
    
    // Local node info
    NetworkNode local_node_;
    NodeType node_type_;
    
    // Cluster info
    std::string cluster_name_;
    bool is_cluster_master_;
    
    // Statistics
    uint64_t bytes_sent_;
    uint64_t bytes_received_;
    uint32_t messages_sent_;
    uint32_t messages_received_;
    
    // Internal methods
    bool initialize_socket(uint16_t port);
    void heartbeat_thread();
    void discovery_thread();
    void receive_thread();
    
    uint32_t calculate_checksum(const std::vector<uint8_t>& data);
    bool verify_checksum(const NetworkMessage& msg);
    
    void update_routing_table(const NetworkNode& node);
    NetworkNode* find_route_to(const std::string& dest);
};

// ═══════════════════════════════════════════════════════════════════════════
//  Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

// Convert node type to string (botanical names)
const char* node_type_to_string(NodeType type);

// Convert message type to string
const char* message_type_to_string(MessageType type);

// Network utility functions
std::string get_local_ip();
std::string get_hostname();
bool is_valid_ipv4(const std::string& ip);

// ⚠️ RED WARNING: Experimental status check
bool is_network_routing_experimental();
const char* get_experimental_warning();

} // namespace Network
} // namespace FlowerOS

#endif // FLOWEROS_ROOTER_HPP

// ═══════════════════════════════════════════════════════════════════════════
//  ⚠️ RED WARNING NOTICE ⚠️
//
//  This is experimental code for FlowerOS v1.3.X development branch.
//  
//  DO NOT USE IN PRODUCTION ENVIRONMENTS!
//  
//  Features marked experimental:
//  - Network routing and discovery
//  - Distributed theme synchronization
//  - Remote GPU batch processing
//  - Cluster formation and management
//  
//  For production use, stick to FlowerOS v1.2.X
// ═══════════════════════════════════════════════════════════════════════════
