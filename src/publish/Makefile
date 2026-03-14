# ═══════════════════════════════════════════════════════════════════════════
#  FlowerPublish (FP) — Build
#  gcc on Debian/WSL; outputs `fp` binary
# ═══════════════════════════════════════════════════════════════════════════

CC      = gcc
CFLAGS  = -O2 -std=c11 -Wall -Wextra -pedantic
LDFLAGS =

SRC     = fp.c
HDR     = fp.h
BIN     = fp

PREFIX  ?= /usr/local

.PHONY: all clean install uninstall help

all: $(BIN)

$(BIN): $(SRC) $(HDR)
	@echo "\033[36m🌱 Compiling FlowerPublish...\033[0m"
	$(CC) $(CFLAGS) -o $@ $(SRC) $(LDFLAGS)
	@echo "\033[32m✓ Built: $(BIN)  ($$(du -h $(BIN) | cut -f1))\033[0m"

clean:
	@echo "\033[33m🍂 Cleaning...\033[0m"
	rm -f $(BIN)
	@echo "\033[32m✓ Clean\033[0m"

install: $(BIN)
	@echo "\033[35m🌸 Installing to $(PREFIX)/bin/fp\033[0m"
	install -Dm755 $(BIN) $(PREFIX)/bin/fp
	@echo "\033[32m✓ Installed. Run: fp help\033[0m"

uninstall:
	rm -f $(PREFIX)/bin/fp
	@echo "\033[32m✓ Removed $(PREFIX)/bin/fp\033[0m"

help:
	@echo ""
	@echo "  FlowerPublish build targets:"
	@echo "    make          Build fp binary"
	@echo "    make install  Install to $(PREFIX)/bin/"
	@echo "    make clean    Remove build artifacts"
	@echo ""
