# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Kernel Build System
#  Plant-themed operating system core
# ═══════════════════════════════════════════════════════════════════════════

CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -O2 -g
LDFLAGS = -lm -lpthread

# Build type (BARE_METAL, PARASITIC, CONTAINER)
BUILD_TYPE ?= PARASITIC

ifeq ($(BUILD_TYPE),BARE_METAL)
    CFLAGS += -DFLOWEROS_BUILD_TYPE=1
else ifeq ($(BUILD_TYPE),PARASITIC)
    CFLAGS += -DFLOWEROS_BUILD_TYPE=2
else ifeq ($(BUILD_TYPE),CONTAINER)
    CFLAGS += -DFLOWEROS_BUILD_TYPE=3
endif

# Source files
KERNEL_SRC = flower_kernel.c
DEMO_SRC = kernel_demo.c

# Object files
KERNEL_OBJ = $(KERNEL_SRC:.c=.o)
DEMO_OBJ = $(DEMO_SRC:.c=.o)

# Output binaries
DEMO_BIN = kernel_demo

# ═══════════════════════════════════════════════════════════════════════════
#  Targets
# ═══════════════════════════════════════════════════════════════════════════

.PHONY: all clean demo help

all: demo

demo: $(DEMO_BIN)

$(DEMO_BIN): $(KERNEL_OBJ) $(DEMO_OBJ)
	@echo "$(shell echo -e '\033[35m')🌸 Linking kernel demo...$(shell echo -e '\033[0m')"
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "$(shell echo -e '\033[32m')✓ Demo built: $@$(shell echo -e '\033[0m')"

%.o: %.c flower_kernel.h
	@echo "$(shell echo -e '\033[36m')🌱 Compiling $<...$(shell echo -e '\033[0m')"
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	@echo "$(shell echo -e '\033[33m')🍂 Cleaning build artifacts...$(shell echo -e '\033[0m')"
	rm -f $(KERNEL_OBJ) $(DEMO_OBJ) $(DEMO_BIN)
	@echo "$(shell echo -e '\033[32m')✓ Clean complete$(shell echo -e '\033[0m')"

run: demo
	@echo ""
	@echo "$(shell echo -e '\033[35m')🌸 Running FlowerOS Kernel Demo...$(shell echo -e '\033[0m')"
	@echo ""
	./$(DEMO_BIN)

help:
	@echo ""
	@echo "╔═══════════════════════════════════════════════════════════════════════════╗"
	@echo "║              🌸 FlowerOS Kernel Build System 🌸                          ║"
	@echo "╚═══════════════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Targets:"
	@echo "  make            - Build kernel demo (default)"
	@echo "  make demo       - Build kernel demo"
	@echo "  make run        - Build and run demo"
	@echo "  make clean      - Remove build artifacts"
	@echo "  make help       - Show this help"
	@echo ""
	@echo "Build Types:"
	@echo "  make BUILD_TYPE=BARE_METAL   - Bare metal OS (demo only)"
	@echo "  make BUILD_TYPE=PARASITIC    - Parasitic on Debian/AlmaLinux (production)"
	@echo "  make BUILD_TYPE=CONTAINER    - Container-based"
	@echo ""
	@echo "Example:"
	@echo "  make clean && make BUILD_TYPE=PARASITIC && make run"
	@echo ""
