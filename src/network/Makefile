# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Network Routing System - Makefile
#  
#  ⚠️ RED WARNING: EXPERIMENTAL BUILD SYSTEM ⚠️
# ═══════════════════════════════════════════════════════════════════════════

# Compiler settings
CXX = g++
CC = gcc
CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -fPIC
CFLAGS = -std=c11 -Wall -Wextra -O2 -fPIC
LDFLAGS = -lpthread

# Directories
SRC_DIR = .
BUILD_DIR = build
BIN_DIR = ../bin

# Target library and executables
TARGET_LIB = libflowernetwork.so
TARGET_STATIC = libflowernetwork.a
TARGET_TERMINAL = terminal_node
TARGET_MONITOR = node_monitor
TARGET_DISCOVERY = node_discovery

# Source files
CXX_SOURCES = Rooting.cpp
CXX_TERMINAL = terminal_node.cpp
CXX_MONITOR = node_monitor.cpp
CXX_DISCOVERY = node_discovery.cpp
C_SOURCES = 
HEADERS = Rooter.hpp flower_network.h

# Object files
CXX_OBJECTS = $(CXX_SOURCES:%.cpp=$(BUILD_DIR)/%.o)
C_OBJECTS = $(C_SOURCES:%.c=$(BUILD_DIR)/%.o)
ALL_OBJECTS = $(CXX_OBJECTS) $(C_OBJECTS)

# ═══════════════════════════════════════════════════════════════════════════
#  Targets
# ═══════════════════════════════════════════════════════════════════════════

.PHONY: all clean install experimental-warning

all: experimental-warning $(BUILD_DIR) $(TARGET_LIB) $(TARGET_STATIC) $(TARGET_TERMINAL) $(TARGET_MONITOR) $(TARGET_DISCOVERY)

experimental-warning:
	@echo ""
	@echo "\033[31m╔═══════════════════════════════════════════════════════════════════════════╗\033[0m"
	@echo "\033[31m║                                                                           ║\033[0m"
	@echo "\033[31m║              ⚠️  RED WARNING: EXPERIMENTAL BUILD ⚠️                       ║\033[0m"
	@echo "\033[31m║                                                                           ║\033[0m"
	@echo "\033[31m║  You are building the FlowerOS Network Routing System.                   ║\033[0m"
	@echo "\033[31m║  This is EXPERIMENTAL code and NOT production ready!                     ║\033[0m"
	@echo "\033[31m║                                                                           ║\033[0m"
	@echo "\033[31m║  Features included:                                                       ║\033[0m"
	@echo "\033[31m║   • Network routing and discovery (incomplete)                           ║\033[0m"
	@echo "\033[31m║   • Distributed theme synchronization (stub)                             ║\033[0m"
	@echo "\033[31m║   • Remote GPU batch processing (not implemented)                        ║\033[0m"
	@echo "\033[31m║   • Cluster management (basic)                                           ║\033[0m"
	@echo "\033[31m║                                                                           ║\033[0m"
	@echo "\033[31m║  DO NOT USE IN PRODUCTION ENVIRONMENTS!                                  ║\033[0m"
	@echo "\033[31m║                                                                           ║\033[0m"
	@echo "\033[31m╚═══════════════════════════════════════════════════════════════════════════╝\033[0m"
	@echo ""
	@sleep 2

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BIN_DIR)

# Compile C++ sources
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp $(HEADERS)
	@echo "🌱 Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Compile C sources
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADERS)
	@echo "🌱 Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Build shared library
$(TARGET_LIB): $(ALL_OBJECTS)
	@echo "\033[33m🌱 Linking shared library $(TARGET_LIB)...\033[0m"
	$(CXX) -shared -o $(BUILD_DIR)/$(TARGET_LIB) $(ALL_OBJECTS) $(LDFLAGS)
	@echo "\033[32m✓ Built: $(BUILD_DIR)/$(TARGET_LIB)\033[0m"
	@echo "\033[31m  ⚠️  WARNING: Experimental library\033[0m"

# Build static library
$(TARGET_STATIC): $(ALL_OBJECTS)
	@echo "\033[33m🌱 Creating static library $(TARGET_STATIC)...\033[0m"
	ar rcs $(BUILD_DIR)/$(TARGET_STATIC) $(ALL_OBJECTS)
	@echo "\033[32m✓ Built: $(BUILD_DIR)/$(TARGET_STATIC)\033[0m"

# Build terminal node executable
$(TARGET_TERMINAL): $(CXX_TERMINAL) $(TARGET_STATIC)
	@echo "\033[33m🌱 Building terminal network node...\033[0m"
	$(CXX) $(CXXFLAGS) $(CXX_TERMINAL) $(BUILD_DIR)/$(TARGET_STATIC) $(LDFLAGS) -o $(BUILD_DIR)/$(TARGET_TERMINAL)
	@echo "\033[32m✓ Built: $(BUILD_DIR)/$(TARGET_TERMINAL)\033[0m"
	@echo "\033[31m  ⚠️  WARNING: Experimental terminal network\033[0m"

# Build node monitor executable
$(TARGET_MONITOR): $(CXX_MONITOR) $(TARGET_STATIC)
	@echo "\033[33m🌱 Building node monitor dashboard...\033[0m"
	$(CXX) $(CXXFLAGS) $(CXX_MONITOR) $(BUILD_DIR)/$(TARGET_STATIC) $(LDFLAGS) -o $(BUILD_DIR)/$(TARGET_MONITOR)
	@echo "\033[32m✓ Built: $(BUILD_DIR)/$(TARGET_MONITOR)\033[0m"
	@echo "\033[31m  ⚠️  WARNING: Experimental monitoring system\033[0m"

# Build node discovery executable
$(TARGET_DISCOVERY): $(CXX_DISCOVERY) $(TARGET_STATIC)
	@echo "\033[33m🌱 Building node discovery system...\033[0m"
	$(CXX) $(CXXFLAGS) $(CXX_DISCOVERY) $(BUILD_DIR)/$(TARGET_STATIC) $(LDFLAGS) -o $(BUILD_DIR)/$(TARGET_DISCOVERY)
	@echo "\033[32m✓ Built: $(BUILD_DIR)/$(TARGET_DISCOVERY)\033[0m"
	@echo "\033[31m  ⚠️  WARNING: Experimental auto-discovery\033[0m"

# Install libraries and executables
install: all
	@echo ""
	@echo "\033[31m⚠️  Installing EXPERIMENTAL network tools...\033[0m"
	cp $(BUILD_DIR)/$(TARGET_LIB) $(BIN_DIR)/
	cp $(BUILD_DIR)/$(TARGET_STATIC) $(BIN_DIR)/
	cp $(BUILD_DIR)/$(TARGET_TERMINAL) $(BIN_DIR)/
	cp $(BUILD_DIR)/$(TARGET_MONITOR) $(BIN_DIR)/
	cp $(BUILD_DIR)/$(TARGET_DISCOVERY) $(BIN_DIR)/
	chmod +x $(BIN_DIR)/$(TARGET_TERMINAL)
	chmod +x $(BIN_DIR)/$(TARGET_MONITOR)
	chmod +x $(BIN_DIR)/$(TARGET_DISCOVERY)
	cp $(HEADERS) $(BIN_DIR)/
	@echo "\033[32m✓ Libraries installed to $(BIN_DIR)\033[0m"
	@echo "\033[32m✓ Terminal node installed: $(BIN_DIR)/$(TARGET_TERMINAL)\033[0m"
	@echo "\033[32m✓ Node monitor installed: $(BIN_DIR)/$(TARGET_MONITOR)\033[0m"
	@echo "\033[32m✓ Node discovery installed: $(BIN_DIR)/$(TARGET_DISCOVERY)\033[0m"
	@echo "\033[31m  ⚠️  Remember: These are experimental!\033[0m"
	@echo ""

# Clean build artifacts
clean:
	@echo "🧹 Cleaning network build..."
	rm -rf $(BUILD_DIR)
	rm -f $(BIN_DIR)/$(TARGET_LIB)
	rm -f $(BIN_DIR)/$(TARGET_STATIC)
	rm -f $(BIN_DIR)/$(TARGET_TERMINAL)
	rm -f $(BIN_DIR)/$(TARGET_MONITOR)
	rm -f $(BIN_DIR)/$(TARGET_DISCOVERY)
	@echo "✓ Clean complete"

# ═══════════════════════════════════════════════════════════════════════════
#  Help
# ═══════════════════════════════════════════════════════════════════════════

help:
	@echo "FlowerOS Network Routing System - Build System"
	@echo ""
	@echo "\033[31m⚠️  RED WARNING: This is experimental code!\033[0m"
	@echo ""
	@echo "Targets:"
	@echo "  make all      - Build network libraries (with warning)"
	@echo "  make install  - Install to ../bin (experimental)"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "Output:"
	@echo "  $(BUILD_DIR)/$(TARGET_LIB)     - Shared library"
	@echo "  $(BUILD_DIR)/$(TARGET_STATIC)  - Static library"
	@echo ""
	@echo "\033[33mNote: Network routing is NOT production ready!\033[0m"
	@echo ""

# ═══════════════════════════════════════════════════════════════════════════
#  Build Information
# ═══════════════════════════════════════════════════════════════════════════

.PHONY: info

info:
	@echo "FlowerOS Network Routing System"
	@echo "Version: 1.3.0-EXPERIMENTAL"
	@echo "Status: \033[31mNOT PRODUCTION READY\033[0m"
	@echo ""
	@echo "Compiler: $(CXX)"
	@echo "C++ Standard: C++17"
	@echo "Flags: $(CXXFLAGS)"
	@echo ""
	@echo "Features:"
	@echo "  • Network routing (roots spreading)"
	@echo "  • Node discovery"
	@echo "  • Cluster management"
	@echo "  • Theme synchronization (stub)"
	@echo "  • Distributed GPU (stub)"
	@echo ""
	@echo "\033[31m⚠️  All features are experimental!\033[0m"
	@echo ""
