#ifndef FLOWEROS_FP_H
#define FLOWEROS_FP_H

/**
 * @defgroup fp_config FlowerPublish Configuration
 * @brief Compile-time constants governing FlowerPublish behaviour and limits.
 *
 * These macros define the version string, filesystem conventions, and
 * buffer-size limits used throughout the FlowerPublish (FP) LaTeX frontend.
 * @{
 */

/** @brief Semantic version string for the FlowerPublish tool. */
#define FP_VERSION       "1.0.0"

/** @brief Name of the build-output directory (plant-themed: "bloom").
 *
 *  All pdflatex artefacts (PDF, aux, log, etc.) are written here,
 *  keeping the source tree clean.  Passed to pdflatex via
 *  @c -output-directory.
 */
#define FP_BUILD_DIR     "bloom"

/** @brief Default file extension used when creating new LaTeX templates. */
#define FP_TEMPLATE_EXT  ".tex"

/** @brief Maximum supported filesystem-path length in bytes.
 *
 *  Used to size stack buffers that hold resolved source and output paths.
 *  Set to 4096 to match the common Linux @c PATH_MAX value.
 */
#define FP_MAX_PATH      4096

/** @brief Maximum line length (in bytes) that FP will read from a file.
 *
 *  Lines exceeding this limit are silently truncated when parsing
 *  LaTeX log output or source files.
 */
#define FP_MAX_LINE      8192

/** @brief Number of trailing log lines shown on a LaTeX compilation error.
 *
 *  When pdflatex returns a non-zero exit code, the last @c FP_LOG_LINES
 *  lines of the @c .log file inside @ref FP_BUILD_DIR are printed to
 *  stderr with pastel-coloured diagnostics.
 */
#define FP_LOG_LINES     40

/** @} */ // end of fp_config

/**
 * @defgroup fp_ansi ANSI Pastel Palette
 * @brief 256-colour SGR escape sequences for terminal output.
 *
 * FlowerOS uses a soft pastel palette across all tools.  Each macro
 * expands to a string literal containing the full @c ESC[ sequence so
 * it can be embedded directly in @c printf format strings.
 * @{
 */

/** @brief Reset all SGR attributes. */
#define FP_RST   "\033[0m"
/** @brief Dim grey (index 245). */
#define FP_DIM   "\033[38;5;245m"
/** @brief Accent mint / cyan (index 117). */
#define FP_ACC   "\033[38;5;117m"
/** @brief Pastel pink (index 219). */
#define FP_PNK   "\033[38;5;219m"
/** @brief Pastel green (index 120). */
#define FP_GRN   "\033[38;5;120m"
/** @brief Pastel red (index 210). */
#define FP_RED   "\033[38;5;210m"
/** @brief Pastel yellow (index 229). */
#define FP_YLW   "\033[38;5;229m"
/** @brief Pastel blue (index 111). */
#define FP_BLU   "\033[38;5;111m"
/** @brief Pastel magenta (index 183). */
#define FP_MAG   "\033[38;5;183m"
/** @brief Bold weight attribute. */
#define FP_BOLD  "\033[1m"

/** @} */ // end of fp_ansi

/**
 * @defgroup fp_rc Return Codes
 * @brief Process exit codes returned by every @c fp_cmd_* function.
 *
 * These follow the convention: 0 = success, non-zero = category of
 * failure.  The value is propagated unchanged to @c main's return.
 * @{
 */

#define FP_OK         0   /**< Success. */
#define FP_ERR_ARGS   1   /**< Bad or missing command-line arguments. */
#define FP_ERR_IO     2   /**< Filesystem error (read/write/missing file). */
#define FP_ERR_LATEX  3   /**< pdflatex returned a non-zero exit code. */
#define FP_ERR_DEPS   4   /**< Required external tool not found. */

/** @} */ // end of fp_rc

/**
 * @brief Identifies which sub-command the user requested.
 *
 * Returned by @ref fp_parse_command and used by @c main to dispatch
 * into the corresponding @c fp_cmd_* handler.
 */
typedef enum {
    CMD_HELP,       /**< Show banner + usage text. */
    CMD_NEW,        /**< Scaffold a new .tex from the built-in template. */
    CMD_EDIT,       /**< Open a .tex file in @c $EDITOR. */
    CMD_BUILD,      /**< Compile .tex → .pdf via pdflatex. */
    CMD_VIEW,       /**< Launch a PDF viewer. */
    CMD_WATCH,      /**< Rebuild automatically on file save. */
    CMD_DEPS,       /**< Install Debian/Ubuntu dependencies. */
    CMD_UNKNOWN     /**< Unrecognised command string. */
} FpCommand;

/**
 * @defgroup fp_api Public API
 * @brief Entry points called from @c main after command parsing.
 * @{
 */

/** @brief Print the pastel FlowerPublish splash banner. */
void        fp_banner(void);

/** @brief Map a CLI string (e.g. "build") to an @ref FpCommand value.
 *  @param arg  The first positional argument from @c argv (may be NULL).
 *  @return Corresponding @ref FpCommand, or @ref CMD_HELP / @ref CMD_UNKNOWN.
 */
FpCommand   fp_parse_command(const char *arg);

/** @brief Create a new .tex file from the built-in template.
 *  @param name  Document name (without extension).
 *  @return @ref FP_OK on success.
 */
int         fp_cmd_new(const char *name);

/** @brief Open @p file in the user's @c $EDITOR (nano/vi fallback).
 *  @param file  Path to the .tex file.
 *  @return Editor's exit code, or @ref FP_ERR_DEPS if no editor is found.
 */
int         fp_cmd_edit(const char *file);

/** @brief Compile a .tex file to PDF via pdflatex (two-pass).
 *  @param file   Path to the .tex source.
 *  @param clean  If non-zero, remove auxiliary files after a successful build.
 *  @return @ref FP_OK on success, @ref FP_ERR_LATEX on compilation failure.
 */
int         fp_cmd_build(const char *file, int clean);

/** @brief Open a PDF in the first available viewer.
 *  @param file  Path to a .tex (auto-resolved to bloom/name.pdf) or .pdf.
 *  @return @ref FP_OK on success.
 */
int         fp_cmd_view(const char *file);

/** @brief Watch @p file for writes and rebuild on each save.
 *  @param file  Path to the .tex source.
 *  @return Does not normally return; @ref FP_ERR_DEPS if inotifywait missing.
 */
int         fp_cmd_watch(const char *file);

/** @brief Interactive installer for pdflatex and related Debian packages.
 *  @return @ref FP_OK when all dependencies are satisfied.
 */
int         fp_cmd_deps(void);

/** @brief Print the banner followed by full command-line usage text. */
void        fp_help(void);

/** @} */ // end of fp_api

#endif // FLOWEROS_FP_H
