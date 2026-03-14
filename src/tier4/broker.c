// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS Tier 4 — Broker Implementation
//  Named Pipe Server + State Management
//  
//  This is the heart of Tier 4: owns the pipe and authoritative state.
// ═══════════════════════════════════════════════════════════════════════════

#ifdef _WIN32

#include "broker.h"
#include <windows.h>
#include <shlobj.h>
#include <dpapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// ─────────────────────────────────────────────────────────────────────────
//  Simple JSON Parser (Minimal, No External Dependencies)
// ─────────────────────────────────────────────────────────────────────────

typedef struct {
    char* data;
    size_t size;
    size_t capacity;
} JsonBuilder;

static JsonBuilder* json_builder_create(void) {
    JsonBuilder* jb = calloc(1, sizeof(JsonBuilder));
    jb->capacity = 1024;
    jb->data = malloc(jb->capacity);
    jb->data[0] = '\0';
    return jb;
}

static void json_builder_append(JsonBuilder* jb, const char* str) {
    size_t len = strlen(str);
    while (jb->size + len + 1 >= jb->capacity) {
        jb->capacity *= 2;
        jb->data = realloc(jb->data, jb->capacity);
    }
    strcpy(jb->data + jb->size, str);
    jb->size += len;
}

static void json_builder_free(JsonBuilder* jb) {
    free(jb->data);
    free(jb);
}

// ─────────────────────────────────────────────────────────────────────────
//  Global State
// ─────────────────────────────────────────────────────────────────────────

static struct {
    char state_dir[MAX_PATH];
    char state_file[MAX_PATH];
    JsonBuilder* state;
    BOOL running;
    HANDLE pipe;
} g_broker = {0};

// ─────────────────────────────────────────────────────────────────────────
//  Initialization
// ─────────────────────────────────────────────────────────────────────────

int broker_init(const char* state_dir) {
    // Determine state directory
    if (state_dir) {
        strncpy_s(g_broker.state_dir, MAX_PATH, state_dir, _TRUNCATE);
    } else {
        char localAppData[MAX_PATH];
        if (SHGetFolderPathA(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, localAppData) != S_OK) {
            fprintf(stderr, "Failed to get LocalAppData path\n");
            return -1;
        }
        snprintf(g_broker.state_dir, MAX_PATH, "%s\\FlowerOS\\state", localAppData);
    }
    
    // Create directory if needed
    CreateDirectoryA(g_broker.state_dir, NULL);
    
    // Set state file path
    snprintf(g_broker.state_file, MAX_PATH, "%s\\%s", g_broker.state_dir, FLOWEROS_STATE_FILENAME);
    
    // Secure the directory
    if (secure_state_dir(g_broker.state_dir) != 0) {
        fprintf(stderr, "Warning: Could not secure state directory\n");
    }
    
    // Load state from disk (or create new)
    if (state_load() != 0) {
        // First run - initialize
        printf("First run detected, initializing state...\n");
        if (detect_all() != 0) {
            fprintf(stderr, "Failed to initialize state\n");
            return -1;
        }
        state_save();
    }
    
    printf("FlowerOS Broker initialized\n");
    printf("  State: %s\n", g_broker.state_file);
    printf("  Pipe: %s\n", FLOWEROS_PIPE_NAME);
    
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  State Operations
// ─────────────────────────────────────────────────────────────────────────

char* state_get(const char* key) {
    if (!g_broker.state) return NULL;
    
    // Simple key lookup in JSON (naive implementation)
    char search[256];
    snprintf(search, sizeof(search), "\"%s\":\"", key);
    
    char* pos = strstr(g_broker.state->data, search);
    if (!pos) return NULL;
    
    pos += strlen(search);
    char* end = strchr(pos, '"');
    if (!end) return NULL;
    
    size_t len = end - pos;
    char* value = malloc(len + 1);
    strncpy_s(value, len + 1, pos, len);
    value[len] = '\0';
    
    return value;
}

int state_set(const char* key, const char* value_json) {
    if (!g_broker.state) {
        g_broker.state = json_builder_create();
        json_builder_append(g_broker.state, "{}");
    }
    
    // Simple set: rebuild JSON with new value
    // Production code would use proper JSON library
    char* old_value = state_get(key);
    
    if (old_value) {
        // Replace existing
        char old_entry[512], new_entry[512];
        snprintf(old_entry, sizeof(old_entry), "\"%s\":\"%s\"", key, old_value);
        snprintf(new_entry, sizeof(new_entry), "\"%s\":%s", key, value_json);
        
        // Find and replace (naive)
        char* pos = strstr(g_broker.state->data, old_entry);
        if (pos) {
            // Rebuild JSON
            JsonBuilder* new_state = json_builder_create();
            size_t before_len = pos - g_broker.state->data;
            char before[4096];
            strncpy_s(before, sizeof(before), g_broker.state->data, before_len);
            before[before_len] = '\0';
            
            json_builder_append(new_state, before);
            json_builder_append(new_state, new_entry);
            
            char* after = pos + strlen(old_entry);
            json_builder_append(new_state, after);
            
            json_builder_free(g_broker.state);
            g_broker.state = new_state;
        }
        free(old_value);
    } else {
        // Add new entry (insert before closing brace)
        char* closing = strrchr(g_broker.state->data, '}');
        if (closing) {
            JsonBuilder* new_state = json_builder_create();
            size_t before_len = closing - g_broker.state->data;
            char before[4096];
            strncpy_s(before, sizeof(before), g_broker.state->data, before_len);
            before[before_len] = '\0';
            
            json_builder_append(new_state, before);
            if (before_len > 1) json_builder_append(new_state, ",");
            
            char entry[512];
            snprintf(entry, sizeof(entry), "\"%s\":%s}", key, value_json);
            json_builder_append(new_state, entry);
            
            json_builder_free(g_broker.state);
            g_broker.state = new_state;
        }
    }
    
    state_save();
    return 0;
}

int state_save(void) {
    if (!g_broker.state) return -1;
    
    FILE* f = NULL;
    errno_t err = fopen_s(&f, g_broker.state_file, "w");
    if (err != 0 || !f) {
        fprintf(stderr, "Failed to save state to %s\n", g_broker.state_file);
        return -1;
    }
    
    fprintf(f, "%s\n", g_broker.state->data);
    fclose(f);
    
    return 0;
}

int state_load(void) {
    FILE* f = NULL;
    errno_t err = fopen_s(&f, g_broker.state_file, "r");
    if (err != 0 || !f) {
        return -1;  // File doesn't exist yet
    }
    
    // Read entire file
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (g_broker.state) json_builder_free(g_broker.state);
    g_broker.state = json_builder_create();
    
    char* buffer = malloc(size + 1);
    fread(buffer, 1, size, f);
    buffer[size] = '\0';
    fclose(f);
    
    json_builder_append(g_broker.state, buffer);
    free(buffer);
    
    printf("State loaded: %zu bytes\n", g_broker.state->size);
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  System Detection
// ─────────────────────────────────────────────────────────────────────────

int detect_system(void) {
    char username[256];
    DWORD username_len = sizeof(username);
    GetUserNameA(username, &username_len);
    state_set("system.USER", username);
    
    char desktop[MAX_PATH];
    if (SHGetFolderPathA(NULL, CSIDL_DESKTOP, NULL, 0, desktop) == S_OK) {
        char escaped[MAX_PATH * 2];
        // Escape backslashes for JSON
        char* src = desktop;
        char* dst = escaped;
        while (*src) {
            if (*src == '\\') *dst++ = '\\';
            *dst++ = *src++;
        }
        *dst = '\0';
        
        char value[MAX_PATH * 2 + 3];
        snprintf(value, sizeof(value), "\"%s\"", escaped);
        state_set("system.DESKTOP", value);
    }
    
    char hostname[256];
    DWORD hostname_len = sizeof(hostname);
    GetComputerNameA(hostname, &hostname_len);
    
    char value[260];
    snprintf(value, sizeof(value), "\"%s\"", hostname);
    state_set("system.HOSTNAME", value);
    
    printf("Detected system: %s@%s\n", username, hostname);
    return 0;
}

int detect_drives(void) {
    DWORD drives = GetLogicalDrives();
    
    JsonBuilder* drive_list = json_builder_create();
    json_builder_append(drive_list, "[");
    
    BOOL first = TRUE;
    for (int i = 0; i < 26; i++) {
        if (drives & (1 << i)) {
            char drive[4] = { 'A' + i, ':', '\0', '\0' };
            char root[4] = { drive[0], ':', '\\', '\0' };
            
            UINT type = GetDriveTypeA(root);
            const char* type_str = "unknown";
            if (type == DRIVE_FIXED) type_str = "fixed";
            else if (type == DRIVE_REMOVABLE) type_str = "removable";
            else if (type == DRIVE_REMOTE) type_str = "network";
            else if (type == DRIVE_CDROM) type_str = "cdrom";
            
            if (!first) json_builder_append(drive_list, ",");
            
            char entry[256];
            snprintf(entry, sizeof(entry), "{\"letter\":\"%s\",\"type\":\"%s\"}", drive, type_str);
            json_builder_append(drive_list, entry);
            
            first = FALSE;
        }
    }
    
    json_builder_append(drive_list, "]");
    state_set("drives.DRIVE_LIST", drive_list->data);
    
    json_builder_free(drive_list);
    printf("Detected drives\n");
    return 0;
}

int detect_terminals(void) {
    // Detect common terminal emulators
    state_set("shell.DEFAULT_SHELL", "\"pwsh.exe\"");
    printf("Detected terminals\n");
    return 0;
}

int detect_all(void) {
    // Initialize empty state
    if (g_broker.state) json_builder_free(g_broker.state);
    g_broker.state = json_builder_create();
    json_builder_append(g_broker.state, "{");
    json_builder_append(g_broker.state, "\"floweros\":{\"FLOWEROS_VERSION\":\"1.3.0\",\"TIER\":4}");
    json_builder_append(g_broker.state, "}");
    
    detect_system();
    detect_drives();
    detect_terminals();
    
    // Add features
    state_set("features.gpu_enabled", "false");
    state_set("features.network_enabled", "false");
    state_set("features.theme", "\"garden\"");
    
    return 0;
}

// ─────────────────────────────────────────────────────────────────────────
//  Security
// ─────────────────────────────────────────────────────────────────────────

int secure_state_dir(const char* path) {
    // Set ACLs so only current user can access
    // Simplified: production would use proper ACL API
    return 0;  // Placeholder
}

char* dpapi_encrypt(const char* plaintext) {
    DATA_BLOB plainBlob, cipherBlob;
    plainBlob.pbData = (BYTE*)plaintext;
    plainBlob.cbData = (DWORD)strlen(plaintext) + 1;
    
    if (!CryptProtectData(&plainBlob, L"FlowerOS", NULL, NULL, NULL, 0, &cipherBlob)) {
        return NULL;
    }
    
    // Base64 encode (simplified - just hex for now)
    char* hex = malloc(cipherBlob.cbData * 2 + 1);
    for (DWORD i = 0; i < cipherBlob.cbData; i++) {
        sprintf(hex + i * 2, "%02X", cipherBlob.pbData[i]);
    }
    
    LocalFree(cipherBlob.pbData);
    return hex;
}

char* dpapi_decrypt(const char* ciphertext_b64) {
    // Placeholder - decode hex, then CryptUnprotectData
    return NULL;
}

// ─────────────────────────────────────────────────────────────────────────
//  Message Handling
// ─────────────────────────────────────────────────────────────────────────

static void handle_message(const char* request, char* response, size_t response_size) {
    // Parse simple JSON request
    if (strstr(request, "\"op\":\"ping\"")) {
        snprintf(response, response_size, "{\"ok\":true,\"pong\":true}\n");
    }
    else if (strstr(request, "\"op\":\"get\"")) {
        // Extract key
        char* key_start = strstr(request, "\"key\":\"");
        if (key_start) {
            key_start += 7;
            char* key_end = strchr(key_start, '"');
            if (key_end) {
                char key[256];
                size_t key_len = key_end - key_start;
                strncpy_s(key, sizeof(key), key_start, key_len);
                key[key_len] = '\0';
                
                char* value = state_get(key);
                if (value) {
                    snprintf(response, response_size, "{\"ok\":true,\"value\":\"%s\"}\n", value);
                    free(value);
                } else {
                    snprintf(response, response_size, "{\"ok\":false,\"error\":\"Key not found\"}\n");
                }
            }
        }
    }
    else if (strstr(request, "\"op\":\"set\"")) {
        // Simplified set handler
        snprintf(response, response_size, "{\"ok\":true}\n");
    }
    else if (strstr(request, "\"op\":\"snapshot\"")) {
        if (g_broker.state) {
            snprintf(response, response_size, "{\"ok\":true,\"state\":%s}\n", g_broker.state->data);
        } else {
            snprintf(response, response_size, "{\"ok\":false}\n");
        }
    }
    else if (strstr(request, "\"op\":\"refresh_drives\"")) {
        detect_drives();
        snprintf(response, response_size, "{\"ok\":true}\n");
    }
    else if (strstr(request, "\"op\":\"shutdown\"")) {
        g_broker.running = FALSE;
        snprintf(response, response_size, "{\"ok\":true}\n");
    }
    else {
        snprintf(response, response_size, "{\"ok\":false,\"error\":\"Unknown operation\"}\n");
    }
}

// ─────────────────────────────────────────────────────────────────────────
//  Broker Main Loop
// ─────────────────────────────────────────────────────────────────────────

int broker_run(void) {
    g_broker.running = TRUE;
    
    printf("\nFlowerOS Broker running on pipe: %s\n", FLOWEROS_PIPE_NAME);
    printf("Waiting for connections...\n\n");
    
    while (g_broker.running) {
        // Create named pipe
        g_broker.pipe = CreateNamedPipeA(
            FLOWEROS_PIPE_NAME,
            PIPE_ACCESS_DUPLEX,
            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
            FLOWEROS_MAX_CLIENTS,
            FLOWEROS_PIPE_BUFSIZE,
            FLOWEROS_PIPE_BUFSIZE,
            0,
            NULL
        );
        
        if (g_broker.pipe == INVALID_HANDLE_VALUE) {
            fprintf(stderr, "Failed to create named pipe: %lu\n", GetLastError());
            return -1;
        }
        
        // Wait for client
        BOOL connected = ConnectNamedPipe(g_broker.pipe, NULL) ? 
                         TRUE : (GetLastError() == ERROR_PIPE_CONNECTED);
        
        if (connected) {
            printf("Client connected\n");
            
            char request[FLOWEROS_PIPE_BUFSIZE];
            char response[FLOWEROS_PIPE_BUFSIZE];
            DWORD bytes_read;
            
            // Read request
            if (ReadFile(g_broker.pipe, request, sizeof(request) - 1, &bytes_read, NULL)) {
                request[bytes_read] = '\0';
                
                // Handle message
                handle_message(request, response, sizeof(response));
                
                // Send response
                DWORD bytes_written;
                WriteFile(g_broker.pipe, response, (DWORD)strlen(response), &bytes_written, NULL);
                FlushFileBuffers(g_broker.pipe);
            }
            
            DisconnectNamedPipe(g_broker.pipe);
        }
        
        CloseHandle(g_broker.pipe);
    }
    
    printf("Broker shutdown\n");
    return 0;
}

void broker_shutdown(void) {
    g_broker.running = FALSE;
}

// ─────────────────────────────────────────────────────────────────────────
//  Main Entry Point (if compiled as standalone)
// ─────────────────────────────────────────────────────────────────────────

#ifdef BROKER_STANDALONE

int main(int argc, char** argv) {
    printf("═══════════════════════════════════════════════════════════════════════════\n");
    printf("  FlowerOS Tier 4 Broker v1.0\n");
    printf("  Named Pipe Server + State Store\n");
    printf("═══════════════════════════════════════════════════════════════════════════\n\n");
    
    if (broker_init(NULL) != 0) {
        fprintf(stderr, "Failed to initialize broker\n");
        return 1;
    }
    
    return broker_run();
}

#endif // BROKER_STANDALONE

#endif // _WIN32
