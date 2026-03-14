// fortune.c - Wisdom database with categories
// build: gcc -O2 -std=c11 -Wall -Wextra -o fortune fortune.c
// usage: fortune [category]

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// Self-encoded wisdom database
static const char *wisdom_tech[] = {
  "The best code is no code at all.",
  "Premature optimization is the root of all evil. - Donald Knuth",
  "Make it work, make it right, make it fast.",
  "Code never lies, comments sometimes do.",
  "Simplicity is the ultimate sophistication.",
  NULL
};

static const char *wisdom_flower[] = {
  "A flower does not think of competing with the flower next to it.",
  "Where flowers bloom, so does hope.",
  "In every walk with nature, one receives far more than he seeks.",
  "The earth laughs in flowers. - Ralph Waldo Emerson",
  "To plant a garden is to believe in tomorrow.",
  NULL
};

static const char *wisdom_zen[] = {
  "The obstacle is the path.",
  "When you reach the top, keep climbing.",
  "Before enlightenment: chop wood, carry water. After: chop wood, carry water.",
  "The quieter you become, the more you can hear.",
  "Empty your cup so that it may be filled.",
  NULL
};

typedef struct {
  const char *name;
  const char **entries;
} category_t;

static category_t categories[] = {
  {"tech", wisdom_tech},
  {"flower", wisdom_flower},
  {"zen", wisdom_zen},
  {NULL, NULL}
};

// Get random entry from category
static const char *get_fortune(const char *category_name) {
  category_t *cat = NULL;
  
  // Find category
  if (category_name) {
    for (int i = 0; categories[i].name; i++) {
      if (strcmp(categories[i].name, category_name) == 0) {
        cat = &categories[i];
        break;
      }
    }
    if (!cat) {
      fprintf(stderr, "fortune: unknown category '%s'\n", category_name);
      return NULL;
    }
  } else {
    // Random category
    srand(time(NULL));
    int ncat = 0;
    while (categories[ncat].name) ncat++;
    cat = &categories[rand() % ncat];
  }
  
  // Count entries
  int count = 0;
  while (cat->entries[count]) count++;
  
  if (count == 0) return NULL;
  
  // Pick random
  srand(time(NULL));
  return cat->entries[rand() % count];
}

int main(int argc, char **argv) {
  const char *category = (argc > 1) ? argv[1] : NULL;
  
  if (argc > 1 && (strcmp(argv[1], "-l") == 0 || strcmp(argv[1], "--list") == 0)) {
    printf("Available categories:\n");
    for (int i = 0; categories[i].name; i++) {
      int count = 0;
      while (categories[i].entries[count]) count++;
      printf("  %-10s (%d entries)\n", categories[i].name, count);
    }
    return 0;
  }
  
  const char *fortune = get_fortune(category);
  if (fortune) {
    printf("%s\n", fortune);
  }
  
  return fortune ? 0 : 1;
}
