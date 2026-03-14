# FlowerOS v1.1 Directory Structure

```
FlowerOS/
├── VERSION (1.1.0)
│
├── features/v1.1/          # New features (v1.0 core untouched)
│   └── theming/
│       ├── engine.ps1      # PowerShell theme engine
│       ├── engine.sh       # Bash/WSL theme engine
│       ├── themes/         # Theme definitions
│       ├── apply-theme.ps1 # Theme installer
│       └── apply-theme.sh  # Theme installer (WSL)
│
├── test/                   # Testing infrastructure
│   ├── run-tests.sh        # Test runner
│   ├── test-themes.ps1     # Theme validation
│   └── test-core.sh        # Core functionality tests
│
├── temp/                   # Temporary files
│   └── .gitkeep
│
└── [v1.0 core unchanged]
    ├── lib/
    ├── *.c
    ├── build.sh
    └── ...
```

## Design Principles

1. **Non-Invasive**: v1.0 code remains untouched
2. **Modular**: Features in separate directories
3. **Testable**: Dedicated test infrastructure
4. **Clean**: Temp files isolated
