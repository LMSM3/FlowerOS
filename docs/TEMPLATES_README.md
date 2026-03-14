# 🌸 FlowerOS MOTD Template System

**Beautiful, data-rich terminal greetings with GPU stats, weather, and market data**

---

## ✨ Features

- **🖥️ System Info**: Real-time CPU/GPU/Memory/Disk stats with visual progress bars
- **🌤️ Weather**: Live weather and 3-day forecast with emoji icons (auto-location or custom city)
- **📈 Stocks**: Track stocks & crypto with live prices and trend indicators

All scripts are **self-contained Python 3** with **no external dependencies** except standard library + `urllib`.

---

## 🚀 Quick Start

### Installation

Templates are already installed in:
```
/mnt/c/Users/Liam/Desktop/FlowerOS/motd/
├── sysinfo.py   # System stats
├── weather.py   # Weather forecast
└── stocks.py    # Market watch
```

### Integration (Already Done!)

Your `.bashrc` is configured to show **sysinfo** template on every new terminal.

---

## 📺 Usage

### Auto-Display on Shell Start

Every new terminal shows the configured template automatically.

### Manual Commands

```bash
# View templates
motd-sysinfo          # System information (CPU/GPU/RAM/Disk)
motd-weather          # Weather for your location
motd-weather NYC      # Weather for specific city
motd-stocks           # Market watch (default symbols)
motd-stocks TSLA NVDA # Custom symbols

# Manage stocks watchlist
motd-stocks add TSLA NVDA  # Add symbols
motd-stocks list           # Show watchlist

# Control auto-display
motd-off              # Disable auto-MOTD
motd-on               # Re-enable auto-MOTD

# Change default template
motd-set weather      # Set weather as default
motd-set sysinfo      # Set sysinfo as default (current)
motd-set stocks       # Set stocks as default
```

---

## 🎨 Template Details

### 1. System Information (`sysinfo.py`)

Displays:
- **CPU**: Model, cores, load average, usage %
- **GPU**: NVIDIA GPU (name, temperature, utilization, VRAM)
- **Memory**: Used/Total GB with visual bar
- **Disk**: Root filesystem usage
- **System**: Hostname, uptime

**Example Output:**
```
╔═══════════════════════════════════════════════════════════╗
║  🌸 FlowerOS System Information                      ║
╚═══════════════════════════════════════════════════════════╝

  System: DESKTOP-G0UNQ2K
  Uptime: 21h 42m
  Time:   2026-02-08 14:57:47

  CPU: 13th Gen Intel(R) Core(TM) i9-13900K
  Cores: 8 | Load: 0.52 0.48 0.45
  ████░░░░░░░░░░░░░░░░ 26.0%

  GPU: NVIDIA GeForce RTX 4070
  Usage: 12% | Temp: 52°C | VRAM: 3840/12282 MB

  Memory: 4.2 GB / 15.6 GB
  ████░░░░░░░░░░░░░░░░ 26.9%

  Disk: 67.2 GB / 1006.9 GB
  █░░░░░░░░░░░░░░░░░░░ 6.7%
```

**GPU Detection**: Automatically detects NVIDIA GPUs using `nvidia-smi`.

---

### 2. Weather (`weather.py`)

Uses **wttr.in** API (no key required).

**Features:**
- Auto-detects location via IP
- Current conditions with emoji icons
- Temperature (color-coded)
- Humidity, pressure, wind
- 3-day forecast

**Example:**
```bash
motd-weather        # Auto-detect location
motd-weather London # Specific city
motd-weather "New York"
```

**Output:**
```
╔═══════════════════════════════════════════════════════════╗
║  🌸 FlowerOS Weather Report                         ║
╚═══════════════════════════════════════════════════════════╝

  Location: Seattle, United States
  Updated: 2026-02-08 14:58

  Current: ☁️  Cloudy
  Temperature: 8°C (feels 6°C)
  Humidity: 82% | Pressure: 1015 hPa
  Wind: → 12 km/h W

  3-Day Forecast:

  Sat, Feb 08:
    🌧️  Light rain
    ↑ 10°C / ↓ 6°C

  Sun, Feb 09:
    ⛅ Partly cloudy
    ↑ 12°C / ↓ 7°C

  Mon, Feb 10:
    ☀️  Sunny
    ↑ 14°C / ↓ 8°C
```

---

### 3. Stocks/Crypto (`stocks.py`)

Uses **Yahoo Finance** API (no key required).

**Default Symbols**: AAPL, MSFT, GOOGL, BTC-USD, ETH-USD

**Features:**
- Real-time prices
- Daily change with color indicators (▲/▼)
- Customizable watchlist
- Supports stocks and crypto

**Usage:**
```bash
motd-stocks              # Show watchlist
motd-stocks TSLA NVDA    # Show specific symbols
motd-stocks add AMZN     # Add to watchlist
motd-stocks list         # View watchlist
```

**Example Output:**
```
╔═══════════════════════════════════════════════════════════╗
║  🌸 FlowerOS Market Watch                           ║
╚═══════════════════════════════════════════════════════════╝

  Updated: 2026-02-08 14:58:32

  AAPL (Apple Inc.)
  USD 175.42  ▲ 2.31 (1.33%)

  BTC-USD (Bitcoin USD)
  USD 98,234.50  ▼ 1,245.80 (1.25%)

  ETH-USD (Ethereum USD)
  USD 3,521.18  ▲ 89.32 (2.60%)
```

**Watchlist Config**: `~/.config/floweros/stocks.conf`

---

## ⚙️ Configuration

### Change Default Template

Edit in `.bashrc` or use command:

```bash
export FLOWEROS_MOTD_TEMPLATE="weather"  # weather, sysinfo, or stocks
# OR
motd-set weather
```

### Disable Auto-Display

```bash
# Temporarily
export FLOWEROS_NO_AUTO_MOTD=1

# Permanently
motd-off

# Re-enable
motd-on
```

### Customize Stocks Watchlist

Edit `~/.config/floweros/stocks.conf`:
```
# FlowerOS Stocks
AAPL
MSFT
GOOGL
TSLA
NVDA
BTC-USD
ETH-USD
```

Or use commands:
```bash
motd-stocks add AMZN META NFLX
```

---

## 🔧 Technical Details

### Code Injection Design

All three templates are:
- **Self-contained Python 3 scripts** (~100 lines each)
- **No pip dependencies** (only stdlib + urllib)
- **Minified** for efficiency
- **Embedded color codes** (ANSI 256-color support)

### API Usage

| Template | API | Key Required? | Rate Limit |
|----------|-----|---------------|------------|
| sysinfo | Local `/proc` | No | N/A |
| weather | wttr.in | No | ~1000/day |
| stocks | Yahoo Finance | No | Generous |

### Performance

- **Sysinfo**: <50ms (instant)
- **Weather**: ~500ms (network)
- **Stocks**: ~100ms per symbol (network)

---

## 🎯 Advanced Usage

### Time-Based Templates

Add to `.bashrc`:
```bash
# Morning: weather, Afternoon: sysinfo, Evening: stocks
hour=$(date +%H)
if [ $hour -lt 12 ]; then
    export FLOWEROS_MOTD_TEMPLATE="weather"
elif [ $hour -lt 18 ]; then
    export FLOWEROS_MOTD_TEMPLATE="sysinfo"
else
    export FLOWEROS_MOTD_TEMPLATE="stocks"
fi
```

### Random Template

```bash
templates=("sysinfo" "weather" "stocks")
export FLOWEROS_MOTD_TEMPLATE="${templates[$RANDOM % ${#templates[@]}]}"
```

### Combine Templates

```bash
motd-combined() {
    python3 /mnt/c/Users/Liam/Desktop/FlowerOS/motd/sysinfo.py
    echo ""
    python3 /mnt/c/Users/Liam/Desktop/FlowerOS/motd/weather.py
}
```

---

## 📁 File Structure

```
FlowerOS/motd/
├── sysinfo.py              # System stats template
├── weather.py              # Weather forecast template
├── stocks.py               # Market watch template
├── TEMPLATES_README.md     # This file
└── install-templates.sh    # Installer script

~/.config/floweros/
├── stocks.conf             # Stock watchlist
└── motd.conf               # MOTD configuration

~/.bashrc
└── FlowerOS MOTD Template System  # Integration code
```

---

## 🐛 Troubleshooting

### Python Not Found

Ensure Python 3 is installed:
```bash
python3 --version
```

### GPU Not Detected

Install `nvidia-smi` or GPU won't show (not an error).

### Weather/Stocks Not Loading

- Check internet connection
- APIs may have rate limits
- Try again in a few seconds

### Template Not Showing

```bash
# Check configuration
echo $FLOWEROS_MOTD_ENABLED    # Should be "1"
echo $FLOWEROS_MOTD_TEMPLATE   # Should be "sysinfo", "weather", or "stocks"

# Test manually
python3 /mnt/c/Users/Liam/Desktop/FlowerOS/motd/sysinfo.py
```

---

## 🌺 Philosophy

> **"Every terminal greeting should be breathtaking."**

FlowerOS MOTD templates combine:
- Real GPU utilization (NVIDIA)
- Live internet data (weather, stocks)
- Beautiful ANSI art
- Zero configuration (auto-location, sensible defaults)
- Code injection design (self-contained, embeddable)

This is **Tier 4 infrastructure** — persistent, beautiful, functional.

---

## 🎉 Enjoy Your Golden Terminal!

Every login is now a visual and informational experience. 🌸
