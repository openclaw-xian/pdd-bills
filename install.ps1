# install.ps1 — 把 pdd-bills skill 安装到 DSH 的 skills 目录（默认建目录联接，单份真实文件）
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Copy          # 复制而不是 junction
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target "D:\.agents\skills\pdd-bills"
#
# 安全行为：
#   - 目标已存在且是指向本目录的 junction → 直接提示“已安装”
#   - 目标已存在但不是 junction → 默认停止；加 -Force 会把它改名成 .bak-<时间戳> 再安装
#   - 不会删除/覆盖任何文件（除上述改名备份）

param(
  [string]$Target = (Join-Path $env:USERPROFILE ".agents\skills\pdd-bills"),
  [switch]$Copy,
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$Self = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Fail($msg) { Write-Host "[x] $msg" -ForegroundColor Red; exit 1 }
function Ok($msg) { Write-Host "[ok] $msg" -ForegroundColor Green }
function Info($msg) { Write-Host "[..] $msg" -ForegroundColor Cyan }

Write-Host "pdd-bills install"
Write-Host "  source : $Self"
Write-Host "  target : $Target"
Write-Host "  mode   : $(if ($Copy) { 'copy' } else { 'junction' })"

# 0) 源检查
foreach ($f in @("SKILL.md", "batch-run.mjs", "worker-export.mjs")) {
  if (-not (Test-Path (Join-Path $Self $f))) { Fail "source incomplete: missing $f" }
}

# 1) 环境检查（只提示，不阻塞安装）
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) { Info "node: $($node.Source)" } else { Write-Host "[!] node not found - 安装 skill 不需要，但运行需要 Node.js" -ForegroundColor Yellow }

$egoCandidates = @(
  (Join-Path $env:USERPROFILE ".local\share\ego\active_version_dir\ego-browser.exe"),
  (Join-Path $env:USERPROFILE ".local\bin\ego-browser.exe")
)
$ego = $egoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ego) {
  $ego = (Get-Command ego-browser -ErrorAction SilentlyContinue)?.Source
}
if ($ego) { Info "ego-browser: $ego" } else { Write-Host "[!] ego-browser not found - 运行前需安装并登录各店 profile" -ForegroundColor Yellow }

# 2) 目标状态
$parent = Split-Path -Parent $Target
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null; Info "created $parent" }

if (Test-Path $Target) {
  $item = Get-Item $Target -Force
  if ($item.LinkType -eq "Junction" -and ($item.Target -join ",") -eq $Self) {
    Ok "already installed (junction -> $Self)"
    exit 0
  }
  if (-not $Force) {
    Fail "target already exists and is not this skill's junction: $Target`n    如果用 -Force，会先改名成 .bak-<时间戳> 再安装。"
  }
  $bak = "$Target.bak-" + (Get-Date -Format "yyyyMMddHHmmss")
  Rename-Item $Target $bak
  Info "backup: $bak"
}

# 3) 安装
if ($Copy) {
  Copy-Item $Self $Target -Recurse
  Ok "copied to $Target"
} else {
  $r = cmd /c "mklink /J `"$Target`" `"$Self`"" 2>&1
  if ($LASTEXITCODE -ne 0) { Fail "mklink failed: $r`n    改用 -Copy 复制安装。" }
  Ok "junction created: $Target -> $Self"
}

# 4) 后续提示
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  1. 准备账单根目录（默认 D:/对账账单，非 C 盘；也可在配置里 root 指定）"
Write-Host "  2. 店铺清单 _stores.json 可不提供（doctor/首次运行会自动扫描 ego profiles 生成）"
Write-Host "  3. 自检：node `"$Target\batch-run.mjs`" <doctor-config.json>   （config 里写 `"doctor\": true`）"
Write-Host "  4. 正式跑：node `"$Target\batch-run.mjs`" <config.json>"
Write-Host "  详见 $Target\SKILL.md 和 references/。"
