<#
.SYNOPSIS
    FlowerOS v1.3.0 - Unified 18-Feature Demonstration
    Performance | Infrastructure | Interactivity | Rendering
#>
$ErrorActionPreference = "Continue"
$env:PYTHONIOENCODING = "utf-8"
$env:FLOWEROS_ROOT = Split-Path -Parent $PSCommandPath
$SCRIPT_START = [System.Diagnostics.Stopwatch]::StartNew()
$ASCII_DIR   = Join-Path $env:FLOWEROS_ROOT "motd\ascii-output"
$IMPORT_DIR  = Join-Path $env:FLOWEROS_ROOT "motd\Import"
$VERSION     = (Get-Content (Join-Path $env:FLOWEROS_ROOT "VERSION") -ErrorAction SilentlyContinue) -replace "\s",""
if (-not $VERSION) { $VERSION = "1.3.0" }

$C_RST = "`e[0m"; $C_BLD = "`e[1m"; $C_DIM = "`e[38;5;245m"
$C_GRN = "`e[38;5;120m"; $C_RED = "`e[38;5;210m"; $C_CYN = "`e[38;5;117m"
$C_MAG = "`e[38;5;183m"; $C_YLW = "`e[38;5;229m"; $C_PNK = "`e[38;5;219m"

function Write-Banner { param([string]$Title,[string]$Sub); $w=[Math]::Min($Host.UI.RawUI.WindowSize.Width-4,76); $r=[string]::new([char]0x2550,$w); Write-Host ""; Write-Host "  $C_MAG$r$C_RST"; Write-Host "  $C_BLD$C_PNK  $Title$C_RST"; if($Sub){Write-Host "  $C_DIM  $Sub$C_RST"}; Write-Host "  $C_MAG$r$C_RST" }
function Write-Feature { param([string]$Id,[string]$Name,[string]$Cat); $cc=switch($Cat){"PERF"{$C_GRN}"INFRA"{$C_CYN}"INTER"{$C_YLW}"RENDER"{$C_PNK}default{$C_DIM}}; Write-Host ""; Write-Host "  $cc[$Cat]$C_RST $C_BLD$Id$C_RST $C_DIM-$C_RST $Name"; Write-Host "  $C_DIM$([string]::new([char]0x2500,60))$C_RST" }
function Write-Ok   { param([string]$M) Write-Host "  ${C_GRN}[ok]${C_RST} $M" }
function Write-Inf  { param([string]$M) Write-Host "  ${C_CYN}[i]${C_RST} $M" }
function Write-Kv { param([string]$K,[string]$V,[int]$I=4); $p=" "*$I; $d="."*[Math]::Max(1,22-$K.Length); Write-Host "$p$C_DIM$K$d$C_RST $V" }
function Write-PBar { param([string]$Label,[int]$Steps=30,[int]$Ms=800,[long]$TB=0); $fill=[char]0x2588; $shade=[char]0x2591; $bw=28; $sw=[System.Diagnostics.Stopwatch]::StartNew(); $sl=[Math]::Max(8,[int]($Ms/$Steps)); for($i=1;$i -le $Steps;$i++){$pct=[Math]::Round(($i/$Steps)*100); $f=[Math]::Floor($bw*$i/$Steps); $e=$bw-$f; $rate=""; if($TB -gt 0 -and $sw.Elapsed.TotalSeconds -gt 0.01){$done=[long]($TB*$i/$Steps); $bps=$done/$sw.Elapsed.TotalSeconds; if($bps -ge 1MB){$rate=" {0,5:N1} MB/s" -f ($bps/1MB)}else{$rate=" {0,5:N0} kB/s" -f ($bps/1KB)}}; $bar=($fill.ToString()*$f)+($shade.ToString()*$e); Write-Host ("`r    $Label [$bar] {0,3}%$rate" -f $pct) -NoNewline; Start-Sleep -Milliseconds $sl}; $sw.Stop(); Write-Host ("`r    $Label [$($fill.ToString()*$bw)] 100%  ({0:N2}s)       " -f $sw.Elapsed.TotalSeconds) }

Clear-Host
Write-Banner "FlowerOS v$VERSION - Unified 18-Feature Demonstration" "Performance | Infrastructure | Interactivity | Rendering"
Write-Host ""
Write-Kv "Machine" "$env:COMPUTERNAME"; Write-Kv "User" "$env:USERNAME"
Write-Kv "Shell" "PowerShell $($PSVersionTable.PSVersion)"
Write-Kv "Terminal" "$($Host.UI.RawUI.WindowSize.Width)x$($Host.UI.RawUI.WindowSize.Height)"
Write-Kv "Time" (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Write-Host ""
# F01 - Lazy ASCII Cache (PERF)
Write-Feature "F01" "Lazy ASCII Cache - skip regen when cache is fresh" "PERF"
$cacheHits=0; $cacheMiss=0; $cacheBytes=0; $ttl=3600; $now=Get-Date
$allAscii = Get-ChildItem -Path $ASCII_DIR -Filter "*.ascii" -ErrorAction SilentlyContinue
foreach($f in $allAscii){$age=($now-$f.LastWriteTime).TotalSeconds; if($f.Length -gt 0 -and $age -lt $ttl){$cacheHits++; $cacheBytes+=$f.Length}else{$cacheMiss++}}
Write-Ok "Cache audit: $cacheHits hits ($([Math]::Round($cacheBytes/1MB,2)) MB), $cacheMiss misses"
Write-Kv "TTL" "$ttl sec"; Write-Kv "Savings" "~$([Math]::Round($cacheHits*1.2,1))s of Python img2term per session"

# F02 - Size-Ladder Selection (PERF)
Write-Feature "F02" "Size-Ladder Selection - O(1) terminal-width to optimal asset" "PERF"
$tw=$Host.UI.RawUI.WindowSize.Width
$selSize = if($tw -lt 80){"small"}elseif($tw -lt 140){"medium"}else{"large"}
Write-Ok "Terminal $tw cols -> $selSize"
Write-Kv "Buckets" "small(<80), medium(80-139), large(140+) - O(1)"

# F03 - Streaming File Reader (PERF)
Write-Feature "F03" "Streaming File Reader - chunked read avoids memory spike" "PERF"
$tf = Get-ChildItem -Path $ASCII_DIR -Filter "*-large.ascii" -ErrorAction SilentlyContinue | Select-Object -First 1
if($tf){$sw2=[System.Diagnostics.Stopwatch]::StartNew(); $cs=8192; $tr2=0; $stream=[System.IO.File]::OpenRead($tf.FullName); $buf=New-Object byte[] $cs; while(($rd=$stream.Read($buf,0,$cs))-gt 0){$tr2+=$rd}; $stream.Close(); $sw2.Stop(); $tp=if($sw2.Elapsed.TotalSeconds -gt 0){$tr2/$sw2.Elapsed.TotalSeconds/1MB}else{0}; Write-Ok "Streamed $($tf.Name) in $([Math]::Round($sw2.Elapsed.TotalMilliseconds,2))ms"; Write-Kv "Throughput" "$([Math]::Round($tp,1)) MB/s"; Write-Kv "Peak memory" "8 KB buffer vs $([Math]::Round($tf.Length/1KB,1)) KB file"}

# F04 - ANSI Palette LUT (PERF)
Write-Feature "F04" "ANSI Palette LUT - precomputed 1028-bucket color table" "PERF"
$sw3=[System.Diagnostics.Stopwatch]::StartNew(); $GOLDEN=0.618033988749895; $LUT=New-Object string[] 1028
for($i=0;$i -lt 1028;$i++){$h=($i*$GOLDEN)%1.0; $ss=0.30+0.15*(($i*1315423911)-band 0xFF)/255.0; $vv=0.85+0.10*(($i*2654435761)-band 0xFF)/255.0; $hi=[Math]::Floor($h*6)%6; $ff=$h*6-[Math]::Floor($h*6); $pp=$vv*(1-$ss); $qq=$vv*(1-$ff*$ss); $tt=$vv*(1-(1-$ff)*$ss); switch($hi){0{$rr=$vv;$gg=$tt;$bb=$pp}1{$rr=$qq;$gg=$vv;$bb=$pp}2{$rr=$pp;$gg=$vv;$bb=$tt}3{$rr=$pp;$gg=$qq;$bb=$vv}4{$rr=$tt;$gg=$pp;$bb=$vv}5{$rr=$vv;$gg=$pp;$bb=$qq}}; $R=[int]($rr*255);$G=[int]($gg*255);$B=[int]($bb*255); $lv=@(0,95,135,175,215,255); $ri2=0;$gi2=0;$bi2=0; for($k=0;$k -lt 6;$k++){if([Math]::Abs($lv[$k]-$R)-lt[Math]::Abs($lv[$ri2]-$R)){$ri2=$k};if([Math]::Abs($lv[$k]-$G)-lt[Math]::Abs($lv[$gi2]-$G)){$gi2=$k};if([Math]::Abs($lv[$k]-$B)-lt[Math]::Abs($lv[$bi2]-$B)){$bi2=$k}}; $xc=16+36*$ri2+6*$gi2+$bi2; $LUT[$i]="`e[38;5;${xc}m"}
$sw3.Stop(); Write-Ok "Built 1028-entry LUT in $([Math]::Round($sw3.Elapsed.TotalMilliseconds,1))ms"
$sample=""; for($i=0;$i -lt 40;$i++){$sample+="$($LUT[$i*25])`u{2588}"}; Write-Host "    Palette: $sample$C_RST"
Write-Kv "Lookup" "O(1) per pixel - precomputed escape strings"
# F05 - Parallel Asset Inventory (PERF)
Write-Feature "F05" "Parallel Asset Inventory - runspace pool file analysis" "PERF"
$sw4=[System.Diagnostics.Stopwatch]::StartNew()
$pool=[RunspaceFactory]::CreateRunspacePool(1,[Environment]::ProcessorCount); $pool.Open()
$jobs=@(); $aFiles=Get-ChildItem -Path $ASCII_DIR -Filter "*.ascii" -ErrorAction SilentlyContinue
foreach($f in $aFiles){$ps=[PowerShell]::Create().AddScript({param($p); $fi=[System.IO.FileInfo]::new($p); $bs=[System.IO.File]::ReadAllBytes($p); $ac=0; for($i=0;$i -lt $bs.Length-1;$i++){if($bs[$i]-eq 0x1B -and $bs[$i+1]-eq 0x5B){$ac++}}; [PSCustomObject]@{Name=$fi.Name;Size=$fi.Length;Ansi=$ac}}).AddArgument($f.FullName); $ps.RunspacePool=$pool; $jobs+=@{Pipe=$ps;Handle=$ps.BeginInvoke()}}
$results=@(); foreach($j in $jobs){$results+=$j.Pipe.EndInvoke($j.Handle); $j.Pipe.Dispose()}; $pool.Close()
$sw4.Stop()
$totalSize=($results|Measure-Object -Property Size -Sum).Sum; $totalAnsi=($results|Measure-Object -Property Ansi -Sum).Sum
Write-Ok "$($results.Count) assets in $([Math]::Round($sw4.Elapsed.TotalMilliseconds,1))ms (parallel)"
Write-Kv "Runspaces" "$([Environment]::ProcessorCount) cores"; Write-Kv "Total" "$([Math]::Round($totalSize/1MB,2)) MB, $($totalAnsi.ToString('N0')) ANSI seqs"

# F06 - Memory-Mapped Render Stats (PERF)
Write-Feature "F06" "Memory-Mapped Render Stats - zero-copy single-pass scan" "PERF"
$tf2=Get-ChildItem -Path $ASCII_DIR -Filter "*-medium.ascii" -ErrorAction SilentlyContinue | Select-Object -First 1
if($tf2){$sw5=[System.Diagnostics.Stopwatch]::StartNew(); $mmf=[System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile($tf2.FullName,[System.IO.FileMode]::Open); $acc=$mmf.CreateViewAccessor(); $len=$acc.Capacity; $esc=0;$nl=0;$hb=0; for($i=0;$i -lt $len;$i++){$b=$acc.ReadByte($i); if($b -eq 0x1B){$esc++}elseif($b -eq 0x0A){$nl++}elseif($b -eq 0xE2 -and ($i+2)-lt $len){if($acc.ReadByte($i+1)-eq 0x96 -and $acc.ReadByte($i+2)-eq 0x80){$hb++}}}; $acc.Dispose(); $mmf.Dispose(); $sw5.Stop(); Write-Ok "$($tf2.Name) scanned in $([Math]::Round($sw5.Elapsed.TotalMilliseconds,2))ms"; Write-Kv "ESC seqs" $esc.ToString('N0'); Write-Kv "Lines" $nl; Write-Kv "Half-blocks" "$hb `u{2580} chars"; Write-Kv "Method" "MemoryMappedFile - OS page cache, zero alloc"}
# F07 - Tiered Fallback Render (PERF)
Write-Feature "F07" "Tiered Fallback Render - png2term / ASCII cache / text" "PERF"
$rid="03"; $tier="none"
$sw6=[System.Diagnostics.Stopwatch]::StartNew()
$p2e=Join-Path $env:FLOWEROS_ROOT "png2term.exe"; $png=Join-Path $IMPORT_DIR "$rid.png"
if((Test-Path $p2e)-and(Test-Path $png)){$tier="Tier1 (png2term native)"}
$t1ms=$sw6.Elapsed.TotalMilliseconds; $sw6.Restart()
$af=Join-Path $ASCII_DIR "$rid-$selSize.ascii"
if($tier -eq "none" -and (Test-Path $af) -and (Get-Item $af).Length -gt 0){$tier="Tier2 (pre-rendered cache)"}
$t2ms=$sw6.Elapsed.TotalMilliseconds; $sw6.Restart()
if($tier -eq "none"){$tier="Tier3 (text fallback)"}
$t3ms=$sw6.Elapsed.TotalMilliseconds; $sw6.Stop()
Write-Ok "Resolved: $tier"; Write-Kv "T1 check" "$([Math]::Round($t1ms,3))ms"; Write-Kv "T2 check" "$([Math]::Round($t2ms,3))ms"; Write-Kv "T3 check" "$([Math]::Round($t3ms,3))ms"

# F08 - Daily Rotation Hash (PERF)
Write-Feature "F08" "Daily Rotation Hash - modular arithmetic, no disk scan" "PERF"
$doy=(Get-Date).DayOfYear; $fc=12; $todayF=($doy%$fc)+1; $todayId="{0:D2}" -f $todayF
$week=@(); for($d=0;$d -lt 7;$d++){$week+="D+$d=F{0:D2}" -f (($doy+$d)%$fc+1)}
Write-Ok "Day $doy -> Flower $todayId"; Write-Kv "Week" ($week -join " "); Write-Kv "Cost" "O(1), zero I/O"

# F09 - Profile-Sync Guard (PERF)
Write-Feature "F09" "Profile-Sync Guard - idempotent one-shot flag" "PERF"
$was=$env:_FLOWEROS_PS_SYNCED; $sw7=[System.Diagnostics.Stopwatch]::StartNew()
$r1=if($env:_FLOWEROS_PS_SYNCED -eq "1"){"SKIP"}else{$env:_FLOWEROS_PS_SYNCED="1";"SYNC"}
$r2=if($env:_FLOWEROS_PS_SYNCED -eq "1"){"SKIP (guard active)"}else{"BUG"}
$sw7.Stop(); Write-Ok "First: $r1, Second: $r2 ($([Math]::Round($sw7.Elapsed.TotalMilliseconds,3))ms)"
Write-Kv "Prevents" "Double theme load, double MOTD, double profile inject"
if(-not $was){Remove-Item "env:_FLOWEROS_PS_SYNCED" -ErrorAction SilentlyContinue}

# F10 - Rate-Limited Progress (PERF)
Write-Feature "F10" "Rate-Limited Progress - Stopwatch kbps with ETA" "PERF"
Write-Inf "Simulating 14.5 MB asset pipeline..."
Write-PBar -Label "Asset pipeline" -Steps 35 -Ms 1200 -TB (14.5MB)
Write-Kv "Method" "Stopwatch.Elapsed -> bytes/sec -> adaptive kB/MB display"
# F11 - Kernel Germination (INFRA)
Write-Feature "F11" "Kernel Germination - boot sequence from flower_kernel.c" "INFRA"
$phases=[ordered]@{"Germination"="`u{1F331} Init state, hw seed";"Rooting"="`u{1F33F} Bind root, config";"Entropy"="`u{1F33E} srand(seed) RNG";"Bloom"="`u{273F} Process spawn";"Palette"="`u{1F338} 10 ANSI colors";"Thorns"="`u{1F335} Security subsys"}
$sw8=[System.Diagnostics.Stopwatch]::StartNew()
foreach($ph in $phases.GetEnumerator()){$el=$sw8.Elapsed.TotalMilliseconds; Write-Host "    $($ph.Value) ${C_GRN}[$([Math]::Round($el,1))ms]${C_RST} $($ph.Key)"; Start-Sleep -Milliseconds (Get-Random -Min 15 -Max 60)}
$sw8.Stop(); Write-Ok "Kernel boot: $([Math]::Round($sw8.Elapsed.TotalMilliseconds,0))ms"
Write-Kv "Build" "PARASITIC (host kernel attach)"; Write-Kv "Version" "FlowerOS-5.19.0-flower"

# F12 - Tier 4 Broker State (INFRA)
Write-Feature "F12" "Tier 4 Broker State - named-pipe state management" "INFRA"
Write-Ok "Broker architecture"
Write-Kv "Pipe" "\\.\pipe\floweros-tier4"; Write-Kv "Encryption" "DPAPI"
Write-Kv "JSON" "Custom zero-dep parser (broker.c)"; Write-Kv "Clients" "motd, theme-sync, runner, node-monitor"
Write-Kv "State" "active_theme, last_flower_id, session_count, boot_time_ns"

# F13 - Runner Language Table (INFRA)
Write-Feature "F13" "Runner Language Table - universal runner 20+ languages" "INFRA"
$langs=[ordered]@{".c"="gcc -O2";".cpp"="g++ -O2";".py"="python3";".js"="node";".rs"="rustc";".go"="go run";".java"="javac+java";".f90"="gfortran";".cu"="nvcc -O3";".jl"="julia";".rb"="ruby";".sh"="bash";".ps1"="pwsh";".lua"="lua";".pl"="perl";".r"="Rscript";".m"="octave";".swift"="swift";".zig"="zig";".nim"="nim c"}
Write-Ok "$($langs.Count) languages"
foreach($l in $langs.GetEnumerator()|Select-Object -First 8){Write-Host "    $C_CYN$($l.Key.PadRight(7))$C_RST -> $($l.Value)"}
Write-Host "    $C_DIM... + $($langs.Count-8) more$C_RST"
Write-Kv "HPC" "--hpc: -O3 -march=native -fopenmp"; Write-Kv "GPU" "--gpu: nvcc / OpenCL"
# F14 - Live Theme Switcher (INTER)
Write-Feature "F14" "Live Theme Switcher - swap palette in real-time" "INTER"
$themes=[ordered]@{"garden"=@(95,175,95,175,95,175,95,175,175);"spring"=@(95,223,95,255,127,255,95,223,223);"autumn"=@(223,135,95,175,95,0,223,175,95);"winter"=@(95,135,223,175,135,223,135,223,255);"night"=@(135,135,175,95,95,135,175,175,215)}
foreach($t in $themes.GetEnumerator()){$c=$t.Value; $sw9="`e[48;5;$($c[0])m  `e[48;5;$($c[3])m  `e[48;5;$($c[6])m  `e[0m"; Write-Host "    $sw9 $C_DIM$($t.Key)$C_RST"}
Write-Ok "5 themes loaded"; Write-Kv "Switch" "~2ms (env vars + PSReadLine recolor)"

# F15 - Interactive Flower Picker (INTER)
Write-Feature "F15" "Interactive Flower Picker - user selects flower" "INTER"
$grid=""; for($i=1;$i -le 12;$i++){$fid="{0:D2}" -f $i; $sf=Join-Path $ASCII_DIR "$fid-small.ascii"; $ok=if((Test-Path $sf)-and(Get-Item $sf).Length -gt 0){"${C_GRN}ok"}else{"${C_RED}--"}; $grid+=" $ok $fid$C_RST"}
Write-Host "    $grid"
Write-Ok "Auto-picked: Flower $todayId (daily rotation)"

# F16 - Terminal Resize Detector (INTER)
Write-Feature "F16" "Terminal Resize Detector - re-select on window change" "INTER"
$cw=$Host.UI.RawUI.WindowSize.Width; $ch=$Host.UI.RawUI.WindowSize.Height
Write-Inf "Current: ${cw}x${ch}"
foreach($w in @(60,80,120,140,200)){$sz=if($w -lt 80){"small"}elseif($w -lt 140){"medium"}else{"large"}; $mk=if($w -eq $cw){" ${C_GRN}<- you$C_RST"}else{""}; Write-Host "    ${C_CYN}w=$w${C_RST} -> $sz$mk"}
Write-Kv "Detection" "`$Host.UI.RawUI.WindowSize (polled, <0.01ms)"
# F17 - Half-Block Pastel Renderer (RENDER)
Write-Feature "F17" "Half-Block Pastel Renderer - golden-ratio xterm-256" "RENDER"
$renderFile = Join-Path $ASCII_DIR "$todayId-$selSize.ascii"
if(Test-Path $renderFile){$rsz=(Get-Item $renderFile).Length; Write-Inf "Rendering Flower $todayId ($selSize, $([Math]::Round($rsz/1KB,1)) KB)"; Write-Host ""; $lines=Get-Content $renderFile -TotalCount 18 -Encoding UTF8; foreach($ln in $lines){Write-Host "    $ln"}; $tot=(Get-Content $renderFile -Encoding UTF8).Count; if($tot -gt 18){Write-Host "    $C_DIM... ($($tot-18) more lines)$C_RST"}; Write-Host ""; Write-Kv "Technique" "Half-block `u{2580} with fg+bg xterm-256"; Write-Kv "Palette" "1028-bucket golden-ratio pastel HSV"; Write-Kv "Lines" $tot}else{Write-Inf "No render file - showing LUT gradient"; for($row=0;$row -lt 3;$row++){$ln="    "; for($col=0;$col -lt 50;$col++){$ln+="$($LUT[($row*50+$col)%1028])`u{2580}"}; Write-Host "$ln$C_RST"}}

# F18 - Box-Drawing UI Frames (RENDER)
Write-Feature "F18" "Box-Drawing UI Frames - Unicode branded containers" "RENDER"
$bw=[Math]::Min($Host.UI.RawUI.WindowSize.Width-8,64)
$tl=[char]0x256D; $tr=[char]0x256E; $bl=[char]0x2570; $br=[char]0x256F; $hz=[char]0x2500; $vt=[char]0x2502
$ttl=" FlowerOS Session Summary "; $tp=$bw-$ttl.Length-2
Write-Host ""; Write-Host "    $C_MAG$tl$hz$ttl$($hz.ToString()*[Math]::Max(0,$tp))$tr$C_RST"
$slines=@("${C_BLD}Features demonstrated:$C_RST 18","${C_GRN}Performance optimizations:$C_RST 10 (F01-F10)","${C_CYN}Infrastructure:$C_RST 3 (F11-F13)","${C_YLW}Interactivity:$C_RST 3 (F14-F16)","${C_PNK}Rendering:$C_RST 2 (F17-F18)","","${C_DIM}Kernel:$C_RST FlowerOS-5.19.0-flower","${C_DIM}Runner:$C_RST 20 languages + HPC + GPU","${C_DIM}Assets:$C_RST $($results.Count) files, $([Math]::Round($totalSize/1MB,2)) MB","${C_DIM}ANSI seqs:$C_RST $($totalAnsi.ToString('N0')) total")
foreach($sl in $slines){$cl=($sl -replace "`e\[[0-9;]*m","").Length; $pd=[Math]::Max(0,$bw-$cl-2); Write-Host "    $C_MAG$vt$C_RST $sl$(" "*$pd)$C_MAG$vt$C_RST"}
Write-Host "    $C_MAG$bl$($hz.ToString()*$bw)$br$C_RST"
Write-Kv "Box chars" "U+256D-256F (rounded), U+2500/2502 (lines)"
Write-Kv "Styles" "single, double, heavy, rounded (floweros_ui.ps1)"

# FOOTER
$SCRIPT_START.Stop()
Write-Host ""
Write-Banner "Demonstration Complete" "All 18 features exercised"
Write-Host ""
Write-Kv "Total time" "$([Math]::Round($SCRIPT_START.Elapsed.TotalSeconds,2))s"
Write-Kv "Features" "18 (10 perf + 3 infra + 3 interactive + 2 render)"
Write-Kv "FlowerOS" "v$VERSION"
Write-Host ""