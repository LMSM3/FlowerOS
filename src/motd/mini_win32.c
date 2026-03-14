#define WIN32_LEAN_AND_MEAN

#include <windows.h>


static HWND hEdit, hLabel;


LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {

    switch (msg) {

    case WM_CREATE: {

        // Edit box

        hEdit = CreateWindowExA(WS_EX_CLIENTEDGE, "EDIT", "",

            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,

            10, 10, 260, 24, hwnd, (HMENU)101, GetModuleHandle(NULL), NULL);


        // Button

        CreateWindowExA(0, "BUTTON", "Copy",

            WS_CHILD | WS_VISIBLE,

            280, 10, 80, 24, hwnd, (HMENU)102, GetModuleHandle(NULL), NULL);


        // Label

        hLabel = CreateWindowExA(0, "STATIC", "Type text, press Copy.",

            WS_CHILD | WS_VISIBLE,

            10, 45, 350, 24, hwnd, (HMENU)103, GetModuleHandle(NULL), NULL);

        return 0;

    }

    case WM_COMMAND: {

        if (LOWORD(wParam) == 102) { // Button id

            char buf[512];

            GetWindowTextA(hEdit, buf, (int)sizeof(buf));

            SetWindowTextA(hLabel, buf[0] ? buf : "(empty)");

        }

        return 0;

    }

    case WM_DESTROY:

        PostQuitMessage(0);

        return 0;

    }

    return DefWindowProc(hwnd, msg, wParam, lParam);

}


int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrev, LPSTR lpCmdLine, int nShow) {

    (void)hPrev; (void)lpCmdLine;


    const char *CLASS_NAME = "MiniWin32Class";


    WNDCLASSA wc = {0};

    wc.lpfnWndProc   = WndProc;

    wc.hInstance     = hInst;

    wc.lpszClassName = CLASS_NAME;

    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);


    if (!RegisterClassA(&wc)) return 1;


    HWND hwnd = CreateWindowExA(

        0, CLASS_NAME, "Mini Win32 (C)",

        WS_OVERLAPPEDWINDOW,

        CW_USEDEFAULT, CW_USEDEFAULT, 400, 140,

        NULL, NULL, hInst, NULL

    );

    if (!hwnd) return 1;


    ShowWindow(hwnd, nShow);

    UpdateWindow(hwnd);


    MSG msg;

    while (GetMessage(&msg, NULL, 0, 0) > 0) {

        TranslateMessage(&msg);

        DispatchMessage(&msg);

    }

    return (int)msg.wParam;

}

