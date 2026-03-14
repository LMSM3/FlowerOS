// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Terminal Network Instance
//  terminal_node.cpp - C++ terminal that becomes a network node
//
//  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
//
//  Usage:
//    ./terminal_node plant             - Become regular node
//    ./terminal_node grow_tree [name]  - Become master
//    ./terminal_node join <ip>         - Join garden
// ═══════════════════════════════════════════════════════════════════════════

#include "../network/Rooter.hpp"
#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <signal.h>
#include <unistd.h>

using namespace FlowerOS::Network;

// Global router instance
static Rooter* g_router = nullptr;
static bool g_running = true;

// ═══════════════════════════════════════════════════════════════════════════
//  Signal Handler
// ═══════════════════════════════════════════════════════════════════════════

void signal_handler(int signum) {
    std::cout << "\n🥀 Uprooting node..." << std::endl;
    g_running = false;
    
    if (g_router) {
        g_router->shutdown();
    }
    
    exit(0);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Display Node Status
// ═══════════════════════════════════════════════════════════════════════════

void display_status(Rooter& router) {
    NetworkNode local = router.get_local_node_info();
    
    std::cout << "\n╔═══════════════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║                                                                           ║\n";
    std::cout << "║                  FlowerOS Terminal Network Node                           ║\n";
    std::cout << "║                                                                           ║\n";
    std::cout << "╚═══════════════════════════════════════════════════════════════════════════╝\n";
    std::cout << std::endl;
    
    std::cout << "🌱 Node Information:\n";
    std::cout << "  Hostname: " << local.hostname << "\n";
    std::cout << "  IP: " << local.ip_address << "\n";
    std::cout << "  Port: " << local.port << "\n";
    std::cout << "  Type: " << node_type_to_string(local.type) << "\n";
    std::cout << std::endl;
    
    std::cout << "🌿 Network Status:\n";
    std::cout << "  Connected: " << (router.is_rooted() ? "✓ Yes" : "✗ No") << "\n";
    std::cout << "  Roots: " << router.get_connected_roots() << "\n";
    std::cout << std::endl;
    
    std::cout << "📊 Statistics:\n";
    std::cout << "  Sent: " << router.get_bytes_sent() << " bytes\n";
    std::cout << "  Received: " << router.get_bytes_received() << " bytes\n";
    std::cout << std::endl;
    
    std::cout << "\033[31m⚠️  Network features are EXPERIMENTAL\033[0m\n";
    std::cout << std::endl;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Terminal Icon Based on Type
// ═══════════════════════════════════════════════════════════════════════════

const char* get_node_icon(NodeType type) {
    switch (type) {
        case NodeType::SEED: return "🌱";
        case NodeType::SPROUT: return "🌿";
        case NodeType::PLANT: return "🪴";
        case NodeType::FLOWER: return "🌸";
        case NodeType::TREE: return "🌳";
        case NodeType::WILTED: return "🥀";
        default: return "❓";
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Plant Mode - Become Regular Node
// ═══════════════════════════════════════════════════════════════════════════

void plant_mode(uint16_t port = 7777) {
    std::cout << "\n\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m║                  🌱 PLANTING TERMINAL AS NODE 🌱                          ║\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m\n";
    std::cout << std::endl;
    
    Rooter router;
    g_router = &router;
    
    // Initialize
    if (!router.initialize(port)) {
        std::cerr << "✗ Failed to initialize router\n";
        return;
    }
    
    // Evolve to PLANT
    router.set_node_type(NodeType::PLANT);
    
    // Display status
    display_status(router);
    
    std::cout << "🪴 Terminal is now a network node.\n";
    std::cout << "   Other FlowerOS instances can connect to you.\n";
    std::cout << std::endl;
    std::cout << "Commands:\n";
    std::cout << "  Ctrl+C - Uproot (stop)\n";
    std::cout << std::endl;
    
    // Run until interrupted
    std::cout << "Running... (Press Ctrl+C to stop)\n";
    std::cout << std::endl;
    
    while (g_running) {
        // Update status periodically
        std::this_thread::sleep_for(std::chrono::seconds(30));
        
        if (g_running) {
            std::cout << get_node_icon(router.get_node_type()) 
                      << " Still running... (" 
                      << router.get_connected_roots() << " roots)\n";
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Grow Tree Mode - Become Master Node
// ═══════════════════════════════════════════════════════════════════════════

void grow_tree_mode(const std::string& cluster_name, uint16_t port = 7777) {
    std::cout << "\n\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m║                  🌳 GROWING INTO MASTER NODE 🌳                           ║\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m\n";
    std::cout << std::endl;
    
    Rooter router;
    g_router = &router;
    
    // Initialize
    if (!router.initialize(port)) {
        std::cerr << "✗ Failed to initialize router\n";
        return;
    }
    
    // Form cluster
    if (!router.form_cluster(cluster_name)) {
        std::cerr << "✗ Failed to form cluster\n";
        return;
    }
    
    // Display status
    display_status(router);
    
    std::cout << "🌳 Terminal is now the master node.\n";
    std::cout << "   Cluster: " << cluster_name << "\n";
    std::cout << "   Other nodes can join your garden.\n";
    std::cout << std::endl;
    
    NetworkNode local = router.get_local_node_info();
    std::cout << "Share with others:\n";
    std::cout << "  \033[36m./terminal_node join " << local.ip_address << "\033[0m\n";
    std::cout << std::endl;
    
    // Run until interrupted
    std::cout << "Running... (Press Ctrl+C to stop)\n";
    std::cout << std::endl;
    
    while (g_running) {
        std::this_thread::sleep_for(std::chrono::seconds(30));
        
        if (g_running) {
            std::cout << "🌳 Master running... (" 
                      << router.get_connected_roots() << " connected nodes)\n";
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Join Garden Mode - Connect to Master
// ═══════════════════════════════════════════════════════════════════════════

void join_garden_mode(const std::string& master_ip, uint16_t port = 7777, uint16_t master_port = 7777) {
    std::cout << "\n\033[36m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m\n";
    std::cout << "\033[36m║                                                                           ║\033[0m\n";
    std::cout << "\033[36m║                  🌿 JOINING GARDEN 🌿                                     ║\033[0m\n";
    std::cout << "\033[36m║                                                                           ║\033[0m\n";
    std::cout << "\033[36m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m\n";
    std::cout << std::endl;
    
    Rooter router;
    g_router = &router;
    
    // Initialize
    if (!router.initialize(port)) {
        std::cerr << "✗ Failed to initialize router\n";
        return;
    }
    
    // Connect to master
    std::cout << "🌿 Connecting to master garden...\n";
    std::cout << "   Master: " << master_ip << ":" << master_port << "\n";
    std::cout << std::endl;
    
    if (!router.connect_to_root(master_ip, master_port)) {
        std::cerr << "✗ Failed to connect to master\n";
        std::cerr << "   Make sure master is running\n";
        return;
    }
    
    // Display status
    display_status(router);
    
    std::cout << "\033[32m✓ Joined garden!\033[0m\n";
    std::cout << "   Your roots are connected to: " << master_ip << "\n";
    std::cout << std::endl;
    
    // Run until interrupted
    std::cout << "Running... (Press Ctrl+C to stop)\n";
    std::cout << std::endl;
    
    while (g_running) {
        std::this_thread::sleep_for(std::chrono::seconds(30));
        
        if (g_running) {
            std::cout << get_node_icon(router.get_node_type())
                      << " Connected to master... (heartbeat)\n";
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Interactive Mode
// ═══════════════════════════════════════════════════════════════════════════

void interactive_mode() {
    std::cout << "\n\033[36m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m\n";
    std::cout << "\033[36m║                                                                           ║\033[0m\n";
    std::cout << "\033[36m║              FlowerOS Terminal Network - Interactive Mode                 ║\033[0m\n";
    std::cout << "\033[36m║                                                                           ║\033[0m\n";
    std::cout << "\033[36m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m\n";
    std::cout << std::endl;
    
    std::cout << "\033[31m⚠️  RED WARNING: Network features are EXPERIMENTAL\033[0m\n";
    std::cout << std::endl;
    
    std::cout << "What would you like to do?\n";
    std::cout << std::endl;
    std::cout << "  1) Plant myself (become regular node)\n";
    std::cout << "  2) Grow into tree (become master node)\n";
    std::cout << "  3) Join existing garden (connect to master)\n";
    std::cout << "  4) Exit\n";
    std::cout << std::endl;
    
    int choice;
    std::cout << "Choose option (1-4): ";
    std::cin >> choice;
    
    std::string cluster, ip;
    
    switch (choice) {
        case 1:
            plant_mode();
            break;
            
        case 2:
            std::cout << "Cluster name [my_garden]: ";
            std::cin >> cluster;
            if (cluster.empty()) cluster = "my_garden";
            grow_tree_mode(cluster);
            break;
            
        case 3:
            std::cout << "Master IP address: ";
            std::cin >> ip;
            if (!ip.empty()) {
                join_garden_mode(ip);
            } else {
                std::cerr << "⚠️  IP address required\n";
            }
            break;
            
        case 4:
            std::cout << "Exiting...\n";
            break;
            
        default:
            std::cerr << "⚠️  Invalid choice\n";
            break;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Main Entry Point
// ═══════════════════════════════════════════════════════════════════════════

int main(int argc, char* argv[]) {
    // Set up signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    std::cout << "\n\033[32m🌱 FlowerOS Terminal Network Instance\033[0m\n";
    std::cout << "   Version: 1.3.0-EXPERIMENTAL\n";
    std::cout << std::endl;
    
    // Parse command line
    if (argc < 2) {
        interactive_mode();
        return 0;
    }
    
    std::string command = argv[1];
    
    if (command == "plant") {
        uint16_t port = (argc > 2) ? std::stoi(argv[2]) : 7777;
        plant_mode(port);
    }
    else if (command == "grow_tree") {
        std::string cluster = (argc > 2) ? argv[2] : "my_garden";
        uint16_t port = (argc > 3) ? std::stoi(argv[3]) : 7777;
        grow_tree_mode(cluster, port);
    }
    else if (command == "join") {
        if (argc < 3) {
            std::cerr << "Usage: " << argv[0] << " join <master_ip> [port] [master_port]\n";
            return 1;
        }
        std::string master_ip = argv[2];
        uint16_t port = (argc > 3) ? std::stoi(argv[3]) : 7777;
        uint16_t master_port = (argc > 4) ? std::stoi(argv[4]) : 7777;
        join_garden_mode(master_ip, port, master_port);
    }
    else if (command == "--help" || command == "-h") {
        std::cout << "FlowerOS Terminal Network Instance\n";
        std::cout << "\n";
        std::cout << "Usage:\n";
        std::cout << "  " << argv[0] << " plant [port]              - Become regular node\n";
        std::cout << "  " << argv[0] << " grow_tree [name] [port]   - Become master node\n";
        std::cout << "  " << argv[0] << " join <ip> [port]          - Join existing garden\n";
        std::cout << "  " << argv[0] << " (no args)                 - Interactive mode\n";
        std::cout << "\n";
        std::cout << "Examples:\n";
        std::cout << "  " << argv[0] << " plant                     - Plant on port 7777\n";
        std::cout << "  " << argv[0] << " grow_tree research        - Become master of 'research' cluster\n";
        std::cout << "  " << argv[0] << " join 192.168.1.100        - Join master at IP\n";
        std::cout << "\n";
        std::cout << "\033[31m⚠️  All features are EXPERIMENTAL\033[0m\n";
        std::cout << "\n";
    }
    else {
        std::cerr << "Unknown command: " << command << "\n";
        std::cerr << "Try: " << argv[0] << " --help\n";
        return 1;
    }
    
    return 0;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ⚠️ RED WARNING: EXPERIMENTAL TERMINAL NETWORK CODE ⚠️
// ═══════════════════════════════════════════════════════════════════════════
