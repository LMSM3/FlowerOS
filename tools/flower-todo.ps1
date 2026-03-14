# ═══════════════════════════════════════════════════════════════════════════
#  FlowerOS To-Do Notepad  🌸  (PowerShell)
#  Pastel-themed task manager — state in %LOCALAPPDATA%\FlowerOS\state\
#  Part of FlowerOS Tier 4 — every petal accounted for.
# ═══════════════════════════════════════════════════════════════════════════

param(
    [Parameter(Position = 0)]
    [ValidateSet("add", "list", "done", "undo", "rm", "clear", "help")]
    [string]$Command = "list",

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Args
)

# ── Import helpers if available ──
$helpersPath = Join-Path $PSScriptRoot "..\lib\helpers.ps1"
if (Test-Path $helpersPath) { . $helpersPath }

# ── ANSI helpers ──
function Esc([string]$code) { return "$([char]27)[$code" }
$C_DIM = "38;5;245m"; $C_ACC = "38;5;117m"; $C_PNK = "38;5;219m"
$C_GRN = "38;5;120m"; $C_RED = "38;5;210m"; $C_YLW = "38;5;229m"
$RST = "0m"

function fg($c)  { return Esc $c }
function rs()    { return Esc $RST }

# ── State directory (Tier 4: %LOCALAPPDATA%\FlowerOS\state\) ──
$StateDir = Join-Path $env:LOCALAPPDATA "FlowerOS\state"
$TodoFile = Join-Path $StateDir "todo.json"

if (!(Test-Path $StateDir)) { New-Item -ItemType Directory -Force -Path $StateDir | Out-Null }
if (!(Test-Path $TodoFile))  { Set-Content -Path $TodoFile -Value "[]" -NoNewline }

# ── Load / Save ──
function Load-Tasks {
    $raw = Get-Content -Path $TodoFile -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $tasks = $raw | ConvertFrom-Json
    if ($null -eq $tasks) { return @() }
    # Ensure array
    if ($tasks -isnot [System.Array]) { $tasks = @($tasks) }
    return $tasks
}

function Save-Tasks($tasks) {
    if ($tasks.Count -eq 0) {
        Set-Content -Path $TodoFile -Value "[]" -NoNewline
    } else {
        $tasks | ConvertTo-Json -Depth 4 | Set-Content -Path $TodoFile
    }
}

function Get-NextId($tasks) {
    if ($tasks.Count -eq 0) { return 1 }
    return ($tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
}

# ═══════════════════════════════════════════════════════════════════════════
#  Commands
# ═══════════════════════════════════════════════════════════════════════════

function Invoke-Add {
    $text = ($Args -join " ").Trim()
    if ([string]::IsNullOrEmpty($text)) {
        Write-Host "$(fg $C_RED)✗$(rs) Usage: flower-todo add <task text>"
        return
    }
    $tasks = Load-Tasks
    $id = Get-NextId $tasks
    $entry = [PSCustomObject]@{
        id      = $id
        text    = $text
        done    = $false
        created = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
    $tasks = @($tasks) + @($entry)
    Save-Tasks $tasks
    Write-Host "$(fg $C_GRN)✓$(rs) Added #$($id): $(fg $C_ACC)$text$(rs)"
}

function Invoke-List {
    $tasks = Load-Tasks
    if ($tasks.Count -eq 0) {
        Write-Host ""
        Write-Host "  $(fg $C_DIM)🌸 No tasks yet. Add one with:$(rs) $(fg $C_YLW)flower-todo add <task>$(rs)"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  $(fg $C_PNK)🌸 FlowerOS To-Do$(rs)  $(fg $C_DIM)($($tasks.Count) tasks)$(rs)"
    Write-Host "  $(fg $C_DIM)─────────────────────────────────────$(rs)"

    foreach ($t in $tasks) {
        $idStr = ("#" + $t.id).PadRight(4)
        if ($t.done) {
            Write-Host "  $(fg $C_DIM) ✔  $idStr $($t.text)$(rs)"
        } else {
            Write-Host "  $(fg $C_GRN) ○$(rs)  $(fg $C_ACC)$idStr$(rs) $($t.text)"
        }
    }

    Write-Host "  $(fg $C_DIM)─────────────────────────────────────$(rs)"
    Write-Host ""
}

function Invoke-Done {
    if ($Args.Count -eq 0) { Write-Host "$(fg $C_RED)✗$(rs) Usage: flower-todo done <id>"; return }
    $id = [int]$Args[0]
    $tasks = Load-Tasks
    $found = $false
    foreach ($t in $tasks) {
        if ($t.id -eq $id) { $t.done = $true; $found = $true }
    }
    if (!$found) { Write-Host "$(fg $C_RED)✗$(rs) Task #$id not found."; return }
    Save-Tasks $tasks
    Write-Host "$(fg $C_GRN)✔$(rs) Task #$id marked done."
}

function Invoke-Undo {
    if ($Args.Count -eq 0) { Write-Host "$(fg $C_RED)✗$(rs) Usage: flower-todo undo <id>"; return }
    $id = [int]$Args[0]
    $tasks = Load-Tasks
    $found = $false
    foreach ($t in $tasks) {
        if ($t.id -eq $id) { $t.done = $false; $found = $true }
    }
    if (!$found) { Write-Host "$(fg $C_RED)✗$(rs) Task #$id not found."; return }
    Save-Tasks $tasks
    Write-Host "$(fg $C_YLW)○$(rs) Task #$id reopened."
}

function Invoke-Remove {
    if ($Args.Count -eq 0) { Write-Host "$(fg $C_RED)✗$(rs) Usage: flower-todo rm <id>"; return }
    $id = [int]$Args[0]
    $tasks = Load-Tasks
    $newTasks = @($tasks | Where-Object { $_.id -ne $id })
    if ($newTasks.Count -eq $tasks.Count) { Write-Host "$(fg $C_RED)✗$(rs) Task #$id not found."; return }
    Save-Tasks $newTasks
    Write-Host "$(fg $C_RED)✗$(rs) Task #$id removed."
}

function Invoke-Clear {
    Save-Tasks @()
    Write-Host "$(fg $C_GRN)✓$(rs) All tasks cleared."
}

function Invoke-Help {
    Write-Host ""
    Write-Host "  $(fg $C_PNK)🌸 FlowerOS To-Do Notepad$(rs)"
    Write-Host "  $(fg $C_DIM)─────────────────────────────────────$(rs)"
    Write-Host "  $(fg $C_ACC)add$(rs) <text>     Add a new task"
    Write-Host "  $(fg $C_ACC)list$(rs)           Show all tasks"
    Write-Host "  $(fg $C_ACC)done$(rs) <id>      Mark task complete"
    Write-Host "  $(fg $C_ACC)undo$(rs) <id>      Reopen a task"
    Write-Host "  $(fg $C_ACC)rm$(rs) <id>        Remove a task"
    Write-Host "  $(fg $C_ACC)clear$(rs)          Remove all tasks"
    Write-Host "  $(fg $C_ACC)help$(rs)           Show this help"
    Write-Host "  $(fg $C_DIM)─────────────────────────────────────$(rs)"
    Write-Host "  Data: $(fg $C_DIM)$TodoFile$(rs)"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════
#  Dispatch
# ═══════════════════════════════════════════════════════════════════════════

switch ($Command) {
    "add"   { Invoke-Add }
    "list"  { Invoke-List }
    "done"  { Invoke-Done }
    "undo"  { Invoke-Undo }
    "rm"    { Invoke-Remove }
    "clear" { Invoke-Clear }
    "help"  { Invoke-Help }
    default { Invoke-List }
}
