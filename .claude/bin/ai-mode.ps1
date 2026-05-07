# ai-mode.ps1 - Global routing mode switcher for PowerShell

param(
  [Parameter(Position=0)]
  [string]$Command = "status",

  [switch]$Help
)

$ErrorActionPreference = 'Stop'

$StateDir = if ($env:AI_ROUTING_HOME) { $env:AI_ROUTING_HOME } else { Join-Path $env:USERPROFILE ".claude\.ai-routing" }
$ModeFile = Join-Path $StateDir "mode"

function Ensure-StateDir {
  if (-not (Test-Path -LiteralPath $StateDir)) {
    New-Item -ItemType Directory -Path $StateDir | Out-Null
  }
}

function Read-Mode {
  if (Test-Path -LiteralPath $ModeFile) {
    return (Get-Content -LiteralPath $ModeFile -Raw).Trim().ToLowerInvariant()
  }
  return "claude"
}

if ($Help) {
  $Command = "help"
}

switch ($Command.ToLowerInvariant()) {
  "claude" {
    Ensure-StateDir
    Set-Content -LiteralPath $ModeFile -Value "claude" -NoNewline
    Write-Host "AI routing mode: claude"
    Write-Host "Use Claude Code normally. Codex remains available through cdx/cx."
  }
  "codex" {
    Ensure-StateDir
    Set-Content -LiteralPath $ModeFile -Value "codex" -NoNewline
    Write-Host "AI routing mode: codex"
    Write-Host "Start Codex-primary work with: cx"
  }
  "status" {
    $Mode = Read-Mode
    Write-Host "AI routing mode: $Mode"
    Write-Host "Mode file: $ModeFile"
  }
  { $_ -in @("-h", "--help", "help") } {
    Write-Host "Usage: ai-mode [status|codex|claude]"
    Write-Host "  ai-mode codex   Switch globally to Codex-primary outage mode"
    Write-Host "  ai-mode claude  Switch globally back to Claude orchestration"
    Write-Host "  ai-mode status  Show the current mode"
  }
  default {
    Write-Error "Unknown mode command: $Command"
    Write-Host "Usage: ai-mode [status|codex|claude]"
    exit 1
  }
}
