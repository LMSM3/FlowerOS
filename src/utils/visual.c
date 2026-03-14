// visual.c - FlowerOS Visual Output System
// Real-time visualization after batch calculations
// build: gcc -O2 -std=c11 -Wall -Wextra -o visual visual.c

#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

// ANSI color codes
#define RESET   "\033[0m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN    "\033[36m"
#define WHITE   "\033[37m"
#define BOLD    "\033[1m"

// Visual output modes
typedef enum {
  MODE_BAR_CHART,
  MODE_LINE_GRAPH,
  MODE_TABLE,
  MODE_TREE,
  MODE_PROGRESS,
  MODE_SPARKLINE
} visual_mode_t;

// Data point structure
typedef struct {
  char label[64];
  double value;
  char unit[16];
} data_point_t;

// Clear screen and move cursor home
static void clear_screen(void) {
  printf("\033[2J\033[H");
  fflush(stdout);
}

// Move cursor to position
static void move_cursor(int row, int col) {
  printf("\033[%d;%dH", row, col);
}

// Draw horizontal bar chart
static void draw_bar_chart(data_point_t *data, size_t count, const char *title) {
  if (count == 0) return;
  
  // Find max value for scaling
  double max_val = 0;
  for (size_t i = 0; i < count; i++) {
    if (data[i].value > max_val) max_val = data[i].value;
  }
  
  const int bar_width = 50;
  
  printf("\n%s%s%s\n", BOLD, title, RESET);
  printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n", CYAN, RESET);
  
  for (size_t i = 0; i < count; i++) {
    int bar_len = (int)((data[i].value / max_val) * bar_width);
    
    // Print label
    printf("%-20s ", data[i].label);
    
    // Print bar
    printf("%s", GREEN);
    for (int j = 0; j < bar_len; j++) {
      printf("█");
    }
    printf("%s", RESET);
    
    // Print value
    printf(" %.2f%s\n", data[i].value, data[i].unit);
  }
  
  printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n", CYAN, RESET);
}

// Draw ASCII table
static void draw_table(data_point_t *data, size_t count, const char *title) {
  if (count == 0) return;
  
  printf("\n%s%s%s\n", BOLD, title, RESET);
  printf("%s┌────────────────────┬────────────────┬──────────┐%s\n", CYAN, RESET);
  printf("%s│ %-18s │ %-14s │ %-8s │%s\n", CYAN, "Label", "Value", "Unit", RESET);
  printf("%s├────────────────────┼────────────────┼──────────┤%s\n", CYAN, RESET);
  
  for (size_t i = 0; i < count; i++) {
    printf("%s│%s %-18s %s│%s %14.2f %s│%s %-8s %s│%s\n",
      CYAN, RESET, data[i].label,
      CYAN, RESET, data[i].value,
      CYAN, RESET, data[i].unit,
      CYAN, RESET
    );
  }
  
  printf("%s└────────────────────┴────────────────┴──────────┘%s\n\n", CYAN, RESET);
}

// Draw sparkline (inline mini-graph)
static void draw_sparkline(double *values, size_t count) {
  if (count == 0) return;
  
  // Find min/max
  double min_val = values[0], max_val = values[0];
  for (size_t i = 1; i < count; i++) {
    if (values[i] < min_val) min_val = values[i];
    if (values[i] > max_val) max_val = values[i];
  }
  
  // Unicode sparkline characters
  const char *sparks[] = {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"};
  const int levels = 8;
  
  printf("%s", CYAN);
  for (size_t i = 0; i < count; i++) {
    double normalized = (values[i] - min_val) / (max_val - min_val);
    int level = (int)(normalized * (levels - 1));
    printf("%s", sparks[level]);
  }
  printf("%s", RESET);
}

// Draw progress bar with percentage
static void draw_progress(const char *label, double current, double total) {
  int width = 40;
  double percentage = (current / total) * 100.0;
  int filled = (int)((current / total) * width);
  
  printf("%s%-20s%s [", BOLD, label, RESET);
  
  // Choose color based on progress
  if (percentage < 33.0) {
    printf("%s", RED);
  } else if (percentage < 66.0) {
    printf("%s", YELLOW);
  } else {
    printf("%s", GREEN);
  }
  
  for (int i = 0; i < width; i++) {
    if (i < filled) {
      printf("█");
    } else {
      printf("░");
    }
  }
  
  printf("%s] %5.1f%%\n", RESET, percentage);
}

// Draw tree structure
static void draw_tree(const char **items, size_t count, const char *root) {
  printf("\n%s%s%s\n", BOLD, root, RESET);
  
  for (size_t i = 0; i < count; i++) {
    if (i == count - 1) {
      printf("%s└── %s%s\n", CYAN, RESET, items[i]);
    } else {
      printf("%s├── %s%s\n", CYAN, RESET, items[i]);
    }
  }
  printf("\n");
}

// Animated progress display
static void animate_progress(const char *task, int duration_ms) {
  const char *spinner[] = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"};
  const int frames = 10;
  
  int iterations = duration_ms / 100;
  
  for (int i = 0; i < iterations; i++) {
    printf("\r%s%s%s %s", CYAN, spinner[i % frames], RESET, task);
    fflush(stdout);
    usleep(100000); // 100ms
  }
  
  printf("\r%s✓%s %s\n", GREEN, RESET, task);
}

// Real-time live dashboard (updates in place)
static void live_dashboard(data_point_t *data, size_t count, int updates) {
  for (int i = 0; i < updates; i++) {
    clear_screen();
    
    printf("%s%s═══ FlowerOS Live Dashboard ═══%s\n", BOLD, MAGENTA, RESET);
    printf("Update #%d | Time: %s\n\n", i + 1, __TIME__);
    
    draw_bar_chart(data, count, "System Metrics");
    
    printf("%sPress Ctrl+C to stop%s\n", YELLOW, RESET);
    
    sleep(1);
    
    // Simulate changing data
    for (size_t j = 0; j < count; j++) {
      data[j].value += (rand() % 10 - 5) * 0.1;
      if (data[j].value < 0) data[j].value = 0;
    }
  }
}

// Main visual output dispatcher
int main(int argc, char **argv) {
  srand(time(NULL));
  
  if (argc < 2) {
    fprintf(stderr, "FlowerOS Visual Output System\n\n");
    fprintf(stderr, "Usage: %s <mode> [options]\n\n", argv[0]);
    fprintf(stderr, "Modes:\n");
    fprintf(stderr, "  bar     - Horizontal bar chart\n");
    fprintf(stderr, "  table   - ASCII table\n");
    fprintf(stderr, "  tree    - Tree structure\n");
    fprintf(stderr, "  progress - Progress bars\n");
    fprintf(stderr, "  sparkline - Inline mini-graph\n");
    fprintf(stderr, "  live    - Live updating dashboard\n");
    fprintf(stderr, "  demo    - Show all modes\n");
    return 1;
  }
  
  const char *mode = argv[1];
  
  // Demo mode - show all visualizations
  if (strcmp(mode, "demo") == 0) {
    printf("%s%s\n", BOLD, "FlowerOS Visual Output Demo");
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n\n", RESET);
    
    // Sample data
    data_point_t metrics[] = {
      {"CPU Usage", 65.5, "%"},
      {"Memory", 4.2, "GB"},
      {"Disk I/O", 128.7, "MB/s"},
      {"Network", 45.3, "Mbps"},
      {"Uptime", 72.5, "hrs"}
    };
    size_t count = sizeof(metrics) / sizeof(metrics[0]);
    
    // Bar chart
    draw_bar_chart(metrics, count, "System Metrics - Bar Chart");
    sleep(2);
    
    // Table
    draw_table(metrics, count, "System Metrics - Table View");
    sleep(2);
    
    // Tree structure
    const char *files[] = {
      "FlowerOS/",
      "  ├── random.c",
      "  ├── animate.c",
      "  ├── banner.c",
      "  ├── fortune.c",
      "  └── visual.c"
    };
    draw_tree(files, 5, "FlowerOS Structure");
    sleep(2);
    
    // Progress bars
    printf("\n%sProgress Indicators%s\n", BOLD, RESET);
    printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n", CYAN, RESET);
    draw_progress("Building", 75, 100);
    draw_progress("Testing", 45, 100);
    draw_progress("Installing", 90, 100);
    printf("\n");
    sleep(2);
    
    // Sparklines
    printf("\n%sSparklines (Historical Data)%s\n", BOLD, RESET);
    printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n", CYAN, RESET);
    double cpu_history[] = {45, 50, 48, 52, 55, 60, 58, 62, 65, 68, 70, 65};
    printf("CPU:    ");
    draw_sparkline(cpu_history, 12);
    printf(" (last 12 hours)\n");
    
    double mem_history[] = {3.2, 3.4, 3.6, 3.8, 4.0, 4.1, 4.2, 4.0, 3.9, 4.1, 4.2, 4.3};
    printf("Memory: ");
    draw_sparkline(mem_history, 12);
    printf(" (last 12 hours)\n\n");
    
    // Animated progress
    printf("\n%sAnimated Progress%s\n", BOLD, RESET);
    printf("%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n", CYAN, RESET);
    animate_progress("Compiling random.c", 1000);
    animate_progress("Compiling animate.c", 800);
    animate_progress("Compiling visual.c", 1200);
    printf("\n");
    
    printf("%s%sDemo complete!%s\n", BOLD, GREEN, RESET);
    return 0;
  }
  
  // Bar chart mode
  if (strcmp(mode, "bar") == 0) {
    data_point_t data[] = {
      {"Test 1", 85.5, "%"},
      {"Test 2", 92.3, "%"},
      {"Test 3", 78.1, "%"},
      {"Test 4", 95.7, "%"}
    };
    draw_bar_chart(data, 4, "Test Results");
    return 0;
  }
  
  // Table mode
  if (strcmp(mode, "table") == 0) {
    data_point_t data[] = {
      {"random.c", 2.4, "KB"},
      {"animate.c", 3.1, "KB"},
      {"banner.c", 2.8, "KB"},
      {"visual.c", 4.5, "KB"}
    };
    draw_table(data, 4, "Source Files");
    return 0;
  }
  
  // Live dashboard mode
  if (strcmp(mode, "live") == 0) {
    data_point_t data[] = {
      {"CPU", 50.0, "%"},
      {"Memory", 3.5, "GB"},
      {"Disk", 100.0, "MB/s"}
    };
    live_dashboard(data, 3, 30); // 30 updates
    return 0;
  }
  
  fprintf(stderr, "Unknown mode: %s\n", mode);
  return 1;
}
