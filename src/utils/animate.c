// animate.c - ASCII animation player with self-encoded frames
// build: gcc -O2 -std=c11 -Wall -Wextra -o animate animate.c
// usage: animate <file.anim> [fps] [loop]

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>

#define MAX_FRAME_SIZE 8192
#define MAX_FRAMES 256
#define DEFAULT_FPS 10

// Animation frame structure
typedef struct {
  char *data;
  size_t size;
  int duration_ms;  // per-frame timing
} frame_t;

// Animation container
typedef struct {
  frame_t frames[MAX_FRAMES];
  size_t frame_count;
  int default_fps;
  int loop;
} animation_t;

// Clear screen
static void clear_screen(void) {
  printf("\033[2J\033[H");
  fflush(stdout);
}

// Move cursor home
static void cursor_home(void) {
  printf("\033[H");
  fflush(stdout);
}

// Sleep milliseconds
static void sleep_ms(int ms) {
  struct timespec ts = { ms / 1000, (ms % 1000) * 1000000L };
  nanosleep(&ts, NULL);
}

// Parse .anim file format:
// #FPS=10
// #LOOP=1
// ---FRAME---
// <frame data>
// ---FRAME---
// <frame data>
static int load_animation(const char *path, animation_t *anim) {
  FILE *fp = fopen(path, "r");
  if (!fp) {
    fprintf(stderr, "animate: cannot open '%s'\n", path);
    return -1;
  }
  
  anim->frame_count = 0;
  anim->default_fps = DEFAULT_FPS;
  anim->loop = 0;
  
  char *line = NULL;
  size_t cap = 0;
  ssize_t len;
  
  char frame_buf[MAX_FRAME_SIZE];
  size_t frame_len = 0;
  int in_frame = 0;
  
  while ((len = getline(&line, &cap, fp)) != -1) {
    // Parse directives
    if (strncmp(line, "#FPS=", 5) == 0) {
      anim->default_fps = atoi(line + 5);
      continue;
    }
    if (strncmp(line, "#LOOP=", 6) == 0) {
      anim->loop = atoi(line + 6);
      continue;
    }
    
    // Frame delimiter
    if (strncmp(line, "---FRAME---", 11) == 0) {
      if (in_frame && frame_len > 0) {
        // Save previous frame
        if (anim->frame_count < MAX_FRAMES) {
          frame_t *f = &anim->frames[anim->frame_count++];
          f->data = malloc(frame_len + 1);
          if (f->data) {
            memcpy(f->data, frame_buf, frame_len);
            f->data[frame_len] = '\0';
            f->size = frame_len;
            f->duration_ms = 1000 / anim->default_fps;
          }
        }
        frame_len = 0;
      }
      in_frame = 1;
      continue;
    }
    
    // Accumulate frame data
    if (in_frame && frame_len + len < MAX_FRAME_SIZE) {
      memcpy(frame_buf + frame_len, line, len);
      frame_len += len;
    }
  }
  
  // Save last frame
  if (in_frame && frame_len > 0 && anim->frame_count < MAX_FRAMES) {
    frame_t *f = &anim->frames[anim->frame_count++];
    f->data = malloc(frame_len + 1);
    if (f->data) {
      memcpy(f->data, frame_buf, frame_len);
      f->data[frame_len] = '\0';
      f->size = frame_len;
      f->duration_ms = 1000 / anim->default_fps;
    }
  }
  
  free(line);
  fclose(fp);
  
  return anim->frame_count > 0 ? 0 : -1;
}

// Play animation
static void play_animation(animation_t *anim) {
  if (anim->frame_count == 0) return;
  
  clear_screen();
  
  do {
    for (size_t i = 0; i < anim->frame_count; i++) {
      cursor_home();
      fputs(anim->frames[i].data, stdout);
      fflush(stdout);
      sleep_ms(anim->frames[i].duration_ms);
    }
  } while (anim->loop);
}

// Free animation
static void free_animation(animation_t *anim) {
  for (size_t i = 0; i < anim->frame_count; i++) {
    free(anim->frames[i].data);
  }
}

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "usage: animate <file.anim> [fps] [loop]\n");
    fprintf(stderr, "  fps:  frames per second (default: 10)\n");
    fprintf(stderr, "  loop: 0=once, 1=forever (default: file setting)\n");
    return 1;
  }
  
  animation_t anim;
  if (load_animation(argv[1], &anim) != 0) {
    return 1;
  }
  
  // Override FPS from command line
  if (argc >= 3) {
    int fps = atoi(argv[2]);
    if (fps > 0) {
      for (size_t i = 0; i < anim.frame_count; i++) {
        anim.frames[i].duration_ms = 1000 / fps;
      }
    }
  }
  
  // Override loop from command line
  if (argc >= 4) {
    anim.loop = atoi(argv[3]);
  }
  
  printf("\033[?25l"); // Hide cursor
  play_animation(&anim);
  printf("\033[?25h"); // Show cursor
  
  free_animation(&anim);
  return 0;
}
