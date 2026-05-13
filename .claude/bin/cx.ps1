# cx.ps1 - Codex-led launcher for PowerShell

param(
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

if ($Args.Count -gt 0 -and $Args[0] -in @("-h", "--help", "help")) {
  Write-Host "Usage: cx [task]"
  Write-Host "Starts a Codex-led session. The entrypoint wins over the mode file."
  Write-Host "Codex still routes discovery to Gemini and judgment-heavy decisions to Claude."
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
$UserPrompt = if ($Args.Count -gt 0) { $Args -join " " } else { "Start a Codex-led interactive session in this workspace. Ask what to work on next if no task is already clear." }

$Wrapped = @"
$BasePrompt

GLOBAL ROUTING MODE: $Mode

SESSION ENTRYPOINT: Codex via cx
SESSION ROLE: Codex is the primary orchestrator/executor for this session. Use Gemini for discovery work. Escalate to Claude whenever judgment is needed, including strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish where quality matters, conflicts between sources/tool outputs, high-stakes judgment, and similar cases.

USER TASK:
$UserPrompt
"@

& codex --sandbox workspace-write --ask-for-approval never $Wrapped
