# gca.ps1 — Gemini CLI wrapper for PowerShell

param(
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

$Mode = if ($env:CLAUDE_USAGE_MODE) { $env:CLAUDE_USAGE_MODE } else { "PEAK" }
if (Test-Path "./.scratch/.mode") { $Mode = (Get-Content "./.scratch/.mode" -Raw).Trim() }

$Date = Get-Date -Format "yyyy-MM-dd"

if ($Mode -eq "PEAK") {
  $CompressHint = "Top 5 sources max. Verbatim quotes max 20 words. SUMMARY max 8 bullets. Full dump goes to ./.scratch/research-{topic}-$Date.md."
} else {
  $CompressHint = "Top 8 sources. Verbatim quotes max 25 words. SUMMARY up to 12 bullets. Full dump still goes to ./.scratch/."
}

if (-not (Test-Path "./.scratch")) { New-Item -ItemType Directory -Path "./.scratch" | Out-Null }

if ($Args.Count -eq 0) {
  Write-Error "gca: missing prompt"
  Write-Host 'Usage: gca "<question>"'
  exit 1
}

$Prompt = $Args[0]
$Extra = if ($Args.Count -gt 1) { $Args[1..($Args.Count - 1)] } else { @() }

$Wrapped = @"
$CompressHint

MANDATORY OUTPUT FORMAT:
STATUS: done | blocked
SUMMARY:
  - bullet
SOURCES:
  - title - URL - date
EVIDENCE:
  - URL - verbatim quote
ARTIFACTS:
  - ./.scratch/research-...md
DECISIONS NEEDED:
  - question

TASK:
$Prompt
"@

# Pipe via stdin to avoid Windows command-line quoting issues
$Wrapped | & gemini --yolo --skip-trust @Extra
