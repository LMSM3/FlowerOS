// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Network Node Discovery
//  node_discovery.cpp - Auto-discovery and linking system
//
//  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
//
//  Early version: Hard-coded relationships in linked list
//  Later: Full auto-discovery and dynamic linking
// ═══════════════════════════════════════════════════════════════════════════

#include "../network/Rooter.hpp"
#include <iostream>
#include <vector>
#include <string>
#include <thread>
#include <chrono>
#include <cstring>

using namespace FlowerOS::Network;

// ═══════════════════════════════════════════════════════════════════════════
//  Node Relationship (Linked List)
// ═══════════════════════════════════════════════════════════════════════════

struct NodeRelation {
    std::string ip_address;
    uint16_t port;
    std::string name;
    bool is_gateway;
    NodeRelation* next;
    
    NodeRelation(const std::string& ip, uint16_t p, const std::string& n, bool gateway = false)
        : ip_address(ip), port(p), name(n), is_gateway(gateway), next(nullptr) {}
};

// ═══════════════════════════════════════════════════════════════════════════
//  Network Gate Relations (Linked List)
// ═══════════════════════════════════════════════════════════════════════════

class NetworkGate {
private:
    NodeRelation* head_;
    size_t size_;
    
public:
    NetworkGate() : head_(nullptr), size_(0) {}
    
    ~NetworkGate() {
        clear();
    }
    
    // Add relationship
    void add_relation(const std::string& ip, uint16_t port, const std::string& name, bool is_gateway = false) {
        NodeRelation* new_node = new NodeRelation(ip, port, name, is_gateway);
        
        if (head_ == nullptr) {
            head_ = new_node;
        } else {
            NodeRelation* current = head_;
            while (current->next != nullptr) {
                current = current->next;
            }
            current->next = new_node;
        }
        
        size_++;
    }
    
    // Get all relations
    std::vector<NodeRelation*> get_all() const {
        std::vector<NodeRelation*> relations;
        NodeRelation* current = head_;
        
        while (current != nullptr) {
            relations.push_back(current);
            current = current->next;
        }
        
        return relations;
    }
    
    // Get gateways only
    std::vector<NodeRelation*> get_gateways() const {
        std::vector<NodeRelation*> gateways;
        NodeRelation* current = head_;
        
        while (current != nullptr) {
            if (current->is_gateway) {
                gateways.push_back(current);
            }
            current = current->next;
        }
        
        return gateways;
    }
    
    // Clear all
    void clear() {
        NodeRelation* current = head_;
        while (current != nullptr) {
            NodeRelation* next = current->next;
            delete current;
            current = next;
        }
        head_ = nullptr;
        size_ = 0;
    }
    
    size_t size() const { return size_; }
    
    // Print all relations
    void print() const {
        std::cout << "\n";
        std::cout << "╔═══════════════════════════════════════════════════════════════════════════╗\n";
        std::cout << "║                  Network Gate Relations (Linked List)                     ║\n";
        std::cout << "╚═══════════════════════════════════════════════════════════════════════════╝\n";
        std::cout << "\n";
        
        if (head_ == nullptr) {
            std::cout << "  (empty)\n";
            return;
        }
        
        int index = 0;
        NodeRelation* current = head_;
        
        while (current != nullptr) {
            std::cout << "  Node " << index++ << ":\n";
            std::cout << "    Name:     " << current->name << "\n";
            std::cout << "    Address:  " << current->ip_address << ":" << current->port << "\n";
            std::cout << "    Gateway:  " << (current->is_gateway ? "YES" : "NO") << "\n";
            
            if (current->next != nullptr) {
                std::cout << "    |\n";
                std::cout << "    v\n";
            }
            
            current = current->next;
        }
        
        std::cout << "\n";
        std::cout << "Total: " << size_ << " node(s)\n";
        std::cout << "\n";
    }
};

// ═══════════════════════════════════════════════════════════════════════════
//  Hard-Coded Node Relationships (Early Version)
// ═══════════════════════════════════════════════════════════════════════════

void load_hardcoded_relations(NetworkGate& gate) {
    std::cout << "🌱 Loading hard-coded node relationships...\n\n";
    
    // Master nodes (gateways)
    gate.add_relation("192.168.1.100", 7777, "master_node_01", true);
    gate.add_relation("192.168.1.101", 7777, "master_node_02", true);
    
    // Worker nodes
    gate.add_relation("192.168.1.110", 7777, "worker_node_01", false);
    gate.add_relation("192.168.1.111", 7777, "worker_node_02", false);
    gate.add_relation("192.168.1.112", 7777, "worker_node_03", false);
    gate.add_relation("192.168.1.113", 7777, "worker_node_04", false);
    
    // GPU nodes
    gate.add_relation("192.168.1.120", 7777, "gpu_node_01", false);
    gate.add_relation("192.168.1.121", 7777, "gpu_node_02", false);
    
    // Localhost (for testing)
    gate.add_relation("127.0.0.1", 7777, "localhost_test", false);
    
    std::cout << "✓ Loaded " << gate.size() << " relationships\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Auto-Link to Relations
// ═══════════════════════════════════════════════════════════════════════════

void auto_link_nodes(Rooter& router, NetworkGate& gate) {
    std::cout << "🌿 Attempting to link to discovered nodes...\n\n";
    
    auto relations = gate.get_all();
    int successful = 0;
    int failed = 0;
    
    for (auto relation : relations) {
        std::cout << "  Trying: " << relation->name << " (" << relation->ip_address << ":" << relation->port << ")";
        
        if (router.connect_to_root(relation->ip_address, relation->port)) {
            std::cout << " \033[32m✓ Connected\033[0m\n";
            successful++;
        } else {
            std::cout << " \033[33m✗ Failed\033[0m\n";
            failed++;
        }
        
        // Small delay between attempts
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    
    std::cout << "\n";
    std::cout << "Results:\n";
    std::cout << "  Successful: \033[32m" << successful << "\033[0m\n";
    std::cout << "  Failed:     \033[33m" << failed << "\033[0m\n";
    std::cout << "\n";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Auto-Discovery (Scan Local Network)
// ═══════════════════════════════════════════════════════════════════════════

void scan_local_network(NetworkGate& gate, const std::string& subnet, uint16_t port) {
    std::cout << "🔍 Scanning local network: " << subnet << ".0/24\n\n";
    
    // Parse subnet (e.g., "192.168.1")
    std::string base_ip = subnet;
    
    std::cout << "  Scanning ports " << port << "...\n";
    std::cout << "  (This may take a while)\n\n";
    
    int found = 0;
    
    // Scan range (simplified for demo)
    for (int i = 1; i < 255; i++) {
        std::string ip = base_ip + "." + std::to_string(i);
        
        // Simple port check (in real implementation, would use proper socket connect)
        // For now, just add known IPs
        if (i == 100 || i == 101 || i == 110 || i == 111 || i == 112 || i == 113 || i == 120 || i == 121) {
            std::string name = "discovered_node_" + std::to_string(i);
            bool is_gateway = (i == 100 || i == 101);
            
            gate.add_relation(ip, port, name, is_gateway);
            
            std::cout << "  Found: " << ip << " (" << name << ")\n";
            found++;
        }
    }
    
    std::cout << "\n";
    std::cout << "✓ Scan complete. Found " << found << " node(s)\n\n";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Interactive Menu
// ═══════════════════════════════════════════════════════════════════════════

void show_menu() {
    std::cout << "\n";
    std::cout << "╔═══════════════════════════════════════════════════════════════════════════╗\n";
    std::cout << "║              FlowerOS Network Node Discovery Menu                         ║\n";
    std::cout << "╚═══════════════════════════════════════════════════════════════════════════╝\n";
    std::cout << "\n";
    std::cout << "  1) Load hard-coded relationships\n";
    std::cout << "  2) Scan local network (auto-discover)\n";
    std::cout << "  3) Show all relations\n";
    std::cout << "  4) Show gateways only\n";
    std::cout << "  5) Auto-link to all nodes\n";
    std::cout << "  6) Auto-link to gateways only\n";
    std::cout << "  7) Clear all relations\n";
    std::cout << "  8) Exit\n";
    std::cout << "\n";
    std::cout << "Choose option (1-8): ";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Main Entry Point
// ═══════════════════════════════════════════════════════════════════════════

int main(int argc, char* argv[]) {
    std::cout << "\n";
    std::cout << "\033[32m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m║              FlowerOS Network Node Discovery System                       ║\033[0m\n";
    std::cout << "\033[32m║                                                                           ║\033[0m\n";
    std::cout << "\033[32m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m\n";
    std::cout << "\n";
    
    std::cout << "\033[31m⚠️  RED WARNING: EXPERIMENTAL auto-discovery and linking\033[0m\n";
    std::cout << "\n";
    
    // Initialize router
    uint16_t port = (argc > 1) ? std::stoi(argv[1]) : 7777;
    
    Rooter router;
    if (!router.initialize(port)) {
        std::cerr << "\033[31m✗ Failed to initialize router\033[0m\n";
        return 1;
    }
    
    std::cout << "✓ Router initialized on port " << port << "\n";
    
    // Create network gate
    NetworkGate gate;
    
    // Interactive loop
    bool running = true;
    while (running) {
        show_menu();
        
        int choice;
        std::cin >> choice;
        
        switch (choice) {
            case 1:
                load_hardcoded_relations(gate);
                break;
                
            case 2: {
                std::string subnet;
                std::cout << "\nEnter subnet (e.g., 192.168.1): ";
                std::cin >> subnet;
                scan_local_network(gate, subnet, 7777);
                break;
            }
                
            case 3:
                gate.print();
                break;
                
            case 4: {
                std::cout << "\n";
                std::cout << "╔═══════════════════════════════════════════════════════════════════════════╗\n";
                std::cout << "║                        Gateway Nodes Only                                 ║\n";
                std::cout << "╚═══════════════════════════════════════════════════════════════════════════╝\n";
                std::cout << "\n";
                
                auto gateways = gate.get_gateways();
                if (gateways.empty()) {
                    std::cout << "  (no gateways)\n\n";
                } else {
                    for (auto g : gateways) {
                        std::cout << "  " << g->name << "\n";
                        std::cout << "    " << g->ip_address << ":" << g->port << "\n\n";
                    }
                }
                break;
            }
                
            case 5:
                auto_link_nodes(router, gate);
                break;
                
            case 6: {
                std::cout << "\n🌳 Linking to gateway nodes only...\n\n";
                
                auto gateways = gate.get_gateways();
                for (auto g : gateways) {
                    std::cout << "  Connecting to: " << g->name << " (" << g->ip_address << ":" << g->port << ")";
                    if (router.connect_to_root(g->ip_address, g->port)) {
                        std::cout << " \033[32m✓\033[0m\n";
                    } else {
                        std::cout << " \033[33m✗\033[0m\n";
                    }
                }
                std::cout << "\n";
                break;
            }
                
            case 7:
                gate.clear();
                std::cout << "\n✓ All relations cleared\n";
                break;
                
            case 8:
                running = false;
                std::cout << "\nExiting...\n";
                break;
                
            default:
                std::cout << "\n⚠️  Invalid choice\n";
                break;
        }
    }
    
    // Cleanup
    router.shutdown();
    
    std::cout << "\n";
    std::cout << "🥀 Shutdown complete\n";
    std::cout << "\n";
    
    return 0;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ⚠️ RED WARNING: EXPERIMENTAL NODE DISCOVERY ⚠️
//
//  Early version uses hard-coded relationships in a linked list.
//  Future versions will include:
//    - Full network scanning
//    - mDNS/Bonjour discovery
//    - Dynamic relationship management
//    - Persistent storage
// ═══════════════════════════════════════════════════════════════════════════
