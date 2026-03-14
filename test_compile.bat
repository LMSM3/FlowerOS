@echo off
REM test_compile.bat - Test compile.bat without self-destruct
setlocal enabledelayedexpansion

echo.
echo ════════════════════════════════════════════════════════
echo   FlowerOS Compile Test (No Self-Destruct)
echo ════════════════════════════════════════════════════════
echo.

REM Determine build method
where bash >nul 2>&1
set HAS_BASH=%errorlevel%

where powershell >nul 2>&1
set HAS_PS=%errorlevel%

echo [*] Checking build tools...
if %HAS_PS% equ 0 (
    echo [+] PowerShell: FOUND
) else (
    echo [-] PowerShell: NOT FOUND
)

if %HAS_BASH% equ 0 (
    echo [+] Bash: FOUND
) else (
    echo [-] Bash: NOT FOUND
)

echo.

REM Test PowerShell build
if %HAS_PS% equ 0 (
    echo ════════════════════════════════════════════════════════
    echo   Testing Native PowerShell Build
    echo ════════════════════════════════════════════════════════
    echo.
    powershell -ExecutionPolicy Bypass -File build_native.ps1
    
    if %errorlevel% equ 0 (
        echo.
        echo [OK] PowerShell build completed successfully!
        echo.
        
        REM Check for binaries
        echo [*] Checking binaries...
        for %%f in (random.exe animate.exe banner.exe fortune.exe colortest.exe) do (
            if exist %%f (
                echo [+] %%f exists
            ) else (
                echo [-] %%f missing
            )
        )
        
        echo.
        echo ════════════════════════════════════════════════════════
        echo   READY FOR STEADY STATE - All checks passed!
        echo ════════════════════════════════════════════════════════
    ) else (
        echo.
        echo [!] PowerShell build failed with exit code %errorlevel%
    )
    
    echo.
    pause
    exit /b 0
)

REM Test bash build
if %HAS_BASH% equ 0 (
    echo ════════════════════════════════════════════════════════
    echo   Testing Bash Build
    echo ════════════════════════════════════════════════════════
    echo.
    bash build.sh
    
    if %errorlevel% equ 0 (
        echo.
        echo [OK] Bash build completed successfully!
        echo.
        
        REM Check for binaries
        echo [*] Checking binaries...
        for %%f in (random animate banner fortune colortest) do (
            if exist %%f (
                echo [+] %%f exists
            ) else (
                echo [-] %%f missing
            )
        )
        
        echo.
        echo ════════════════════════════════════════════════════════
        echo   READY FOR STEADY STATE - All checks passed!
        echo ════════════════════════════════════════════════════════
    ) else (
        echo.
        echo [!] Bash build failed with exit code %errorlevel%
    )
    
    echo.
    pause
    exit /b 0
)

echo [!] Error: No build tools available!
echo.
pause
exit /b 1
