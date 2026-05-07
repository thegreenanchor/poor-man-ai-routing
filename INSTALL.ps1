# INSTALL.ps1 — Claude Routing System installer for Windows PowerShell
# Run from the repository root.

$ErrorActionPreference = 'Stop'

$Source = Join-Path $PSScriptRoot ".claude"
$Target = Join-Path $env:USERPROFILE ".claude"

Write-Host "==> Claude Routing System installer (Windows)" -ForegroundColor Cyan
Write-Host "Source: $Source"
Write-Host "Target: $Target"
Write-Host ""

# 1. Backup existing
if (Test-Path $Target) {
    $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Backup = "$Target.bak.$Stamp"
    Write-Host "==> Backing up existing $Target -> $Backup" -ForegroundColor Yellow
    Move-Item $Target $Backup
}

# 2. Copy
Write-Host "==> Copying config to $Target" -ForegroundColor Cyan
Copy-Item -Recurse $Source $Target

# 3. Verify wrappers
$Wrappers = @("cdx.sh","cdx.ps1","cx.sh","cx.ps1","gca.sh","gca.ps1","ai-mode.sh","ai-mode.ps1")
foreach ($w in $Wrappers) {
    $p = Join-Path $Target "bin/$w"
    if (-not (Test-Path $p)) {
        Write-Warning "Missing wrapper: $p"
    }
}

# 4. Add bin to PATH (User scope, persistent)
$BinPath = Join-Path $Target "bin"
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')

if ($UserPath -notlike "*$BinPath*") {
    Write-Host "==> Adding $BinPath to User PATH" -ForegroundColor Cyan
    $NewPath = if ($UserPath) { "$UserPath;$BinPath" } else { $BinPath }
    [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
    Write-Host "    (Open a new shell to pick up the PATH change.)"
} else {
    Write-Host "==> $BinPath already in User PATH" -ForegroundColor Green
}

# 5. Verify external tools
Write-Host ""
Write-Host "==> Checking external tools" -ForegroundColor Cyan

function Test-Cmd($name) {
    $found = Get-Command $name -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "  OK  $name -> $($found.Source)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  XX  $name not found" -ForegroundColor Red
        return $false
    }
}

$CodexOk = Test-Cmd "codex"
$GeminiOk = Test-Cmd "gemini"

if (-not $CodexOk) {
    Write-Host ""
    Write-Host "Install Codex CLI:" -ForegroundColor Yellow
    Write-Host "  npm install -g @openai/codex"
    Write-Host "  codex auth"
}

if (-not $GeminiOk) {
    Write-Host ""
    Write-Host "Install Gemini CLI:" -ForegroundColor Yellow
    Write-Host "  npm install -g @google/gemini-cli"
    Write-Host "  gemini auth"
}

# 6. Done
Write-Host ""
Write-Host "==> Install complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open a new terminal."
Write-Host "  2. Verify: 'ai-mode status', 'cx --help', 'cdx --help', and 'gca --help'"
Write-Host "  3. Open Claude Code in any project, or run 'ai-mode codex' then 'cx' during a Claude outage."
Write-Host ""
Write-Host "Docs: $Target\..\docs\PHASES.md"
