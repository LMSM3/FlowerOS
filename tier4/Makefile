# FlowerOS Tier 4 — Build
#
# Build: cl /O2 broker.c /link advapi32.lib crypt32.lib
#    or: gcc -O2 -o broker.exe broker.c -ladvapi32 -lcrypt32

CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c11 -DBROKER_STANDALONE
LDFLAGS = -ladvapi32 -lcrypt32

SRCDIR = ../src/tier4

all: broker.exe

broker.exe: $(SRCDIR)/broker.c broker.h
	$(CC) $(CFLAGS) -o $@ $(SRCDIR)/broker.c $(LDFLAGS)

clean:
	del /Q broker.exe 2>nul || rm -f broker.exe

.PHONY: all clean
