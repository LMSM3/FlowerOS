#!/usr/bin/env bash
# FlowerOS System Installer
# Installs tree.sh as system-wide command in one line

install_system_wide() {
    local script_name="floweros-tree"
    
    # Try system-wide first (requires sudo)
    if sudo install -m 755 tree.sh "/usr/local/bin/$script_name" 2>/dev/null; then
        echo "✓ Installed to /usr/local/bin/$script_name (system-wide)"
        echo "  Run: $script_name"
        return 0
    fi
    
    # Fallback to user-local
    mkdir -p "$HOME/.local/bin"
    cp tree.sh "$HOME/.local/bin/$script_name"
    chmod +x "$HOME/.local/bin/$script_name"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    echo "✓ Installed to ~/.local/bin/$script_name (user-local)"
    echo "  Run: $script_name"
    echo "  (Reload bash: source ~/.bashrc)"
}

install_system_wide
