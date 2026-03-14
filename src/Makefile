# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS — Master Build  (src/Makefile)
#  Builds every C twin alongside its shell counterpart.
#
#  make              Build all binaries
#  make install      Install to PREFIX/bin (default /usr/local)
#  make clean        Remove build artefacts
#  make list         Show shell ↔ C twin mapping
# ═══════════════════════════════════════════════════════════════════════════

CC      = gcc
CFLAGS  = -O2 -std=c11 -Wall -Wextra -pedantic -I.
LDFLAGS =

PREFIX  ?= /usr/local
BINDIR   = $(PREFIX)/bin

# ── Binaries ────────────────────────────────────────────────────────────────
#  Left column = output binary name
#  Right column = source file

BINS = \
	flower-install \
	flower-uninstall \
	flower-postinstall \
	flower-config \
	flower-motd \
	flower-todo \
	flower-guy \
	flower-walk \
	flower-run \
	flower-chess \
	flower-colony \
	flower-td \
	flower-play \
	fp

# ── Sources ──────────────────────────────────────────────────────────────────

flower-install_SRC    = install/install.c
flower-uninstall_SRC  = install/uninstall.c
flower-postinstall_SRC= install/post_install.c
flower-config_SRC     = config/flower_config.c
flower-motd_SRC       = motd/show_motd.c
flower-todo_SRC       = tools/flower_todo.c
flower-guy_SRC        = utils/flower_guy.c
flower-walk_SRC       = utils/flower_walk.c
flower-run_SRC        = runner/fos_runner.c
flower-chess_SRC      = games/chess_engine.c
flower-colony_SRC     = games/colony_engine.c
flower-td_SRC         = games/td_engine.c
flower-play_SRC       = games/play.c
fp_SRC                = publish/fp.c

# ── Rules ────────────────────────────────────────────────────────────────────

.PHONY: all clean install uninstall list

all: $(BINS)

define COMPILE_RULE
$(1): $$($(1)_SRC) floweros.h
	@printf '\033[36m🌱 %-20s\033[0m %s\n' "$(1)" "$$<"
	$(CC) $(CFLAGS) -o $$@ $$< $(LDFLAGS)
	@printf '\033[32m✓ built: %-18s\033[0m (%s)\n' "$(1)" "$$(du -h $$@ | cut -f1)"
endef

$(foreach bin,$(BINS),$(eval $(call COMPILE_RULE,$(bin))))

clean:
	@printf '\033[33m🍂 Cleaning...\033[0m\n'
	rm -f $(BINS)
	@printf '\033[32m✓ clean\033[0m\n'

install: all
	@printf '\033[35m🌸 Installing to $(BINDIR)/\033[0m\n'
	install -d $(BINDIR)
	$(foreach bin,$(BINS),install -m 755 $(bin) $(BINDIR)/$(bin);)
	@printf '\033[32m✓ All binaries installed. Run: flower-install --tutorial\033[0m\n'

uninstall:
	$(foreach bin,$(BINS),rm -f $(BINDIR)/$(bin);)
	@printf '\033[32m✓ Uninstalled\033[0m\n'

# ── Shell ↔ C twin reference ─────────────────────────────────────────────────

list:
	@echo ""
	@printf '  \033[38;5;219m%-25s\033[0m  \033[38;5;117m%-30s\033[0m  %s\n' \
		"Shell script" "C binary" "Purpose"
	@printf '  \033[38;5;245m%.0s─\033[0m' {1..70}; echo ""
	@printf '  \033[38;5;245m%-25s\033[0m  \033[38;5;120m%-30s\033[0m  %s\n' \
		"install.sh"                  "flower-install"      "Installer + dep walker" \
		"uninstall.sh"                "flower-uninstall"    "Clean removal" \
		"lib/post-install.sh"         "flower-postinstall"  "Optional tools tutorial" \
		"floweros-config.sh"          "flower-config"       "Prefs get/set" \
		"motd/show-motd.sh"           "flower-motd"         "Terminal-width MOTD" \
		"tools/flower-todo.sh"        "flower-todo"         "To-do notepad" \
		"lib/flower_ascii.sh"         "flower-guy"          "ASCII character + moods" \
		"experimental/animations/flower_walk_demo.sh" "flower-walk"        "Tier 5 walk animation" \
		"lib/run.sh"                  "flower-run"          "Universal language runner + HPC" \
		"games/chess.sh"              "flower-chess"        "Terminal chess (num/sym/gui)" \
		"games/colony.sh"             "flower-colony"       "Colony survival (hex/cadence)" \
		"games/td.sh"                 "flower-td"           "Tower defense (garden vs bugs)" \
		"games/play.c"                "flower-play"         "Game launcher menu" \
		"src/publish/fp.c"            "fp"                  "LaTeX workflow"
	@echo ""
