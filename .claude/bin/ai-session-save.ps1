# ai-session-save.ps1 - Export the latest CLI AI session after the fact.

[CmdletBinding()]
param(
  [string]$SessionId,
  [string]$Title,
  [string]$OutputRoot = "$HOME\Documents\workspace\AI Session Logs",
  [switch]$Latest,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'

if ($Help) {
  Write-Host "Usage: ai-session-save [-SessionId <codex-session-id>] [-Title <title>] [-OutputRoot <path>]"
  Write-Host "Exports raw transcript, structured session log, and Notion-ready session log."
  Write-Host "In a connected Codex session, routing rules should also push the Notion-ready log to Notion."
  exit 0
}

function Convert-Slug {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return "ai-session" }
  $slug = $Text.ToLowerInvariant() -replace '[^a-z0-9]+','-'
  $slug = $slug.Trim('-')
  if ($slug.Length -gt 60) { $slug = $slug.Substring(0, 60).Trim('-') }
  if ([string]::IsNullOrWhiteSpace($slug)) { return "ai-session" }
  return $slug
}

function Convert-JsonLine {
  param([string]$Line)
  try { return $Line | ConvertFrom-Json -ErrorAction Stop } catch { return $null }
}

function Get-TextFromContent {
  param($Content)
  if ($null -eq $Content) { return "" }
  if ($Content -is [string]) { return $Content }
  $parts = @()
  foreach ($item in @($Content)) {
    if ($null -ne $item.text) { $parts += [string]$item.text; continue }
    if ($null -ne $item.input_text) { $parts += [string]$item.input_text; continue }
    if ($null -ne $item.output_text) { $parts += [string]$item.output_text; continue }
    if ($item.PSObject.Properties.Name -contains 'type') { $parts += "[${($item.type)}]" }
  }
  return ($parts -join "`n")
}

function Find-CodexSessionFile {
  param([string]$WantedSessionId)

  $root = Join-Path $HOME ".codex\sessions"
  if (-not (Test-Path -LiteralPath $root)) {
    throw "Codex sessions folder not found: $root"
  }

  if ($WantedSessionId) {
    $match = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.jsonl" |
      Where-Object { $_.Name -like "*$WantedSessionId*" } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
    if (-not $match) { throw "No Codex session file found for SessionId: $WantedSessionId" }
    return $match
  }

  return Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.jsonl" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Read-SessionEvents {
  param([string]$Path)
  $events = New-Object System.Collections.Generic.List[object]
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $obj = Convert-JsonLine $line
    if ($null -ne $obj) { $events.Add($obj) }
  }
  return $events
}

$sessionFile = Find-CodexSessionFile -WantedSessionId $SessionId
$events = Read-SessionEvents -Path $sessionFile.FullName
if ($events.Count -eq 0) { throw "Session file had no parseable events: $($sessionFile.FullName)" }

$meta = $events | Where-Object { $_.type -eq 'session_meta' } | Select-Object -First 1
$sessionMeta = if ($meta) { $meta.payload } else { $null }
$id = if ($sessionMeta -and $sessionMeta.id) { [string]$sessionMeta.id } else { [IO.Path]::GetFileNameWithoutExtension($sessionFile.Name) }
$started = if ($sessionMeta -and $sessionMeta.timestamp) { [datetime]$sessionMeta.timestamp } else { $sessionFile.CreationTime }
$cwd = if ($sessionMeta -and $sessionMeta.cwd) { [string]$sessionMeta.cwd } else { "" }
$ai = if ($sessionMeta -and $sessionMeta.originator) { [string]$sessionMeta.originator } else { "codex" }
$model = if ($sessionMeta -and $sessionMeta.model_provider) { [string]$sessionMeta.model_provider } else { "" }

$messages = New-Object System.Collections.Generic.List[object]
$commands = New-Object System.Collections.Generic.List[object]

foreach ($event in $events) {
  $ts = if ($event.timestamp) { [datetime]$event.timestamp } else { $null }

  if ($event.type -eq 'response_item' -and $event.payload.type -eq 'message') {
    $role = [string]$event.payload.role
    $phase = if ($event.payload.phase) { [string]$event.payload.phase } else { "" }
    $text = Get-TextFromContent $event.payload.content
    if (-not [string]::IsNullOrWhiteSpace($text)) {
      $messages.Add([pscustomobject]@{ Timestamp=$ts; Role=$role; Phase=$phase; Text=$text.Trim() })
    }
  }

  if ($event.type -eq 'event_msg' -and $event.payload.type -eq 'agent_message') {
    $text = [string]$event.payload.message
    if (-not [string]::IsNullOrWhiteSpace($text)) {
      $messages.Add([pscustomobject]@{ Timestamp=$ts; Role='assistant'; Phase=([string]$event.payload.phase); Text=$text.Trim() })
    }
  }

  if ($event.type -eq 'response_item' -and $event.payload.type -eq 'function_call') {
    $name = [string]$event.payload.name
    $arguments = [string]$event.payload.arguments
    $commands.Add([pscustomobject]@{ Timestamp=$ts; Tool=$name; Arguments=$arguments; Status='called' })
  }

  if ($event.type -eq 'event_msg' -and $event.payload.type -eq 'exec_command_end') {
    $cmd = if ($event.payload.command) { ($event.payload.command -join ' ') } else { [string]$event.payload.parsed_cmd.cmd }
    $status = if ($event.payload.status) { [string]$event.payload.status } else { [string]$event.payload.exit_code }
    $commands.Add([pscustomobject]@{ Timestamp=$ts; Tool='shell'; Arguments=$cmd; Status=$status })
  }

}

$userPrompts = $messages | Where-Object Role -eq 'user'
if (-not $Title) {
  $firstPrompt = $userPrompts | Select-Object -First 1
  $Title = if ($firstPrompt) { $firstPrompt.Text } else { "Codex session $id" }
}
$slug = Convert-Slug $Title
$stamp = $started.ToString("yyyy-MM-dd_HHmm")
$outDir = Join-Path $OutputRoot "$stamp-codex-$slug"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$rawJsonl = Join-Path $outDir "raw-transcript.jsonl"
$rawMd = Join-Path $outDir "raw-transcript.md"
$sessionLog = Join-Path $outDir "session-log.md"
$notionReady = Join-Path $outDir "notion-ready.md"

Copy-Item -LiteralPath $sessionFile.FullName -Destination $rawJsonl -Force

$rawLines = New-Object System.Collections.Generic.List[string]
$rawLines.Add("# Raw Transcript")
$rawLines.Add("")
$rawLines.Add("- Session ID: ``$id``")
$rawLines.Add("- Source: ``" + $sessionFile.FullName + "``")
$rawLines.Add("- CWD: ``$cwd``")
$rawLines.Add("")
foreach ($m in $messages) {
  $label = $m.Role
  if ($m.Phase) { $label = "$label/$($m.Phase)" }
  $time = if ($m.Timestamp) { $m.Timestamp.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
  $rawLines.Add("## $label $time")
  $rawLines.Add("")
  $rawLines.Add($m.Text)
  $rawLines.Add("")
}
Set-Content -LiteralPath $rawMd -Value $rawLines -Encoding UTF8

$finalAssistant = $messages | Where-Object { $_.Role -eq 'assistant' -and $_.Phase -eq 'final' } | Select-Object -Last 1
$assistantDeliverables = $messages | Where-Object { $_.Role -eq 'assistant' -and ($_.Phase -eq 'final' -or $_.Phase -eq 'commentary') } | Select-Object -Last 8
$commandCount = ($commands | Measure-Object).Count
$fileSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($cmd in $commands) {
  $text = [string]$cmd.Arguments
  foreach ($m in [regex]::Matches($text, '([A-Za-z]:\\[^\r\n"<>|]+?\.[A-Za-z0-9]{1,8})')) {
    $candidate = $m.Groups[1].Value.Trim()
    if ($candidate.Length -gt 180) { continue }
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
      [void]$fileSet.Add((Resolve-Path -LiteralPath $candidate).Path)
    }
  }
}
$fileList = $fileSet | Sort-Object | Select-Object -First 40

$summaryText = if ($finalAssistant) { $finalAssistant.Text } else { "No final assistant message found in the saved session. Review the raw transcript." }

$promptLines = @($userPrompts | Select-Object -First 20 | ForEach-Object { "- " + ($_.Text -replace "`r?`n"," ") })
if ($promptLines.Count -eq 0) { $promptLines = @("- None detected") }

$fileLines = if ($fileList) { @($fileList | ForEach-Object { "- $_" }) } else { @("- None detected") }
$notionFileLines = if ($fileList) { @($fileList | ForEach-Object { "- $_" }) } else { @("- No files detected from transcript metadata.") }

$logLines = New-Object System.Collections.Generic.List[string]
$logLines.Add("# AI Session Log - " + $started.ToString("yyyy-MM-dd HH:mm"))
$logLines.Add("")
$logLines.Add("## Metadata")
$logLines.Add("")
$logLines.Add("- Session ID: ``$id``")
$logLines.Add("- AI: Codex")
$logLines.Add("- Originator: ``$ai``")
$logLines.Add("- Model Provider: ``$model``")
$logLines.Add("- Started: " + $started.ToString("yyyy-MM-dd HH:mm:ss"))
$logLines.Add("- Working Directory: ``$cwd``")
$logLines.Add("- Source Log: ``" + $sessionFile.FullName + "``")
$logLines.Add("- Raw Export: ``$rawJsonl``")
$logLines.Add("")
$logLines.Add("## Goal")
$logLines.Add("")
$logLines.Add($Title)
$logLines.Add("")
$logLines.Add("## User Prompts")
$logLines.Add("")
$promptLines | ForEach-Object { $logLines.Add($_) }
$logLines.Add("")
$logLines.Add("## Work Completed")
$logLines.Add("")
$logLines.Add($summaryText)
$logLines.Add("")
$logLines.Add("## Commands And Tool Activity")
$logLines.Add("")
$logLines.Add("- Tool/command events captured: $commandCount")
$logLines.Add("")
$logLines.Add("## Files Mentioned")
$logLines.Add("")
$fileLines | ForEach-Object { $logLines.Add($_) }
$logLines.Add("")
$logLines.Add("## Open Loops")
$logLines.Add("")
$logLines.Add("- Review raw transcript for any unresolved decisions or follow-up tasks.")
$logLines.Add("")
$logLines.Add("## Artifacts")
$logLines.Add("")
$logLines.Add("- Raw JSONL: ``$rawJsonl``")
$logLines.Add("- Readable transcript: ``$rawMd``")
$logLines.Add("- Structured log: ``$sessionLog``")
$logLines.Add("- Notion-ready log: ``$notionReady``")
Set-Content -LiteralPath $sessionLog -Value $logLines -Encoding UTF8

$notionLines = New-Object System.Collections.Generic.List[string]
$notionLines.Add("---")
$notionLines.Add("Date: " + $started.ToString("yyyy-MM-dd"))
$notionLines.Add("AI: Codex")
$notionLines.Add("Mode: codex-primary")
$notionLines.Add("Session ID: $id")
$notionLines.Add("Project: $slug")
$notionLines.Add("Status: Logged")
$notionLines.Add("Working Directory: $cwd")
$notionLines.Add("Raw Transcript: $rawJsonl")
$notionLines.Add("---")
$notionLines.Add("")
$notionLines.Add("# AI Session Log - " + $started.ToString("yyyy-MM-dd HH:mm"))
$notionLines.Add("")
$notionLines.Add("## Goal")
$notionLines.Add("")
$notionLines.Add($Title)
$notionLines.Add("")
$notionLines.Add("## Summary")
$notionLines.Add("")
$notionLines.Add($summaryText)
$notionLines.Add("")
$notionLines.Add("## Decisions Made")
$notionLines.Add("")
$notionLines.Add("- See transcript for exact wording and context.")
$notionLines.Add("")
$notionLines.Add("## Files / Artifacts")
$notionLines.Add("")
$notionFileLines | ForEach-Object { $notionLines.Add($_) }
$notionLines.Add("")
$notionLines.Add("## Commands / Tool Activity")
$notionLines.Add("")
$notionLines.Add("- Captured $commandCount tool or command events.")
$notionLines.Add("")
$notionLines.Add("## Next Actions")
$notionLines.Add("")
$notionLines.Add("- Review session-log.md and raw transcript if this session needs follow-up.")
$notionLines.Add("")
$notionLines.Add("## Local Paths")
$notionLines.Add("")
$notionLines.Add("- Raw JSONL: ``$rawJsonl``")
$notionLines.Add("- Readable Transcript: ``$rawMd``")
$notionLines.Add("- Structured Session Log: ``$sessionLog``")
Set-Content -LiteralPath $notionReady -Value $notionLines -Encoding UTF8

Write-Host "AI session saved:"
Write-Host "  Folder: $outDir"
Write-Host "  Raw JSONL: $rawJsonl"
Write-Host "  Raw transcript: $rawMd"
Write-Host "  Session log: $sessionLog"
Write-Host "  Notion-ready: $notionReady"
Write-Host "  Notion action: create a Notion page from notion-ready.md when a Notion connector is available."
