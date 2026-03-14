// random.c - pick a random line from .ascii/.txt files in this directory
// build: gcc -O2 -std=c11 -Wall -Wextra -o random random.c

#define _POSIX_C_SOURCE 200809L
#include <dirent.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int has_ext(const char *name, const char *ext) {
  size_t n = strlen(name), e = strlen(ext);
  return (n >= e) && (strcmp(name + (n - e), ext) == 0);
}

static uint32_t urand32(void) {
  FILE *f = fopen("/dev/urandom", "rb");
  if (!f) return 0;
  uint32_t x = 0;
  size_t got = fread(&x, 1, sizeof(x), f);
  fclose(f);
  return (got == sizeof(x)) ? x : 0;
}

static long count_lines(const char *path) {
  FILE *fp = fopen(path, "r");
  if (!fp) return -1;
  long lines = 0;
  int c, saw_any = 0;
  while ((c = fgetc(fp)) != EOF) {
    saw_any = 1;
    if (c == '\n') lines++;
  }
  fclose(fp);
  return saw_any ? lines + 1 : 0;
}

static int print_line(const char *path, long target) {
  FILE *fp = fopen(path, "r");
  if (!fp) return -1;
  
  char *line = NULL;
  size_t cap = 0;
  long cur = 0;
  
  while (getline(&line, &cap, fp) != -1) {
    cur++;
    if (cur == target) {
      fputs(line, stdout);
      free(line);
      fclose(fp);
      return 0;
    }
  }
  
  free(line);
  fclose(fp);
  return -1;
}

int main(int argc, char **argv) {
  const char *dirpath = (argc > 1) ? argv[1] : ".";
  DIR *d = opendir(dirpath);
  if (!d) {
    fprintf(stderr, "random: opendir('%s') failed: %s\n", dirpath, strerror(errno));
    return 1;
  }
  
  // Collect files and count total lines
  struct dirent *ent;
  long total_lines = 0;
  size_t cap = 32, len = 0;
  char **files = calloc(cap, sizeof(char*));
  if (!files) { closedir(d); return 1; }
  
  while ((ent = readdir(d)) != NULL) {
    const char *name = ent->d_name;
    if (name[0] == '.') continue;
    if (!(has_ext(name, ".ascii") || has_ext(name, ".txt"))) continue;
    
    size_t psize = strlen(dirpath) + 1 + strlen(name) + 1;
    char *path = malloc(psize);
    if (!path) continue;
    snprintf(path, psize, "%s/%s", dirpath, name);
    
    long nlines = count_lines(path);
    if (nlines > 0) {
      total_lines += nlines;
      if (len == cap) {
        cap *= 2;
        char **nf = realloc(files, cap * sizeof(char*));
        if (!nf) { free(path); break; }
        files = nf;
      }
      files[len++] = path;
    } else {
      free(path);
    }
  }
  
  closedir(d);
  
  if (len == 0 || total_lines <= 0) {
    fprintf(stderr, "random: no usable .ascii/.txt lines in %s\n", dirpath);
    for (size_t i = 0; i < len; i++) free(files[i]);
    free(files);
    return 1;
  }
  
  uint32_t r = urand32();
  if (r == 0) {
    for (size_t i = 0; i < len; i++) free(files[i]);
    free(files);
    return 2; // fallback to shell
  }
  
  long pick = (long)(r % (uint32_t)total_lines);
  if (pick == 0) {
    for (size_t i = 0; i < len; i++) free(files[i]);
    free(files);
    return 2;
  }
  
  // Find file containing the picked line
  long cumulative = 0;
  for (size_t i = 0; i < len; i++) {
    long nlines = count_lines(files[i]);
    if (nlines <= 0) continue;
    if (pick <= cumulative + nlines) {
      long local = pick - cumulative + 1;
      int rc = print_line(files[i], local);
      for (size_t j = 0; j < len; j++) free(files[j]);
      free(files);
      return (rc == 0) ? 0 : 1;
    }
    cumulative += nlines;
  }
  
  for (size_t i = 0; i < len; i++) free(files[i]);
  free(files);
  return 1;
}
