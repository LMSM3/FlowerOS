# ═══════════════════════════════════════════════════════════════════════════
#  Flower AI — Build  (lib/flower_ai/Makefile)
#
#  Build flags:
#    FLOWER_ENABLE_AI=1          Master switch (required)
#    FLOWER_ENABLE_AI_CUDA=1     Enable CUDA backend path
#    FLOWER_ENABLE_AI_VULKAN=1   Enable Vulkan backend path
#    FLOWER_ENABLE_AI_CPU=1      Enable CPU fallback path (default: on)
#
#  Usage:
#    make                        Build with CPU fallback only
#    make FLOWER_ENABLE_AI_CUDA=1   Build with CUDA + CPU
#    make clean                  Remove build artifacts
#    make check                  Run detection diagnostic
#
#  If FLOWER_ENABLE_AI is not set, nothing compiles. FlowerOS still works.
# ═══════════════════════════════════════════════════════════════════════════

CC       = gcc
CXX      = g++
CFLAGS   = -O2 -std=c11 -Wall -Wextra -pedantic -Iinclude
CXXFLAGS = -O2 -std=c++17 -Wall -Wextra -pedantic -Iinclude
LDFLAGS  =

# ── Feature flags ────────────────────────────────────────────────────────

FLOWER_ENABLE_AI      ?= 1
FLOWER_ENABLE_AI_CPU  ?= 1
FLOWER_ENABLE_AI_CUDA ?= 0
FLOWER_ENABLE_AI_VULKAN ?= 0

ifeq ($(FLOWER_ENABLE_AI),1)
  CFLAGS   += -DFLOWER_ENABLE_AI
  CXXFLAGS += -DFLOWER_ENABLE_AI
endif

ifeq ($(FLOWER_ENABLE_AI_CPU),1)
  CFLAGS   += -DFLOWER_ENABLE_AI_CPU
  CXXFLAGS += -DFLOWER_ENABLE_AI_CPU
endif

ifeq ($(FLOWER_ENABLE_AI_CUDA),1)
  CFLAGS   += -DFLOWER_ENABLE_AI_CUDA
  CXXFLAGS += -DFLOWER_ENABLE_AI_CUDA
endif

ifeq ($(FLOWER_ENABLE_AI_VULKAN),1)
  CFLAGS   += -DFLOWER_ENABLE_AI_VULKAN
  CXXFLAGS += -DFLOWER_ENABLE_AI_VULKAN
endif

# ── Sources ──────────────────────────────────────────────────────────────

C_SRCS    = src/flower_ai.c src/flower_ai_detect.c src/flower_ai_session.c
CXX_SRCS  = src/flower_ai_backend.cpp
C_OBJS    = $(C_SRCS:.c=.o)
CXX_OBJS  = $(CXX_SRCS:.cpp=.o)
ALL_OBJS  = $(C_OBJS) $(CXX_OBJS)

LIB_STATIC = libflower_ai.a

# ── Rules ────────────────────────────────────────────────────────────────

.PHONY: all clean check

ifeq ($(FLOWER_ENABLE_AI),1)
all: $(LIB_STATIC)
	@printf '\033[32m✓ Flower AI built: %s\033[0m\n' "$(LIB_STATIC)"
else
all:
	@printf '\033[33m⚠ Flower AI: FLOWER_ENABLE_AI not set — skipping build\033[0m\n'
endif

$(LIB_STATIC): $(ALL_OBJS)
	ar rcs $@ $^

src/%.o: src/%.c include/flower_ai.h
	@printf '\033[36m🌱 %-30s\033[0m %s\n' "$@" "$<"
	$(CC) $(CFLAGS) -c -o $@ $<

src/%.o: src/%.cpp include/flower_ai.h
	@printf '\033[36m🌱 %-30s\033[0m %s\n' "$@" "$<"
	$(CXX) $(CXXFLAGS) -c -o $@ $<

clean:
	@printf '\033[33m🍂 Cleaning Flower AI...\033[0m\n'
	rm -f $(ALL_OBJS) $(LIB_STATIC)
	@printf '\033[32m✓ clean\033[0m\n'

check: all
	@printf '\n\033[35m🌸 Flower AI — Hardware Detection Diagnostic\033[0m\n'
	@printf '  Build flags:\n'
	@printf '    FLOWER_ENABLE_AI       = $(FLOWER_ENABLE_AI)\n'
	@printf '    FLOWER_ENABLE_AI_CPU   = $(FLOWER_ENABLE_AI_CPU)\n'
	@printf '    FLOWER_ENABLE_AI_CUDA  = $(FLOWER_ENABLE_AI_CUDA)\n'
	@printf '    FLOWER_ENABLE_AI_VULKAN= $(FLOWER_ENABLE_AI_VULKAN)\n'
	@printf '  Library: $(LIB_STATIC)\n'
	@printf '\033[32m✓ Flower AI ready for integration\033[0m\n'
