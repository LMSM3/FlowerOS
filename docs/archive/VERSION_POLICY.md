# FlowerOS Version Policy

## Version Branches

### 📗 v1.2.X - STABLE (Production Ready)

**Status:** ✅ Stable, Production-Ready  
**Use For:** Production environments, daily use, reliability  
**Priority:** Simple functions and core customizations

**Features:**
- ✅ Core ASCII functions (banner, animate, fortune)
- ✅ Visual output system
- ✅ Terminal enhancements
- ✅ User-level installation
- ✅ Well-tested and stable
- ✅ Documented and supported

**Installation:**
```bash
bash build.sh
bash install.sh
source ~/.bashrc
```

**Philosophy:**
> Keep it simple. Focus on what works. Prioritize user customization and core terminal experience.

---

### 📕 v1.3.X - EXPERIMENTAL (Development Branch)

**Status:** 🔴 EXPERIMENTAL, Development Only  
**Use For:** Testing, development, experimentation  
**Priority:** Advanced features, system integration, network capabilities

**Features:**
- 🔴 **System-level root integration** (permanent install)
- 🔴 **Network routing** (Rooter.hpp/Rooting.cpp) - EXPERIMENTAL
- 🔴 **Remote synchronization** - EXPERIMENTAL
- 🔴 **Advanced system takeover** - USE WITH CAUTION
- ✅ All v1.2.X features (stable core)

**Installation:**
```bash
bash build.sh
sudo bash install-permanent.sh  # ⚠️ PERMANENT!
source ~/.bashrc
```

**Visual Warning:**
All network and advanced features are **printed in RED** to indicate experimental status.

**Philosophy:**
> Push boundaries. Integrate deeply. Experiment with system-level features. NOT for production.

---

## 🎯 Which Version Should You Use?

### Use v1.2.X (STABLE) if you want:
- ✅ Reliable, tested terminal enhancements
- ✅ Simple installation and removal
- ✅ Production environment
- ✅ Daily driver setup
- ✅ Learning FlowerOS basics
- ✅ Customization and theming
- ✅ No system-level changes

### Use v1.3.X (EXPERIMENTAL) if you:
- 🔴 Want to experiment with system integration
- 🔴 Need permanent system-level installation
- 🔴 Are testing network/routing features
- 🔴 Understand the risks of root-level changes
- 🔴 Can handle experimental, unstable features
- 🔴 Are contributing to development
- 🔴 Have proper backups

---

## Feature Availability Matrix

| Feature | v1.2.X Stable | v1.3.X Experimental |
|---------|---------------|---------------------|
| **Core Functions** | | |
| flower_pick_ascii_line | ✅ | ✅ |
| flower_banner | ✅ | ✅ |
| flower_animate | ✅ | ✅ |
| flower_fortune | ✅ | ✅ |
| flower_colortest | ✅ | ✅ |
| flower_visual | ✅ | ✅ |
| **Installation** | | |
| User-level install | ✅ | ✅ |
| System-level install | ❌ | 🔴 |
| Easy removal | ✅ | ⚠️ Difficult |
| **Advanced Features** | | |
| Network routing | ❌ | 🔴 Experimental |
| Remote sync | ❌ | 🔴 Experimental |
| System integration | ❌ | 🔴 Experimental |
| Root-level takeover | ❌ | 🔴 Experimental |
| **System Commands** | | |
| floweros-info | ✅ | ✅ |
| floweros-status | ❌ | 🔴 |
| floweros-reload | ✅ | ✅ |
| flower_network_status | ❌ | 🔴 Experimental |
| flower_remote_sync | ❌ | 🔴 Experimental |
| flower_advanced_check | ❌ | 🔴 Experimental |
| **Support** | | |
| Production support | ✅ | ❌ |
| Documentation | ✅ Complete | ⚠️ In progress |
| Stability | ✅ Stable | 🔴 Unstable |
| Breaking changes | ❌ No | ⚠️ Possible |

---

## Color Coding System

FlowerOS uses color coding to indicate feature stability:

### In Stable Versions (v1.2.X):
- **Green text:** Standard, production-ready features
- **Yellow text:** Warnings or notices
- **No red:** All features are stable

### In Experimental Versions (v1.3.X):
- **Green text:** Stable features (inherited from v1.2.X)
- **Yellow text:** Warnings or cautions
- **🔴 Red text:** EXPERIMENTAL features (network, advanced, system-level)

**Rule:** If you see RED, it's experimental and NOT production-ready!

---

## Network & Advanced Features (v1.3.X Only)

### Rooting.cpp / Rooter.hpp

**Status:** 🔴 EXPERIMENTAL  
**Purpose:** Network routing capabilities  
**Availability:** v1.3.X only

These components enable:
- Network-based ASCII art synchronization
- Remote FlowerOS coordination
- Distributed terminal experiences
- Multi-system integration

**Why RED?**
- Not fully tested
- May have security implications
- Network dependencies
- Complex failure modes
- Not suitable for production

### flower_network_status()

**Status:** 🔴 EXPERIMENTAL  
**Purpose:** Check network routing status  

```bash
flower_network_status
# Output in RED if v1.3.X:
⚠️  EXPERIMENTAL: Network features only in v1.3.X
   This feature uses Rooter.hpp/Rooting.cpp (network routing)
   NOT SUPPORTED in stable releases
```

### flower_remote_sync()

**Status:** 🔴 EXPERIMENTAL  
**Purpose:** Synchronize FlowerOS data remotely

```bash
flower_remote_sync
# Output in RED if v1.3.X:
⚠️  EXPERIMENTAL: Remote sync only in v1.3.X
   Network routing required (Rooter.hpp)
   NOT SUPPORTED in stable releases
```

### flower_advanced_check()

**Status:** 🔴 EXPERIMENTAL  
**Purpose:** Display all advanced feature availability

```bash
flower_advanced_check
# Shows feature matrix in RED for experimental, GREEN for stable
```

---

## Development Philosophy

### v1.2.X Philosophy:
> "Simple functions and customizations are the priority."

We focus on:
- Core terminal experience
- Reliable, tested features
- Easy customization
- User-level, removable installation
- No system-level changes
- No network dependencies
- No experimental features

### v1.3.X Philosophy:
> "Push boundaries, integrate deeply, experiment boldly."

We explore:
- System-level integration
- Network capabilities
- Advanced routing
- Permanent installation
- Root-level changes
- Experimental features
- Breaking conventions

**But we clearly mark what's experimental!**

---

## Migration Path

### From v1.2.X → v1.3.X

**Warning:** This is a one-way street for permanent install!

```bash
# 1. Backup your system
sudo cp /etc/bash.bashrc /etc/bash.bashrc.backup
cp ~/.bashrc ~/.bashrc.backup

# 2. Remove v1.2.X
bash uninstall.sh

# 3. Install v1.3.X
bash build.sh
sudo bash install-permanent.sh

# 4. Test advanced features
flower_advanced_check
flower_network_status  # Will show RED warning

# 5. If issues, use emergency removal
sudo bash remove-permanent.sh

# 6. Restore v1.2.X if needed
# (restore backups and reinstall v1.2.X)
```

### From v1.3.X → v1.2.X (Downgrade)

```bash
# 1. Remove v1.3.X permanent install
sudo bash remove-permanent.sh

# 2. Verify removal
grep -i floweros /etc/bash.bashrc
# Should be empty

# 3. Install v1.2.X (stable)
# Check out v1.2.X branch or download release
bash build.sh
bash install.sh
source ~/.bashrc

# 4. Verify stable version
# No RED warnings should appear
```

---

## Testing Policy

### v1.2.X Testing:
- ✅ Extensive user testing
- ✅ Multiple environment verification
- ✅ Regression testing
- ✅ Documentation complete
- ✅ Release candidate process

### v1.3.X Testing:
- ⚠️ Alpha/Beta testing only
- ⚠️ Development environments only
- ⚠️ Known issues acceptable
- ⚠️ Documentation in progress
- ⚠️ No release candidates

---

## Support Policy

### v1.2.X Support:
- ✅ Full support
- ✅ Bug fixes prioritized
- ✅ Documentation maintained
- ✅ Community support
- ✅ Production issues addressed

### v1.3.X Support:
- ⚠️ Best-effort only
- ⚠️ Breaking changes expected
- ⚠️ Documentation incomplete
- ⚠️ Community testing appreciated
- ⚠️ Use at your own risk

---

## Version Identification

### Check Your Version:

```bash
# Show version
floweros-info

# Or check environment
echo $FLOWEROS_VERSION

# Check if experimental
flower_advanced_check
```

### Version String Format:

- `1.2.X` - Stable release (X = patch number)
- `1.3.X` - Experimental release (X = feature iteration)

### Visual Indicators:

**Stable (v1.2.X):**
```
FlowerOS v1.2.4
Status: Production Ready
✅ All features stable
```

**Experimental (v1.3.X):**
```
⚠️  WARNING: FlowerOS v1.3.0 Development Version
   Network and advanced features are EXPERIMENTAL
   Use stable v1.2.X for production environments
```

---

## Contribution Guidelines

### Contributing to v1.2.X:
- Focus on stability and reliability
- No new system-level features
- Bug fixes and refinements
- Documentation improvements
- User experience enhancements

### Contributing to v1.3.X:
- Experiment with new features
- System integration improvements
- Network capabilities
- Advanced routing features
- Breaking changes acceptable

---

## Roadmap

### v1.2.X (Stable):
- Continued maintenance
- Bug fixes
- Performance improvements
- Documentation updates
- Community features

### v1.3.X (Experimental):
- Network routing (Rooter.hpp/Rooting.cpp)
- Remote synchronization
- System-level integration
- Advanced configuration management
- Multi-user coordination

### v1.4.X (Future):
- Stabilize v1.3.X features that prove valuable
- Remove failed experiments
- New stable release with proven features

---

## Summary

| Aspect | v1.2.X | v1.3.X |
|--------|--------|--------|
| **Priority** | Simple functions & customizations | Advanced features & integration |
| **Status** | ✅ Stable | 🔴 Experimental |
| **Use Case** | Production | Development/Testing |
| **Installation** | User-level | System-level (permanent) |
| **Network Features** | ❌ No | 🔴 Yes (experimental) |
| **Color Coding** | Green/Yellow only | Green/Yellow/🔴 Red |
| **Support** | Full support | Best-effort |
| **Removal** | Easy | Difficult |
| **Documentation** | Complete | In progress |

---

**🌸 Remember:**
- **v1.2.X** = Your daily driver, production-ready, simple and stable
- **v1.3.X** = Your experimental playground, advanced features, not production-ready

**Every terminal session is a garden—choose the right seeds for your soil.** 🌸

---

**See also:**
- `README.md` - Main documentation
- `CHANGELOG_v1.2.4.md` - Stable release notes
- `CHANGELOG_v1.3.0.md` - Experimental release notes
- `PERMANENT_INSTALL.md` - v1.3.X installation guide
