# Claude Code status line: context meter, cache hit ratio, model, rate limits.
# (Windows side; the POSIX twin is statusline.sh — keep the two in sync.)
#
# Claude Code pipes the session JSON to this script on stdin. Needs no jq —
# ConvertFrom-Json is built in. Written for Windows PowerShell 5.1, so no
# ternaries, no null-coalescing, no PS7-only operators.
#
# Scaling notes, confirmed against the payload builder:
#   rate_limits.*.used_percentage  0-100 but a float, so it is rounded
#   prompt_cache.hit_ratio         a FRACTION 0-1, so it is multiplied by 100
#
# Renders as:  Context 160k  cache 87%  ~  Opus 5 (1M context)  5h 34% 7d 12%

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'

# --- config ---------------------------------------------------------------
$Sep        = '  '  # between every field group
$WarnPct    = 60    # amber at or above this percent (context and rate limits)
$CritPct    = 80    # red at or above this
$ShowCache  = $true
$ShowDir    = $true
$ShowModel  = $true
$ShowLimits = $true
# --------------------------------------------------------------------------

$raw = [Console]::In.ReadToEnd()

$data = $null
if ($raw -and $raw.Trim()) {
  try { $data = $raw | ConvertFrom-Json } catch { $data = $null }
}

if ($null -eq $data) {
  Write-Output 'Context unavailable'
  exit 0
}

# Missing properties read back as $null under StrictMode -Off, so walk defensively.
$ctx     = $data.context_window
$usedPct = -1
$totalIn = 0
$win     = 0
if ($null -ne $ctx) {
  if ($null -ne $ctx.used_percentage)     { $usedPct = [int][Math]::Round([double]$ctx.used_percentage) }
  if ($null -ne $ctx.total_input_tokens)  { $totalIn = [int64]$ctx.total_input_tokens }
  if ($null -ne $ctx.context_window_size) { $win     = [int64]$ctx.context_window_size }
}

$model = '?'
if ($null -ne $data.model -and $data.model.display_name) { $model = [string]$data.model.display_name }

$cwd = ''
if ($null -ne $data.workspace -and $data.workspace.current_dir) { $cwd = [string]$data.workspace.current_dir }
elseif ($data.cwd) { $cwd = [string]$data.cwd }

# -1 is the "not present" sentinel, matching the bash twin.
$rl5 = -1
$rl7 = -1
$rl = $data.rate_limits
if ($null -ne $rl) {
  if ($null -ne $rl.five_hour -and $null -ne $rl.five_hour.used_percentage) {
    $rl5 = [int][Math]::Round([double]$rl.five_hour.used_percentage)
  }
  if ($null -ne $rl.seven_day -and $null -ne $rl.seven_day.used_percentage) {
    $rl7 = [int][Math]::Round([double]$rl.seven_day.used_percentage)
  }
}

$cachePct = -1
if ($null -ne $data.prompt_cache -and $null -ne $data.prompt_cache.hit_ratio) {
  $cachePct = [int][Math]::Round([double]$data.prompt_cache.hit_ratio * 100)
}

# Compact token counts: 847, 47.3k, 160k, 1.05M.
function Format-Tokens([int64]$n) {
  if ($n -ge 1000000) {
    return ('{0}.{1:D2}M' -f [int64]($n / 1000000), [int64](($n % 1000000) / 10000))
  } elseif ($n -ge 100000) {
    return ('{0}k' -f [int64](($n + 500) / 1000))
  } elseif ($n -ge 1000) {
    return ('{0}.{1}k' -f [int64]($n / 1000), [int64](($n % 1000) / 100))
  }
  return "$n"
}

$e = [char]27
if ($env:NO_COLOR) {
  $cReset = ''; $cDim = ''; $cOk = ''; $cWarn = ''; $cCrit = ''
} else {
  $cReset = "$e[0m"; $cDim = "$e[2m"
  $cOk = "$e[32m";   $cWarn = "$e[33m"; $cCrit = "$e[31m"
}

# Fuller means worse, for both the context window and the rate limits.
function Get-PctColour([int]$p) {
  if ($p -ge $CritPct)     { return $cCrit }
  elseif ($p -ge $WarnPct) { return $cWarn }
  return $cOk
}

# --- context meter --------------------------------------------------------
if ($win -le 0) {
  $line = 'Context n/a'
} else {
  if ($usedPct -lt 0) { $usedPct = 0 }   # null used_percentage = no API call yet
  $line = 'Context ' + (Get-PctColour $usedPct) + (Format-Tokens $totalIn) + $cReset
}

# --- cache hit ratio ------------------------------------------------------
if ($ShowCache -and $cachePct -ge 0) {
  $line += $Sep + $cDim + "cache $cachePct%" + $cReset
}

# --- directory ------------------------------------------------------------
if ($ShowDir -and $cwd) {
  $home_ = $env:USERPROFILE
  if (-not $home_) { $home_ = $HOME }
  $shown = $cwd
  if ($home_ -and $cwd.StartsWith($home_, [StringComparison]::OrdinalIgnoreCase)) {
    $shown = '~' + $cwd.Substring($home_.Length)
  }
  $line += $Sep + $cDim + $shown + $cReset
}

# --- model ----------------------------------------------------------------
if ($ShowModel -and $model -and $model -ne '?') {
  $line += $Sep + $cDim + $model + $cReset
}

# --- rate limits ----------------------------------------------------------
if ($ShowLimits) {
  $limits = ''
  if ($rl5 -ge 0) {
    $limits += $cDim + '5h' + $cReset + ' ' + (Get-PctColour $rl5) + "$rl5%" + $cReset
  }
  if ($rl7 -ge 0) {
    if ($limits) { $limits += ' ' }
    $limits += $cDim + '7d' + $cReset + ' ' + (Get-PctColour $rl7) + "$rl7%" + $cReset
  }
  if ($limits) { $line += $Sep + $limits }
}

Write-Output $line
