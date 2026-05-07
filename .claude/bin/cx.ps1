# cx.ps1 - Codex-primary launcher for PowerShell

param(
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

if ($Args.Count -gt 0 -and $Args[0] -in @("-h", "--help", "help")) {
  Write-Host "Usage: cx [task]"
  Write-Host "Starts Codex as the primary agent for Claude outage mode."
  Write-Host "Run 'ai-mode codex' first to switch the global routing mode."
  exit 0
}

$PromptFile = Join-Path (Split-Path $PSScriptRoot -Parent) "CODEX_PRIMARY.md"
if (-not (Test-Path -LiteralPath $PromptFile)) {
  Write-Error "Missing Codex primary prompt: $PromptFile"
  exit 1
}

if (-not (Test-Path "./.scratch")) {
  New-Item -ItemType Directory -Path "./.scratch" | Out-Null
}

$StateDir = if ($env:AI_ROUTING_HOME) { $env:AI_ROUTING_HOME } else { Join-Path $env:USERPROFILE ".claude\.ai-routing" }
$ModeFile = Join-Path $StateDir "mode"
$Mode = "claude"
if (Test-Path -LiteralPath $ModeFile) {
  $Mode = (Get-Content -LiteralPath $ModeFile -Raw).Trim().ToLowerInvariant()
}

$BasePrompt = Get-Content -LiteralPath $PromptFile -Raw
$UserPrompt = if ($Args.Count -gt 0) { $Args -join " " } else { "Start a Codex-primary interactive session in this workspace. Ask what to work on next if no task is already clear." }

$Wrapped = @"
$BasePrompt

GLOBAL ROUTING MODE: $Mode

USER TASK:
$UserPrompt
"@

& codex --sandbox workspace-write --ask-for-approval never $Wrapped
