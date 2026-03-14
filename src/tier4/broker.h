// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Tier 4 — Broker
//  Owns the named pipe and the authoritative state.
//  All clients (PowerShell, bash, exe tools) talk to this.
//
//  Pipe:  \\.\pipe\floweros\comm
//  State: %LOCALAPPDATA%\FlowerOS\state\state.json
//  Protocol: NDJSON (newline-delimited JSON) request/response
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWEROS_BROKER_H
#define FLOWEROS_BROKER_H

#ifdef _WIN32

#include <windows.h>
#include <stdint.h>
#include <stdbool.h>

// ─────────────────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────────────────

#define FLOWEROS_PIPE_NAME  "\\\\.\\pipe\\floweros\\comm"
#define FLOWEROS_PIPE_BUFSIZE 4096
#define FLOWEROS_MAX_CLIENTS 16
#define FLOWEROS_STATE_FILENAME "state.json"

// ─────────────────────────────────────────────────────────────────────────
//  Message types (request → broker → response)
// ─────────────────────────────────────────────────────────────────────────
//
//  All messages are single-line JSON terminated by \n
//
//  Request:  {"op":"get","key":"system.USER"}\n
//  Response: {"ok":true,"value":"alice"}\n
//
//  Request:  {"op":"set","key":"features.gpu_enabled","value":true}\n
//  Response: {"ok":true}\n
//
//  Request:  {"op":"list","prefix":"drives"}\n
//  Response: {"ok":true,"keys":["drives.DRIVE_LIST","drives.primary"]}\n
//
//  Request:  {"op":"snapshot"}\n
//  Response: {"ok":true,"state":{...entire state...}}\n
//
//  Request:  {"op":"refresh_drives"}\n
//  Response: {"ok":true,"drives":[...]}\n

typedef enum {
    BROKER_OP_GET           = 0,
    BROKER_OP_SET           = 1,
    BROKER_OP_LIST          = 2,
    BROKER_OP_SNAPSHOT      = 3,
    BROKER_OP_REFRESH_DRIVES = 4,
    BROKER_OP_PING          = 5,
    BROKER_OP_SHUTDOWN      = 6,
    BROKER_OP_UNKNOWN       = 255
} BrokerOp;

// ─────────────────────────────────────────────────────────────────────────
//  Broker lifecycle
// ─────────────────────────────────────────────────────────────────────────

// Initialize broker: load state from disk, set up ACLs, create pipe.
// state_dir: path to directory containing state.json (NULL = default)
// Returns 0 on success, nonzero on error.
int  broker_init(const char *state_dir);

// Run broker loop (blocks). Accepts pipe connections, dispatches ops.
// Returns when broker_shutdown() is called from a handler or signal.
int  broker_run(void);

// Signal the broker to stop. Safe to call from any thread / signal handler.
void broker_shutdown(void);

// ─────────────────────────────────────────────────────────────────────────
//  State operations (called internally by broker or by embedded use)
// ─────────────────────────────────────────────────────────────────────────

// Read value by dotted key (e.g. "system.USER"). Returns NULL if missing.
// Caller must free the returned string.
char *state_get(const char *key);

// Write value by dotted key. value is a JSON fragment.
// Returns 0 on success.
int   state_set(const char *key, const char *value_json);

// Persist current state to disk. Called automatically after set.
int   state_save(void);

// Reload state from disk.
int   state_load(void);

// ─────────────────────────────────────────────────────────────────────────
//  System detection (populates state on first run / refresh)
// ─────────────────────────────────────────────────────────────────────────

// Detect USER, DESKTOP, HOME, HOSTNAME and write to state.
int detect_system(void);

// Enumerate drives and write to state.drives.DRIVE_LIST.
int detect_drives(void);

// Detect installed terminal emulators and write to state.shell.
int detect_terminals(void);

// Full first-run detection (calls all of the above + generates INSTALL_ID).
int detect_all(void);

// ─────────────────────────────────────────────────────────────────────────
//  Security
// ─────────────────────────────────────────────────────────────────────────

// Set ACLs on state directory so only current user can read/write.
int secure_state_dir(const char *path);

// Encrypt a value using DPAPI (user context). Returns base64 ciphertext.
// Caller must free.
char *dpapi_encrypt(const char *plaintext);

// Decrypt a DPAPI-encrypted value. Returns plaintext. Caller must free.
char *dpapi_decrypt(const char *ciphertext_b64);

#endif // _WIN32
#endif // FLOWEROS_BROKER_H
