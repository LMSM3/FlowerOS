# FlowerOS - Line Ending Fix

If you get errors like:
```
build-motd.sh: line 4: $'\r': command not found
```

This is a **line ending issue** (CRLF vs LF).

## Quick Fix

```bash
# Install dos2unix (if needed)
sudo apt-get install dos2unix

# Fix all scripts
find . -name "*.sh" -type f -exec dos2unix {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;

# Or without dos2unix:
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
find . -name "*.sh" -type f -exec chmod +x {} \;
```

## Prevent Future Issues

```bash
# Configure Git
git config core.autocrlf input

# Or create .gitattributes
echo "*.sh text eol=lf" >> .gitattributes
```

Done! 🌸
