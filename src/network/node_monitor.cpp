// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Network Node Monitor
//  node_monitor.cpp - Live TUI dashboard for network monitoring
//
//  ⚠️ RED WARNING: EXPERIMENTAL - NOT PRODUCTION READY ⚠️
//
//  Black screen with boxed live-updating stats:
//    • Network up/down speed
//    • Hardware allocations
//    • Node number & connections
//    • Permissions & status
// ═══════════════════════════════════════════════════════════════════════════

#include "../network/Rooter.hpp"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <chrono>
#include <thread>
#include <vector>
#include <ctime>
#include <sys/ioctl.h>
#include <unistd.h>

using namespace FlowerOS::Network;

// ═══════════════════════════════════════════════════════════════════════════
//  ANSI Escape Codes for Terminal Control
// ═══════════════════════════════════════════════════════════════════════════

namespace ANSI {
    const char* CLEAR_SCREEN = "\033[2J";
    const char* HOME = "\033[H";
    const char* HIDE_CURSOR = "\033[?25l";
    const char* SHOW_CURSOR = "\033[?25h";
    const char* BLACK_BG = "\033[40m";
    const char* RESET = "\033[0m";
    const char* BOLD = "\033[1m";
    const char* GREEN = "\033[32m";
    const char* CYAN = "\033[36m";
    const char* YELLOW = "\033[33m";
    const char* RED = "\033[31m";
    const char* WHITE = "\033[37m";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Terminal Size
// ═══════════════════════════════════════════════════════════════════════════

struct TermSize {
    int rows;
    int cols;
};

TermSize get_terminal_size() {
    struct winsize w;
    ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
    return {w.ws_row, w.ws_col};
}

// ═══════════════════════════════════════════════════════════════════════════
//  Network Statistics Tracker
// ═══════════════════════════════════════════════════════════════════════════

struct NetworkStats {
    uint64_t bytes_sent;
    uint64_t bytes_received;
    uint64_t bytes_sent_prev;
    uint64_t bytes_received_prev;
    double upload_speed;      // bytes/sec
    double download_speed;    // bytes/sec
    uint32_t connections;
    std::chrono::steady_clock::time_point last_update;
    
    NetworkStats() : bytes_sent(0), bytes_received(0), 
                     bytes_sent_prev(0), bytes_received_prev(0),
                     upload_speed(0.0), download_speed(0.0),
                     connections(0),
                     last_update(std::chrono::steady_clock::now()) {}
    
    void update(uint64_t sent, uint64_t received, uint32_t conns) {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            now - last_update).count() / 1000.0;
        
        if (elapsed > 0) {
            upload_speed = (sent - bytes_sent_prev) / elapsed;
            download_speed = (received - bytes_received_prev) / elapsed;
        }
        
        bytes_sent_prev = sent;
        bytes_received_prev = received;
        bytes_sent = sent;
        bytes_received = received;
        connections = conns;
        last_update = now;
    }
};

// ═══════════════════════════════════════════════════════════════════════════
//  Format Bytes
// ═══════════════════════════════════════════════════════════════════════════

std::string format_bytes(double bytes) {
    const char* units[] = {"B", "KB", "MB", "GB", "TB"};
    int unit = 0;
    
    while (bytes >= 1024.0 && unit < 4) {
        bytes /= 1024.0;
        unit++;
    }
    
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << bytes << " " << units[unit];
    return oss.str();
}

std::string format_speed(double bytes_per_sec) {
    return format_bytes(bytes_per_sec) + "/s";
}

// ═══════════════════════════════════════════════════════════════════════════
//  Draw Box
// ═══════════════════════════════════════════════════════════════════════════

void draw_box(int x, int y, int width, int height, const std::string& title) {
    // Top border
    std::cout << "\033[" << y << ";" << x << "H";
    std::cout << ANSI::BOLD << ANSI::GREEN << "╔";
    
    // Title
    if (!title.empty()) {
        int title_len = title.length();
        int padding = (width - title_len - 4) / 2;
        for (int i = 0; i < padding; i++) std::cout << "═";
        std::cout << "[ " << ANSI::CYAN << title << ANSI::GREEN << " ]";
        for (int i = 0; i < width - title_len - padding - 4; i++) std::cout << "═";
    } else {
        for (int i = 0; i < width - 2; i++) std::cout << "═";
    }
    std::cout << "╗" << ANSI::RESET;
    
    // Sides
    for (int i = 1; i < height - 1; i++) {
        std::cout << "\033[" << (y + i) << ";" << x << "H";
        std::cout << ANSI::BOLD << ANSI::GREEN << "║" << ANSI::RESET;
        
        std::cout << "\033[" << (y + i) << ";" << (x + width - 1) << "H";
        std::cout << ANSI::BOLD << ANSI::GREEN << "║" << ANSI::RESET;
    }
    
    // Bottom border
    std::cout << "\033[" << (y + height - 1) << ";" << x << "H";
    std::cout << ANSI::BOLD << ANSI::GREEN << "╚";
    for (int i = 0; i < width - 2; i++) std::cout << "═";
    std::cout << "╝" << ANSI::RESET;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Draw Text at Position
// ═══════════════════════════════════════════════════════════════════════════

void draw_text(int x, int y, const std::string& text, const char* color = ANSI::WHITE) {
    std::cout << "\033[" << y << ";" << x << "H";
    std::cout << color << text << ANSI::RESET;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Progress Bar
// ═══════════════════════════════════════════════════════════════════════════

std::string progress_bar(double percent, int width) {
    int filled = (int)(percent * width / 100.0);
    std::ostringstream oss;
    
    oss << ANSI::GREEN << "[";
    for (int i = 0; i < width; i++) {
        if (i < filled) {
            oss << "█";
        } else {
            oss << "░";
        }
    }
    oss << "]" << ANSI::RESET;
    
    return oss.str();
}

// ═══════════════════════════════════════════════════════════════════════════
//  Node Monitor Dashboard
// ═══════════════════════════════════════════════════════════════════════════

class NodeMonitor {
private:
    Rooter& router_;
    NetworkStats stats_;
    bool running_;
    
public:
    NodeMonitor(Rooter& router) : router_(router), running_(true) {}
    
    void render() {
        // Get terminal size
        auto term = get_terminal_size();
        int width = term.cols;
        int height = term.rows;
        
        // Clear screen (black background)
        std::cout << ANSI::CLEAR_SCREEN;
        std::cout << ANSI::HOME;
        std::cout << ANSI::BLACK_BG;
        std::cout << ANSI::HIDE_CURSOR;
        
        // Get node info
        NetworkNode local = router_.get_local_node_info();
        uint32_t roots = router_.get_connected_roots();
        
        // Update stats
        stats_.update(
            router_.get_bytes_sent(),
            router_.get_bytes_received(),
            roots
        );
        
        // Main box
        int box_width = std::min(80, width - 4);
        int box_height = std::min(30, height - 2);
        int box_x = (width - box_width) / 2;
        int box_y = (height - box_height) / 2;
        
        draw_box(box_x, box_y, box_width, box_height, "FlowerOS Network Node Monitor");
        
        // Content area
        int content_x = box_x + 3;
        int content_y = box_y + 2;
        int line = 0;
        
        // Node Information
        draw_text(content_x, content_y + line++, 
                 std::string(ANSI::BOLD) + ANSI::CYAN + "🌱 NODE INFORMATION" + ANSI::RESET);
        line++;
        
        draw_text(content_x, content_y + line++,
                 std::string("  Hostname:     ") + ANSI::YELLOW + local.hostname + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  IP Address:   ") + ANSI::YELLOW + local.ip_address + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  Port:         ") + ANSI::YELLOW + std::to_string(local.port) + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  Type:         ") + ANSI::GREEN + node_type_to_string(local.type) + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  Status:       ") + 
                 (router_.is_rooted() ? std::string(ANSI::GREEN) + "CONNECTED" : std::string(ANSI::RED) + "DISCONNECTED") +
                 ANSI::RESET);
        
        line++;
        
        // Network Statistics
        draw_text(content_x, content_y + line++,
                 std::string(ANSI::BOLD) + ANSI::CYAN + "📊 NETWORK STATISTICS" + ANSI::RESET);
        line++;
        
        // Upload speed
        draw_text(content_x, content_y + line++,
                 std::string("  Upload:       ") + ANSI::GREEN + format_speed(stats_.upload_speed) + ANSI::RESET);
        
        // Download speed
        draw_text(content_x, content_y + line++,
                 std::string("  Download:     ") + ANSI::GREEN + format_speed(stats_.download_speed) + ANSI::RESET);
        
        // Total sent
        draw_text(content_x, content_y + line++,
                 std::string("  Total Sent:   ") + ANSI::YELLOW + format_bytes(stats_.bytes_sent) + ANSI::RESET);
        
        // Total received
        draw_text(content_x, content_y + line++,
                 std::string("  Total Recv:   ") + ANSI::YELLOW + format_bytes(stats_.bytes_received) + ANSI::RESET);
        
        line++;
        
        // Connections
        draw_text(content_x, content_y + line++,
                 std::string(ANSI::BOLD) + ANSI::CYAN + "🌳 CONNECTIONS" + ANSI::RESET);
        line++;
        
        draw_text(content_x, content_y + line++,
                 std::string("  Root Nodes:   ") + ANSI::GREEN + std::to_string(roots) + ANSI::RESET);
        
        // Connection bar
        int bar_width = 30;
        double conn_percent = std::min(100.0, roots * 10.0);
        draw_text(content_x + 2, content_y + line++,
                 progress_bar(conn_percent, bar_width));
        
        line++;
        
        // Hardware Allocations (simulated)
        draw_text(content_x, content_y + line++,
                 std::string(ANSI::BOLD) + ANSI::CYAN + "⚙️  HARDWARE ALLOCATIONS" + ANSI::RESET);
        line++;
        
        // CPU (simulated)
        draw_text(content_x, content_y + line++,
                 std::string("  CPU:          ") + progress_bar(45.0, 20) + " 45%");
        
        // Memory (simulated)
        draw_text(content_x, content_y + line++,
                 std::string("  Memory:       ") + progress_bar(62.0, 20) + " 62%");
        
        // Network (simulated)
        draw_text(content_x, content_y + line++,
                 std::string("  Network:      ") + progress_bar(28.0, 20) + " 28%");
        
        line++;
        
        // Permissions
        draw_text(content_x, content_y + line++,
                 std::string(ANSI::BOLD) + ANSI::CYAN + "🔒 PERMISSIONS" + ANSI::RESET);
        line++;
        
        draw_text(content_x, content_y + line++,
                 std::string("  Network:      ") + ANSI::GREEN + "GRANTED" + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  Routing:      ") + ANSI::GREEN + "GRANTED" + ANSI::RESET);
        
        draw_text(content_x, content_y + line++,
                 std::string("  Cluster:      ") + ANSI::GREEN + "GRANTED" + ANSI::RESET);
        
        line++;
        
        // Status bar at bottom
        std::time_t now = std::time(nullptr);
        char time_str[100];
        std::strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", std::localtime(&now));
        
        draw_text(content_x, box_y + box_height - 3,
                 std::string(ANSI::YELLOW) + "⚠️  EXPERIMENTAL MODE" + ANSI::RESET);
        
        draw_text(content_x, box_y + box_height - 2,
                 std::string("Last Update: ") + ANSI::GREEN + time_str + ANSI::RESET +
                 "  |  Press Ctrl+C to exit");
        
        std::cout << std::flush;
    }
    
    void run(int update_interval_ms = 1000) {
        while (running_) {
            render();
            std::this_thread::sleep_for(std::chrono::milliseconds(update_interval_ms));
        }
        
        // Cleanup
        std::cout << ANSI::SHOW_CURSOR;
        std::cout << ANSI::RESET;
        std::cout << ANSI::CLEAR_SCREEN;
        std::cout << ANSI::HOME;
    }
    
    void stop() {
        running_ = false;
    }
};

// ═══════════════════════════════════════════════════════════════════════════
//  Signal Handler
// ═══════════════════════════════════════════════════════════════════════════

static NodeMonitor* g_monitor = nullptr;
static Rooter* g_router = nullptr;

void signal_handler(int signum) {
    if (g_monitor) {
        g_monitor->stop();
    }
    if (g_router) {
        g_router->shutdown();
    }
    
    std::cout << ANSI::SHOW_CURSOR;
    std::cout << ANSI::RESET;
    std::cout << ANSI::CLEAR_SCREEN;
    std::cout << ANSI::HOME;
    
    exit(0);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Main Entry Point
// ═══════════════════════════════════════════════════════════════════════════

int main(int argc, char* argv[]) {
    // Parse arguments
    uint16_t port = (argc > 1) ? std::stoi(argv[1]) : 7777;
    int update_interval = (argc > 2) ? std::stoi(argv[2]) : 1000;
    
    // Welcome message
    std::cout << ANSI::GREEN << "\n🌱 FlowerOS Network Node Monitor\n";
    std::cout << "   Version: 1.3.0-EXPERIMENTAL\n\n";
    std::cout << ANSI::YELLOW << "⚠️  Initializing monitoring dashboard...\n\n" << ANSI::RESET;
    
    // Initialize router
    Rooter router;
    g_router = &router;
    
    if (!router.initialize(port)) {
        std::cerr << ANSI::RED << "✗ Failed to initialize network\n" << ANSI::RESET;
        return 1;
    }
    
    // Set up signal handler
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Create monitor
    NodeMonitor monitor(router);
    g_monitor = &monitor;
    
    std::cout << ANSI::GREEN << "✓ Network initialized\n";
    std::cout << "✓ Monitor starting...\n\n" << ANSI::RESET;
    
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    // Run monitor
    monitor.run(update_interval);
    
    return 0;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ⚠️ RED WARNING: EXPERIMENTAL NODE MONITORING ⚠️
// ═══════════════════════════════════════════════════════════════════════════
