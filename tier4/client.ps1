# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS Tier 4 — PowerShell Client
#  Talks to broker via \\.\pipe\floweros\comm
#  This is how terminals join the FlowerOS substrate.
# ═══════════════════════════════════════════════════════════════════════════

$PIPE_NAME = "floweros\comm"

function Send-FlowerOS {
    param([string]$Json)

    $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $PIPE_NAME, [System.IO.Pipes.PipeDirection]::InOut)
    try {
        $pipe.Connect(3000)  # 3s timeout
        $writer = New-Object System.IO.StreamWriter($pipe)
        $reader = New-Object System.IO.StreamReader($pipe)

        $writer.WriteLine($Json)
        $writer.Flush()

        $pipe.WaitForPipeDrain()
        $response = $reader.ReadLine()
        return $response | ConvertFrom-Json
    }
    catch {
        Write-Error "Cannot reach FlowerOS broker. Is it running?"
        return $null
    }
    finally {
        $pipe.Dispose()
    }
}

# ─────────────────────────────────────────────────────────────────────────
#  Public Functions
# ─────────────────────────────────────────────────────────────────────────

function Test-FlowerOS {
    <# Ping the broker #>
    $r = Send-FlowerOS '{"op":"ping"}'
    if ($r -and $r.ok) {
        Write-Host "FlowerOS broker is alive." -ForegroundColor Green
        return $true
    }
    Write-Host "FlowerOS broker not responding." -ForegroundColor Red
    return $false
}

function Get-FlowerState {
    param([string]$Key)
    <# Read a value from the state store #>
    $json = @{ op = "get"; key = $Key } | ConvertTo-Json -Compress
    $r = Send-FlowerOS $json
    if ($r -and $r.ok) { return $r.value }
    return $null
}

function Set-FlowerState {
    param([string]$Key, $Value)
    <# Write a value to the state store #>
    $json = @{ op = "set"; key = $Key; value = $Value } | ConvertTo-Json -Compress
    $r = Send-FlowerOS $json
    return ($r -and $r.ok)
}

function Get-FlowerSnapshot {
    <# Get entire state #>
    $r = Send-FlowerOS '{"op":"snapshot"}'
    if ($r -and $r.ok) { return $r.state }
    return $null
}

function Update-FlowerDrives {
    <# Ask broker to re-detect drives #>
    $r = Send-FlowerOS '{"op":"refresh_drives"}'
    if ($r -and $r.ok) { return $r.drives }
    return $null
}

function Stop-FlowerBroker {
    <# Shut down the broker #>
    $r = Send-FlowerOS '{"op":"shutdown"}'
    if ($r -and $r.ok) {
        Write-Host "Broker shutting down." -ForegroundColor Yellow
    }
}

# ─────────────────────────────────────────────────────────────────────────
#  Convenience aliases (what you actually type)
# ─────────────────────────────────────────────────────────────────────────

function flower_user     { Get-FlowerState "USER" }
function flower_desktop  { Get-FlowerState "DESKTOP" }
function flower_hostname { Get-FlowerState "HOSTNAME" }
function flower_drives   { Get-FlowerState "DRIVE_LIST" }
function flower_version  { Get-FlowerState "FLOWEROS_VERSION" }
function flower_tier     { Get-FlowerState "TIER" }

function flower_status {
    <# Quick status check #>
    $snap = Get-FlowerSnapshot
    if (-not $snap) {
        Write-Host "Broker not running." -ForegroundColor Red
        return
    }
    Write-Host ""
    Write-Host "  FlowerOS Tier 4" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  User:     $($snap.system.USER)" -ForegroundColor White
    Write-Host "  Host:     $($snap.system.HOSTNAME)" -ForegroundColor White
    Write-Host "  Home:     $($snap.system.HOME)" -ForegroundColor White
    Write-Host "  Desktop:  $($snap.system.DESKTOP)" -ForegroundColor White
    Write-Host "  Version:  $($snap.floweros.FLOWEROS_VERSION)" -ForegroundColor Green
    Write-Host "  Tier:     $($snap.floweros.TIER)" -ForegroundColor Green
    Write-Host "  Theme:    $($snap.features.theme)" -ForegroundColor Magenta
    Write-Host "  GPU:      $($snap.features.gpu_enabled)" -ForegroundColor Yellow
    Write-Host "  Network:  $($snap.features.network_enabled)" -ForegroundColor Yellow
    Write-Host "  Drives:   $($snap.drives.DRIVE_LIST.Count) detected" -ForegroundColor White
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────────────
#  Auto-announce on load
# ─────────────────────────────────────────────────────────────────────────

Write-Host "  FlowerOS client loaded. Run " -NoNewline -ForegroundColor DarkGray
Write-Host "flower_status" -NoNewline -ForegroundColor Cyan
Write-Host " to check." -ForegroundColor DarkGray
