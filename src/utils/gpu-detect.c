// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS GPU Detection Utility
//  Hardware detection layer for GPU capabilities
//  
//  Status: STUB IMPLEMENTATION - Detects GPU but doesn't accelerate anything
// ═══════════════════════════════════════════════════════════════════════════

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#ifdef _WIN32
#include <windows.h>
#include <setupapi.h>
#include <devguid.h>
#pragma comment(lib, "setupapi.lib")
#endif

// ═══════════════════════════════════════════════════════════════════════════
//  GPU Information Structure
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    char name[256];
    char vendor[128];
    unsigned long long vram_bytes;
    int cuda_cores;
    int compute_capability_major;
    int compute_capability_minor;
    bool is_cuda_capable;
    bool is_opencl_capable;
} GPUInfo;

// ═══════════════════════════════════════════════════════════════════════════
//  Platform-Specific Detection
// ═══════════════════════════════════════════════════════════════════════════

#ifdef _WIN32

static int detect_gpus_windows(GPUInfo* gpus, int max_gpus) {
    int count = 0;
    HDEVINFO hDevInfo;
    SP_DEVINFO_DATA DeviceInfoData;
    DWORD i;
    
    // Get device information set for display adapters
    hDevInfo = SetupDiGetClassDevs(&GUID_DEVCLASS_DISPLAY, 0, 0, DIGCF_PRESENT);
    if (hDevInfo == INVALID_HANDLE_VALUE) {
        return 0;
    }
    
    DeviceInfoData.cbSize = sizeof(SP_DEVINFO_DATA);
    
    for (i = 0; SetupDiEnumDeviceInfo(hDevInfo, i, &DeviceInfoData) && count < max_gpus; i++) {
        DWORD DataT;
        LPTSTR buffer = NULL;
        DWORD buffersize = 0;
        
        // Get device description
        while (!SetupDiGetDeviceRegistryProperty(hDevInfo, &DeviceInfoData, SPDRP_DEVICEDESC,
                                                  &DataT, (PBYTE)buffer, buffersize, &buffersize)) {
            if (GetLastError() == ERROR_INSUFFICIENT_BUFFER) {
                if (buffer) LocalFree(buffer);
                buffer = (LPTSTR)LocalAlloc(LPTR, buffersize);
            } else {
                break;
            }
        }
        
        if (buffer) {
            // Convert to narrow string
            #ifdef UNICODE
            wcstombs(gpus[count].name, buffer, sizeof(gpus[count].name) - 1);
            #else
            strncpy(gpus[count].name, buffer, sizeof(gpus[count].name) - 1);
            #endif
            
            // Detect vendor
            if (strstr(gpus[count].name, "NVIDIA") || strstr(gpus[count].name, "nVidia")) {
                strcpy(gpus[count].vendor, "NVIDIA");
                gpus[count].is_cuda_capable = true;
            } else if (strstr(gpus[count].name, "AMD") || strstr(gpus[count].name, "Radeon")) {
                strcpy(gpus[count].vendor, "AMD");
                gpus[count].is_opencl_capable = true;
            } else if (strstr(gpus[count].name, "Intel")) {
                strcpy(gpus[count].vendor, "Intel");
                gpus[count].is_opencl_capable = true;
            } else {
                strcpy(gpus[count].vendor, "Unknown");
            }
            
            // Estimate VRAM (stub - would need WMI or vendor APIs)
            gpus[count].vram_bytes = 0;  // Unknown
            gpus[count].cuda_cores = 0;  // Unknown without CUDA runtime
            
            count++;
            LocalFree(buffer);
        }
    }
    
    SetupDiDestroyDeviceInfoList(hDevInfo);
    return count;
}

#else // Linux

static int detect_gpus_linux(GPUInfo* gpus, int max_gpus) {
    int count = 0;
    
    // Try to read from /proc or lspci
    FILE* fp = popen("lspci | grep -i vga", "r");
    if (fp) {
        char line[512];
        while (fgets(line, sizeof(line), fp) && count < max_gpus) {
            strncpy(gpus[count].name, line, sizeof(gpus[count].name) - 1);
            
            // Detect vendor
            if (strstr(line, "NVIDIA")) {
                strcpy(gpus[count].vendor, "NVIDIA");
                gpus[count].is_cuda_capable = true;
            } else if (strstr(line, "AMD") || strstr(line, "ATI")) {
                strcpy(gpus[count].vendor, "AMD");
                gpus[count].is_opencl_capable = true;
            } else if (strstr(line, "Intel")) {
                strcpy(gpus[count].vendor, "Intel");
                gpus[count].is_opencl_capable = true;
            }
            
            count++;
        }
        pclose(fp);
    }
    
    return count;
}

#endif

// ═══════════════════════════════════════════════════════════════════════════
//  Public API
// ═══════════════════════════════════════════════════════════════════════════

static int detect_gpus(GPUInfo* gpus, int max_gpus) {
#ifdef _WIN32
    return detect_gpus_windows(gpus, max_gpus);
#else
    return detect_gpus_linux(gpus, max_gpus);
#endif
}

static void print_gpu_info(const GPUInfo* gpu) {
    printf("  Name: %s\n", gpu->name);
    printf("  Vendor: %s\n", gpu->vendor);
    
    if (gpu->vram_bytes > 0) {
        printf("  VRAM: %.2f GB\n", gpu->vram_bytes / (1024.0 * 1024.0 * 1024.0));
    } else {
        printf("  VRAM: Unknown\n");
    }
    
    if (gpu->cuda_cores > 0) {
        printf("  CUDA Cores: %d\n", gpu->cuda_cores);
    }
    
    printf("  CUDA Capable: %s\n", gpu->is_cuda_capable ? "Yes" : "No");
    printf("  OpenCL Capable: %s\n", gpu->is_opencl_capable ? "Yes" : "No");
}

// ═══════════════════════════════════════════════════════════════════════════
//  Command Line Interface
// ═══════════════════════════════════════════════════════════════════════════

static void print_usage(const char* prog) {
    printf("Usage: %s <command>\n", prog);
    printf("\nCommands:\n");
    printf("  status      - Show GPU detection status\n");
    printf("  info        - Show detailed GPU information\n");
    printf("  list        - List all detected GPUs\n");
    printf("  help        - Show this help message\n");
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("\033[31m⚠️  STUB: GPU detection utility\033[0m\n");
        printf("This is a basic hardware detection tool.\n");
        printf("It does NOT provide actual GPU acceleration.\n\n");
        print_usage(argv[0]);
        return 1;
    }
    
    GPUInfo gpus[16];
    memset(gpus, 0, sizeof(gpus));
    
    const char* cmd = argv[1];
    
    if (strcmp(cmd, "status") == 0) {
        printf("\033[33mGPU Detection Status\033[0m\n");
        printf("════════════════════════════════════════\n\n");
        
        int count = detect_gpus(gpus, 16);
        
        if (count > 0) {
            printf("  GPUs Detected: %d\n", count);
            printf("  Status: \033[32mAvailable\033[0m\n");
            printf("  Mode: CPU fallback (no acceleration)\n\n");
            
            printf("\033[33m⚠️  WARNING:\033[0m\n");
            printf("  GPU hardware detected, but FlowerOS does not\n");
            printf("  currently implement GPU acceleration.\n");
            printf("  All processing runs on CPU.\n\n");
            
            printf("  To enable GPU acceleration:\n");
            printf("    1. Install CUDA toolkit (NVIDIA)\n");
            printf("    2. Rebuild FlowerOS with CUDA support\n");
            printf("    3. Implement GPU kernels in C/C++/CUDA\n");
        } else {
            printf("  GPUs Detected: 0\n");
            printf("  Status: \033[31mNone found\033[0m\n");
            printf("  Mode: CPU only\n");
        }
    }
    else if (strcmp(cmd, "info") == 0) {
        printf("\033[33mGPU Information\033[0m\n");
        printf("════════════════════════════════════════\n\n");
        
        printf("Hardware Detection: Special hardware layer\n");
        printf("Status: Stub implementation\n");
        printf("Acceleration: Not available\n\n");
        
        printf("FlowerOS GPU features require:\n");
        printf("  • CUDA toolkit installation\n");
        printf("  • OpenCL platform setup\n");
        printf("  • ROCm for AMD GPUs\n");
        printf("  • Kernel implementation in CUDA/OpenCL\n\n");
        
        int count = detect_gpus(gpus, 16);
        printf("Detected %d GPU(s) via OS enumeration:\n\n", count);
        
        for (int i = 0; i < count; i++) {
            printf("GPU %d:\n", i);
            print_gpu_info(&gpus[i]);
            printf("\n");
        }
    }
    else if (strcmp(cmd, "list") == 0) {
        int count = detect_gpus(gpus, 16);
        
        for (int i = 0; i < count; i++) {
            printf("%d: %s (%s)\n", i, gpus[i].name, gpus[i].vendor);
        }
        
        if (count == 0) {
            printf("No GPUs detected\n");
        }
    }
    else if (strcmp(cmd, "help") == 0) {
        print_usage(argv[0]);
    }
    else {
        printf("Unknown command: %s\n\n", cmd);
        print_usage(argv[0]);
        return 1;
    }
    
    return 0;
}
