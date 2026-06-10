/* png2term.c — FlowerOS PNG-to-terminal colour block renderer
 *
 * Reads a PNG image and emits xterm-256 half-block (▀) ANSI art to stdout.
 * Zero external dependencies beyond the C standard library: the PNG decoder
 * is a minimal, self-contained implementation that handles the subset of PNG
 * required for MOTD art (8-bit RGB/RGBA, non-interlaced).
 *
 * Build:
 *   gcc -O2 -std=c11 -Wall -Wextra -o png2term src/utils/png2term.c -lm -lz
 *
 * Usage:
 *   ./png2term <image.png> [cols] [pastel]
 *     cols   — output width in columns (default: 60, for MOTD sidebar)
 *     pastel — pastel strength 0.0–1.0 (default: 0.55)
 *
 * MOTD integration:
 *   ./png2term logo.png 34 0.50 > ascii/logo-motd.txt
 *   (The MOTD system expects _GUTTER=34 columns for the art sidebar.)
 *
 * Output is xterm-256 colour escape sequences with half-block characters,
 * identical in format to the pre-rendered .ascii files in motd/ascii-output/.
 */

#define _POSIX_C_SOURCE 200809L
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ═══════════════════════════════════════════════════════════════════════════
 *  Minimal PNG decoder (RGB/RGBA, non-interlaced, 8-bit)
 *  Uses zlib for DEFLATE; everything else is handled inline.
 * ═══════════════════════════════════════════════════════════════════════════ */

#include <zlib.h>

typedef struct {
    uint32_t width;
    uint32_t height;
    uint8_t *pixels;   /* RGB, 3 bytes per pixel, row-major */
} image_t;

static uint32_t read_be32(const uint8_t *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8)  | (uint32_t)p[3];
}

static int paeth_predictor(int a, int b, int c) {
    int p  = a + b - c;
    int pa = abs(p - a);
    int pb = abs(p - b);
    int pc = abs(p - c);
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc)             return b;
    return c;
}

static void png_unfilter(uint8_t *row, const uint8_t *prev,
                         uint32_t bpp, uint32_t stride, uint8_t filter) {
    switch (filter) {
    case 0: /* None */
        break;
    case 1: /* Sub */
        for (uint32_t i = bpp; i < stride; i++)
            row[i] = (uint8_t)(row[i] + row[i - bpp]);
        break;
    case 2: /* Up */
        for (uint32_t i = 0; i < stride; i++)
            row[i] = (uint8_t)(row[i] + prev[i]);
        break;
    case 3: /* Average */
        for (uint32_t i = 0; i < stride; i++) {
            uint8_t a = (i >= bpp) ? row[i - bpp] : 0;
            row[i] = (uint8_t)(row[i] + ((a + prev[i]) >> 1));
        }
        break;
    case 4: /* Paeth */
        for (uint32_t i = 0; i < stride; i++) {
            uint8_t a = (i >= bpp) ? row[i - bpp] : 0;
            uint8_t b = prev[i];
            uint8_t c = (i >= bpp) ? prev[i - bpp] : 0;
            row[i] = (uint8_t)(row[i] + paeth_predictor(a, b, c));
        }
        break;
    }
}

static image_t *png_load(const char *path) {
    FILE *fp = fopen(path, "rb");
    if (!fp) { fprintf(stderr, "png2term: cannot open '%s'\n", path); return NULL; }

    /* Check PNG signature */
    uint8_t sig[8];
    if (fread(sig, 1, 8, fp) != 8) { fclose(fp); return NULL; }
    const uint8_t expected[8] = {137,80,78,71,13,10,26,10};
    if (memcmp(sig, expected, 8) != 0) {
        fprintf(stderr, "png2term: not a PNG file\n");
        fclose(fp);
        return NULL;
    }

    uint32_t width = 0, height = 0;
    uint8_t  bit_depth = 0, color_type = 0;
    int      has_ihdr = 0;

    /* Collect all IDAT chunks */
    uint8_t *idat_buf = NULL;
    size_t   idat_len = 0, idat_cap = 0;

    for (;;) {
        uint8_t chunk_hdr[8];
        if (fread(chunk_hdr, 1, 8, fp) != 8) break;
        uint32_t clen = read_be32(chunk_hdr);
        char type[5] = {0};
        memcpy(type, chunk_hdr + 4, 4);

        if (strcmp(type, "IHDR") == 0) {
            uint8_t ihdr[13];
            if (fread(ihdr, 1, 13, fp) != 13) { fclose(fp); return NULL; }
            width      = read_be32(ihdr);
            height     = read_be32(ihdr + 4);
            bit_depth  = ihdr[8];
            color_type = ihdr[9];
            /* ihdr[10] = compression, ihdr[11] = filter, ihdr[12] = interlace */
            if (ihdr[12] != 0) {
                fprintf(stderr, "png2term: interlaced PNGs not supported\n");
                fclose(fp);
                return NULL;
            }
            if (bit_depth != 8) {
                fprintf(stderr, "png2term: only 8-bit depth supported (got %d)\n", bit_depth);
                fclose(fp);
                return NULL;
            }
            if (color_type != 2 && color_type != 6) {
                fprintf(stderr, "png2term: only RGB (2) and RGBA (6) supported (got %d)\n", color_type);
                fclose(fp);
                return NULL;
            }
            has_ihdr = 1;
            fseek(fp, 4, SEEK_CUR); /* skip CRC */
            continue;
        }

        if (strcmp(type, "IDAT") == 0) {
            if (idat_len + clen > idat_cap) {
                idat_cap = (idat_len + clen) * 2;
                idat_buf = realloc(idat_buf, idat_cap);
                if (!idat_buf) { fclose(fp); return NULL; }
            }
            if (fread(idat_buf + idat_len, 1, clen, fp) != clen) {
                free(idat_buf); fclose(fp); return NULL;
            }
            idat_len += clen;
            fseek(fp, 4, SEEK_CUR); /* skip CRC */
            continue;
        }

        if (strcmp(type, "IEND") == 0) break;

        /* Skip unknown chunks */
        fseek(fp, (long)clen + 4, SEEK_CUR);
    }
    fclose(fp);

    if (!has_ihdr || !idat_buf || width == 0 || height == 0) {
        free(idat_buf);
        fprintf(stderr, "png2term: incomplete PNG\n");
        return NULL;
    }

    /* Decompress IDAT */
    uint32_t bpp    = (color_type == 6) ? 4 : 3;
    uint32_t stride = width * bpp;
    size_t   raw_sz = (size_t)height * (stride + 1); /* +1 per row for filter byte */

    uint8_t *raw = malloc(raw_sz);
    if (!raw) { free(idat_buf); return NULL; }

    z_stream zs = {0};
    zs.next_in  = idat_buf;
    zs.avail_in = (uInt)idat_len;
    zs.next_out = raw;
    zs.avail_out = (uInt)raw_sz;

    if (inflateInit(&zs) != Z_OK) {
        free(raw); free(idat_buf); return NULL;
    }
    int zret = inflate(&zs, Z_FINISH);
    inflateEnd(&zs);
    free(idat_buf);

    if (zret != Z_STREAM_END) {
        fprintf(stderr, "png2term: zlib decompression failed (%d)\n", zret);
        free(raw);
        return NULL;
    }

    /* Unfilter and extract RGB */
    image_t *img = malloc(sizeof(image_t));
    if (!img) { free(raw); return NULL; }
    img->width  = width;
    img->height = height;
    img->pixels = malloc((size_t)width * height * 3);
    if (!img->pixels) { free(img); free(raw); return NULL; }

    uint8_t *prev_row = calloc(stride, 1);
    if (!prev_row) { free(img->pixels); free(img); free(raw); return NULL; }

    for (uint32_t y = 0; y < height; y++) {
        uint8_t *src  = raw + (size_t)y * (stride + 1);
        uint8_t filter = src[0];
        uint8_t *row   = src + 1;

        png_unfilter(row, prev_row, bpp, stride, filter);

        uint8_t *dst = img->pixels + (size_t)y * width * 3;
        for (uint32_t x = 0; x < width; x++) {
            dst[x * 3 + 0] = row[x * bpp + 0];
            dst[x * 3 + 1] = row[x * bpp + 1];
            dst[x * 3 + 2] = row[x * bpp + 2];
            /* Alpha channel (if RGBA) is discarded — composited onto white */
        }
        memcpy(prev_row, row, stride);
    }

    free(prev_row);
    free(raw);
    return img;
}

static void image_free(image_t *img) {
    if (img) { free(img->pixels); free(img); }
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  Bilinear resize
 * ═══════════════════════════════════════════════════════════════════════════ */

static image_t *image_resize(const image_t *src, uint32_t nw, uint32_t nh) {
    image_t *dst = malloc(sizeof(image_t));
    if (!dst) return NULL;
    dst->width  = nw;
    dst->height = nh;
    dst->pixels = malloc((size_t)nw * nh * 3);
    if (!dst->pixels) { free(dst); return NULL; }

    for (uint32_t y = 0; y < nh; y++) {
        double sy = (double)y * (src->height - 1) / (nh > 1 ? nh - 1 : 1);
        uint32_t y0 = (uint32_t)sy;
        uint32_t y1 = (y0 + 1 < src->height) ? y0 + 1 : y0;
        double fy = sy - y0;

        for (uint32_t x = 0; x < nw; x++) {
            double sx = (double)x * (src->width - 1) / (nw > 1 ? nw - 1 : 1);
            uint32_t x0 = (uint32_t)sx;
            uint32_t x1 = (x0 + 1 < src->width) ? x0 + 1 : x0;
            double fx = sx - x0;

            for (int c = 0; c < 3; c++) {
                double a = src->pixels[(y0 * src->width + x0) * 3 + c];
                double b = src->pixels[(y0 * src->width + x1) * 3 + c];
                double d = src->pixels[(y1 * src->width + x0) * 3 + c];
                double e = src->pixels[(y1 * src->width + x1) * 3 + c];
                double v = a * (1-fx) * (1-fy) + b * fx * (1-fy)
                         + d * (1-fx) * fy     + e * fx * fy;
                int iv = (int)(v + 0.5);
                dst->pixels[(y * nw + x) * 3 + c] =
                    (uint8_t)(iv < 0 ? 0 : (iv > 255 ? 255 : iv));
            }
        }
    }
    return dst;
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  Colour space helpers
 * ═══════════════════════════════════════════════════════════════════════════ */

static double clamp01(double x) { return x < 0.0 ? 0.0 : (x > 1.0 ? 1.0 : x); }

static void rgb_to_hsl(int r, int g, int b, double *h, double *s, double *l) {
    double rr = r / 255.0, gg = g / 255.0, bb = b / 255.0;
    double mx = rr > gg ? (rr > bb ? rr : bb) : (gg > bb ? gg : bb);
    double mn = rr < gg ? (rr < bb ? rr : bb) : (gg < bb ? gg : bb);
    *l = (mx + mn) / 2.0;
    if (mx == mn) { *h = *s = 0.0; return; }
    double d = mx - mn;
    *s = (*l > 0.5) ? d / (2.0 - mx - mn) : d / (mx + mn);
    if      (mx == rr) *h = (gg - bb) / d + (gg < bb ? 6.0 : 0.0);
    else if (mx == gg) *h = (bb - rr) / d + 2.0;
    else               *h = (rr - gg) / d + 4.0;
    *h /= 6.0;
}

static double hue2rgb(double p, double q, double t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5)     return q;
    if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
    return p;
}

static void hsl_to_rgb(double h, double s, double l, int *r, int *g, int *b) {
    if (s == 0.0) {
        int v = (int)(l * 255.0 + 0.5);
        *r = *g = *b = v;
        return;
    }
    double q = (l < 0.5) ? l * (1.0 + s) : l + s - l * s;
    double p = 2.0 * l - q;
    *r = (int)(hue2rgb(p, q, h + 1.0/3.0) * 255.0 + 0.5);
    *g = (int)(hue2rgb(p, q, h)            * 255.0 + 0.5);
    *b = (int)(hue2rgb(p, q, h - 1.0/3.0) * 255.0 + 0.5);
}

static void pastelize(int *r, int *g, int *b, double strength) {
    double h, s, l;
    rgb_to_hsl(*r, *g, *b, &h, &s, &l);
    s = clamp01(s * (1.0 - 0.75 * strength));
    l = clamp01(l + 0.25 * strength);
    hsl_to_rgb(h, s, l, r, g, b);
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  xterm-256 colour index mapping
 * ═══════════════════════════════════════════════════════════════════════════ */

static const int LEVELS[6] = {0, 95, 135, 175, 215, 255};

static int nearest_level(int v) {
    int best = 0, best_d = abs(LEVELS[0] - v);
    for (int i = 1; i < 6; i++) {
        int d = abs(LEVELS[i] - v);
        if (d < best_d) { best = i; best_d = d; }
    }
    return best;
}

static int xterm256(int r, int g, int b) {
    int ri = nearest_level(r), rr = LEVELS[ri];
    int gi = nearest_level(g), gg = LEVELS[gi];
    int bi = nearest_level(b), bb = LEVELS[bi];
    int cube_code = 16 + 36 * ri + 6 * gi + bi;
    int cube_dist = (r-rr)*(r-rr) + (g-gg)*(g-gg) + (b-bb)*(b-bb);

    int gray = (r + g + b) / 3;
    int gidx = (int)((gray - 8 + 5) / 10);
    if (gidx < 0)  gidx = 0;
    if (gidx > 23) gidx = 23;
    int gval = 8 + 10 * gidx;
    int gray_code = 232 + gidx;
    int gray_dist = (r-gval)*(r-gval) + (g-gval)*(g-gval) + (b-gval)*(b-gval);

    return (gray_dist < cube_dist) ? gray_code : cube_code;
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  Renderer: half-block ▀ with fg (top pixel) + bg (bottom pixel)
 * ═══════════════════════════════════════════════════════════════════════════ */

static void render(const image_t *img, double pastel_strength) {
    uint32_t w = img->width;
    uint32_t h = img->height;

    for (uint32_t y = 0; y + 1 < h; y += 2) {
        int last_fg = -1, last_bg = -1;
        for (uint32_t x = 0; x < w; x++) {
            const uint8_t *top = img->pixels + ((size_t)y * w + x) * 3;
            const uint8_t *bot = img->pixels + ((size_t)(y+1) * w + x) * 3;

            int rt = top[0], gt = top[1], bt = top[2];
            int rb = bot[0], gb = bot[1], bb = bot[2];

            if (pastel_strength > 0.001) {
                pastelize(&rt, &gt, &bt, pastel_strength);
                pastelize(&rb, &gb, &bb, pastel_strength);
            }

            int fg = xterm256(rt, gt, bt);
            int bg = xterm256(rb, gb, bb);

            if (fg != last_fg || bg != last_bg) {
                printf("\033[38;5;%dm\033[48;5;%dm", fg, bg);
                last_fg = fg;
                last_bg = bg;
            }
            putchar(0xE2); putchar(0x96); putchar(0x80); /* UTF-8 for ▀ */
        }
        printf("\033[0m\n");
    }
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  CLI
 * ═══════════════════════════════════════════════════════════════════════════ */

static void usage(const char *argv0) {
    fprintf(stderr,
        "FlowerOS png2term — PNG to terminal colour blocks\n"
        "\n"
        "Usage: %s <image.png> [cols] [pastel]\n"
        "\n"
        "  cols    Output width in columns          (default: 60)\n"
        "  pastel  Pastel strength 0.0–1.0          (default: 0.55)\n"
        "\n"
        "Examples:\n"
        "  %s logo.png                  # 60-col, default pastel\n"
        "  %s logo.png 34 0.50          # MOTD sidebar width\n"
        "  %s photo.png 120 0.00        # Full-width, true colour\n"
        "\n"
        "MOTD integration:\n"
        "  %s logo.png 34 0.50 > motd/ascii-output/logo-motd.txt\n"
        "\n"
        "Build: gcc -O2 -std=c11 -Wall -Wextra -o png2term png2term.c -lm -lz\n",
        argv0, argv0, argv0, argv0, argv0);
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(argv[0]); return 1; }
    if (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        usage(argv[0]); return 0;
    }

    const char *path = argv[1];
    int   cols   = (argc > 2) ? atoi(argv[2]) : 60;
    double pastel = (argc > 3) ? atof(argv[3]) : 0.55;

    if (cols < 4) cols = 4;
    if (cols > 400) cols = 400;
    if (pastel < 0.0) pastel = 0.0;
    if (pastel > 1.0) pastel = 1.0;

    image_t *img = png_load(path);
    if (!img) return 1;

    /* Compute resize keeping aspect ratio.  Terminal chars are ~2:1
     * (half-block pairs represent 2 vertical pixels per row), so
     * we double the target height then halve it during rendering. */
    double scale = (double)cols / (double)img->width;
    uint32_t new_w = (uint32_t)cols;
    uint32_t new_h = (uint32_t)(img->height * scale + 0.5);
    if (new_h < 2) new_h = 2;
    new_h = (new_h / 2) * 2; /* must be even for half-block pairs */

    image_t *resized = image_resize(img, new_w, new_h);
    image_free(img);
    if (!resized) { fprintf(stderr, "png2term: resize failed\n"); return 1; }

    render(resized, pastel);
    image_free(resized);
    return 0;
}
