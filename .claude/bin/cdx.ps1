# cdx.ps1 — Codex CLI wrapper for PowerShell
# Mirror of cdx.sh for native Windows shells.

param(
  [Parameter(Position=0, ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

$Mode = if ($env:CLAUDE_USAGE_MODE) { $env:CLAUDE_USAGE_MODE } else { "PEAK" }
if (Test-Path "./.scratch/.mode") { $Mode = (Get-Content "./.scratch/.mode" -Raw).Trim() }

if ($Mode -eq "PEAK") {
  $CompressHint = "Return STATUS + SUMMARY (max 8 bullets) + EVIDENCE (verbatim slices, max 10 lines each) + ARTIFACTS only. No prose dumps. Heavy output goes to ./.scratch/."
} else {
  $CompressHint = "Return STATUS + SUMMARY (up to 12 bullets) + EVIDENCE + ARTIFACTS. Slices may be longer where decisions need cross-section context."
}

if (-not (Test-Path "./.scratch")) { New-Item -ItemType Directory -Path "./.scratch" | Out-Null }

if ($Args.Count -eq 0) {
  Write-Error "cdx: missing prompt"
  Write-Host 'Usage: cdx "<scoped task>"'
  exit 1
}

$Prompt = $Args[0]
$Extra = if ($Args.Count -gt 1) { $Args[1..($Args.Count - 1)] } else { @() }

$Wrapped = @"
$CompressHint

MANDATORY OUTPUT FORMAT:
STATUS: done | blocked | needs decision
SUMMARY:
  - bullet
EVIDENCE:
  - path:line - verbatim slice
ARTIFACTS:
  - ./.scratch/...
DECISIONS NEEDED:
  - question

TASK:
$Prompt
"@

# Pipe via stdin to avoid Windows command-line quoting issues with embedded quotes
$Wrapped | & codex exec --sandbox workspace-write --skip-git-repo-check @Extra
