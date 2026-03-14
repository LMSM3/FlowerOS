// banner.c - Dynamic ASCII banner generator with effects
// build: gcc -O2 -std=c11 -Wall -Wextra -o banner banner.c
// usage: banner [OPTIONS] "Text"

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

// Big letter patterns (5x5 blocks)
static const char *letters[][5] = {
  // A
  {" ███ ", "█   █", "█████", "█   █", "█   █"},
  // B
  {"████ ", "█   █", "████ ", "█   █", "████ "},
  // C
  {" ████", "█    ", "█    ", "█    ", " ████"},
  // D
  {"████ ", "█   █", "█   █", "█   █", "████ "},
  // E
  {"█████", "█    ", "████ ", "█    ", "█████"},
  // F
  {"█████", "█    ", "████ ", "█    ", "█    "},
  // ... truncated for brevity (add full alphabet)
};

// Flower patterns for decoration
static const char *flowers[] = {
  "✿", "❀", "❁", "✾", "⚘", "❊", "✽", "✻"
};

// Color codes
typedef enum {
  COLOR_RESET = 0,
  COLOR_RED = 31,
  COLOR_GREEN = 32,
  COLOR_YELLOW = 33,
  COLOR_BLUE = 34,
  COLOR_MAGENTA = 35,
  COLOR_CYAN = 36
} color_t;

static void print_color(color_t c, const char *str) {
  if (c != COLOR_RESET) {
    printf("\033[%dm%s\033[0m", c, str);
  } else {
    printf("%s", str);
  }
}

// Simple banner (horizontal text with borders)
static void banner_simple(const char *text, color_t color) {
  size_t len = strlen(text);
  size_t width = len + 6;
  
  // Top border
  print_color(color, "✿");
  for (size_t i = 0; i < width; i++) putchar('━');
  print_color(color, "✿");
  putchar('\n');
  
  // Text line
  print_color(color, "✿");
  printf("   %s   ", text);
  print_color(color, "✿");
  putchar('\n');
  
  // Bottom border
  print_color(color, "✿");
  for (size_t i = 0; i < width; i++) putchar('━');
  print_color(color, "✿");
  putchar('\n');
}

// Flower border
static void banner_flower(const char *text, color_t color) {
  size_t len = strlen(text);
  
  // Top flowers
  print_color(COLOR_MAGENTA, "✿ ");
  print_color(COLOR_CYAN, "❀ ");
  print_color(COLOR_GREEN, "✾ ");
  putchar('\n');
  
  // Text
  print_color(color, text);
  putchar('\n');
  
  // Bottom flowers
  print_color(COLOR_GREEN, "✾ ");
  print_color(COLOR_CYAN, "❀ ");
  print_color(COLOR_MAGENTA, "✿ ");
  putchar('\n');
}

// Gradient effect
static void banner_gradient(const char *text) {
  color_t colors[] = {COLOR_RED, COLOR_YELLOW, COLOR_GREEN, COLOR_CYAN, COLOR_BLUE, COLOR_MAGENTA};
  size_t ncolors = sizeof(colors) / sizeof(colors[0]);
  
  for (size_t i = 0; text[i]; i++) {
    char buf[2] = {text[i], '\0'};
    print_color(colors[i % ncolors], buf);
  }
  putchar('\n');
}

// Box with random flower corners
static void banner_box(const char *text, color_t color) {
  size_t len = strlen(text);
  srand(time(NULL));
  
  const char *tl = flowers[rand() % 8];
  const char *tr = flowers[rand() % 8];
  const char *bl = flowers[rand() % 8];
  const char *br = flowers[rand() % 8];
  
  // Top
  printf("%s", tl);
  for (size_t i = 0; i < len + 2; i++) printf("─");
  printf("%s\n", tr);
  
  // Middle
  printf("│ ");
  print_color(color, text);
  printf(" │\n");
  
  // Bottom
  printf("%s", bl);
  for (size_t i = 0; i < len + 2; i++) printf("─");
  printf("%s\n", br);
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: banner [OPTIONS] \"Text\"\n");
    fprintf(stderr, "options:\n");
    fprintf(stderr, "  -s, --simple    Simple border (default)\n");
    fprintf(stderr, "  -f, --flower    Flower decorations\n");
    fprintf(stderr, "  -g, --gradient  Rainbow gradient\n");
    fprintf(stderr, "  -b, --box       Box with flower corners\n");
    fprintf(stderr, "  -c, --color N   Color (31-36)\n");
    return 1;
  }
  
  // Parse options
  int style = 0; // 0=simple, 1=flower, 2=gradient, 3=box
  color_t color = COLOR_CYAN;
  const char *text = NULL;
  
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "-s") == 0 || strcmp(argv[i], "--simple") == 0) {
      style = 0;
    } else if (strcmp(argv[i], "-f") == 0 || strcmp(argv[i], "--flower") == 0) {
      style = 1;
    } else if (strcmp(argv[i], "-g") == 0 || strcmp(argv[i], "--gradient") == 0) {
      style = 2;
    } else if (strcmp(argv[i], "-b") == 0 || strcmp(argv[i], "--box") == 0) {
      style = 3;
    } else if ((strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "--color") == 0) && i + 1 < argc) {
      color = (color_t)atoi(argv[++i]);
    } else if (!text) {
      text = argv[i];
    }
  }
  
  if (!text) {
    fprintf(stderr, "banner: no text provided\n");
    return 1;
  }
  
  switch (style) {
    case 0: banner_simple(text, color); break;
    case 1: banner_flower(text, color); break;
    case 2: banner_gradient(text); break;
    case 3: banner_box(text, color); break;
  }
  
  return 0;
}
