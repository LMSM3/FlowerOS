// colortest.c - Terminal color and capability diagnostics
// build: gcc -O2 -std=c11 -Wall -Wextra -o colortest colortest.c
// usage: colortest

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// Safe getenv wrapper
static const char* safe_getenv(const char* var) {
    const char* value = getenv(var);
    return value ? value : "not set";
}

static void test_colors(void) {
    printf("\n=== Basic Colors ===\n");
    for (int i = 30; i <= 37; i++) {
        printf("\033[%dm Color %d \033[0m ", i, i);
    }
    printf("\n");
    
    printf("\n=== Bright Colors ===\n");
    for (int i = 90; i <= 97; i++) {
        printf("\033[%dm Color %d \033[0m ", i, i);
    }
    printf("\n");
    
    printf("\n=== Background Colors ===\n");
    for (int i = 40; i <= 47; i++) {
        printf("\033[%dm BG %d \033[0m ", i, i);
    }
    printf("\n");
}

static void test_256_colors(void) {
    printf("\n=== 256 Color Palette ===\n");
    for (int i = 0; i < 256; i++) {
        printf("\033[48;5;%dm %3d \033[0m", i, i);
        if ((i + 1) % 16 == 0) printf("\n");
    }
    printf("\n");
}

static void test_unicode(void) {
    printf("\n=== Unicode Flowers ===\n");
    const char *flowers[] = {
        "✿", "❀", "❁", "✾", "⚘", "❊", "✽", "✻",
        "🌸", "🌺", "🌻", "🌼", "🌷", "🌹"
    };
    
    size_t flower_count = sizeof(flowers) / sizeof(flowers[0]);
    for (size_t i = 0; i < flower_count; i++) {
        printf("%s ", flowers[i]);
    }
    printf("\n");
}

static void test_box_drawing(void) {
    printf("\n=== Box Drawing ===\n");
    printf("┌─────────┐\n");
    printf("│ FlowerOS│\n");
    printf("└─────────┘\n");
    printf("\n");
    printf("╔═════════╗\n");
    printf("║ FlowerOS║\n");
    printf("╚═════════╝\n");
}

static void test_terminal_info(void) {
    printf("\n=== Terminal Info ===\n");
    printf("TERM: %s\n", safe_getenv("TERM"));
    printf("COLORTERM: %s\n", safe_getenv("COLORTERM"));
    printf("TTY: %s\n", isatty(STDOUT_FILENO) ? "yes" : "no");
    
    // Try to get terminal size (with error handling)
    FILE *tput_lines = popen("tput lines 2>/dev/null", "r");
    FILE *tput_cols = popen("tput cols 2>/dev/null", "r");
    
    if (tput_lines && tput_cols) {
        int lines = 0, cols = 0;
        int lines_read = fscanf(tput_lines, "%d", &lines);
        int cols_read = fscanf(tput_cols, "%d", &cols);
        
        if (lines_read == 1 && cols_read == 1 && lines > 0 && cols > 0) {
            printf("Size: %dx%d\n", cols, lines);
        } else {
            printf("Size: unable to detect\n");
        }
        
        pclose(tput_lines);
        pclose(tput_cols);
    } else {
        if (tput_lines) pclose(tput_lines);
        if (tput_cols) pclose(tput_cols);
        printf("Size: tput not available\n");
    }
}

int main(void) {
    printf("\033[36m✿ FlowerOS Terminal Diagnostics\033[0m\n");
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    
    test_terminal_info();
    test_colors();
    test_unicode();
    test_box_drawing();
    test_256_colors();
    
    printf("\n\033[32m✓ Test complete!\033[0m\n\n");
    return EXIT_SUCCESS;
}
