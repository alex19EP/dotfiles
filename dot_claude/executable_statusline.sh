#!/usr/bin/env bash
# Claude Code status line: context meter, cache hit ratio, model, rate limits.
# (POSIX side; the Windows twin is statusline.ps1 — keep the two in sync.)
#
# Claude Code pipes a JSON blob describing the session to this script on stdin.
# Fields used, all confirmed against the v2.1.x payload builder:
#
#   context_window.total_input_tokens   tokens in the window
#                                       (input + cache creation + cache read)
#   context_window.context_window_size  window size for the active model
#   context_window.used_percentage      round(total_input / size * 100), 0-100,
#                                       or null before the first API call
#   rate_limits.{five_hour,seven_day}.used_percentage
#                                       0-100 but a FLOAT (utilization * 100);
#                                       the whole object is absent if no limits
#   prompt_cache.hit_ratio              a FRACTION 0-1 (cache reads / input),
#                                       or null; prompt_cache itself is absent
#                                       until the first request
#
# The float->int conversions happen in jq, since bash has no float math.
#
# Renders as:  Context 160k  cache 87%  ~  Opus 5 (1M context)  5h 34% 7d 12%
#
# Output is plain ASCII with light punctuation so it reads cleanly through a
# screen reader. Colour is ANSI-only, which screen readers ignore.

set -uo pipefail

# --- config ---------------------------------------------------------------
SEP='  '        # between every field group
WARN_PCT=60     # amber at or above this percent (context and rate limits)
CRIT_PCT=80     # red at or above this
SHOW_CACHE=1    # set to 0 to drop the cache hit ratio
SHOW_DIR=1      # set to 0 to drop the working directory
SHOW_MODEL=1    # set to 0 to drop the model name
SHOW_LIMITS=1   # set to 0 to drop the 5h / 7d rate limits
# --------------------------------------------------------------------------

json=$(cat)

# -1 is the "not present" sentinel throughout. Every numeric field is passed
# through `round` so it is always a bash-safe integer.
#
# One field per LINE, not per tab: `IFS=$'\t' read` silently collapses runs of
# tabs, because tab counts as IFS whitespace, so a single empty field (an empty
# cwd, say) shifts every later field left by one and corrupts the whole line.
mapfile -t F < <(printf '%s' "$json" | jq -r '
  [ (if .context_window.used_percentage == null then -1
     else (.context_window.used_percentage | round) end),
    ((.context_window.total_input_tokens  // 0) | round),
    ((.context_window.context_window_size // 0) | round),
    (.model.display_name                  // "?"),
    (.workspace.current_dir               // .cwd // ""),
    (if .rate_limits.five_hour.used_percentage == null then -1
     else (.rate_limits.five_hour.used_percentage | round) end),
    (if .rate_limits.seven_day.used_percentage == null then -1
     else (.rate_limits.seven_day.used_percentage | round) end),
    (if .prompt_cache.hit_ratio == null then -1
     else (.prompt_cache.hit_ratio * 100 | round) end)
  ] | .[] | tostring | gsub("[\n\r\t]"; " ")' 2>/dev/null)

if (( ${#F[@]} != 8 )); then
  # jq missing or payload unparseable: say so rather than printing nothing.
  printf 'Context unavailable\n'
  exit 0
fi

used_pct=${F[0]} total_in=${F[1]} win=${F[2]} model=${F[3]}
cwd=${F[4]}      rl5=${F[5]}      rl7=${F[6]} cache_pct=${F[7]}

# Compact token counts: 847, 47.3k, 160k, 1.05M.
fmt_tokens() {
  local n=$1
  if   (( n >= 1000000 )); then printf '%d.%02dM' $(( n / 1000000 )) $(( n % 1000000 / 10000 ))
  elif (( n >= 100000  )); then printf '%dk'      $(( (n + 500) / 1000 ))
  elif (( n >= 1000    )); then printf '%d.%dk'   $(( n / 1000 )) $(( n % 1000 / 100 ))
  else                          printf '%d'       "$n"
  fi
}

if [[ -n ${NO_COLOR:-} ]]; then
  c_reset='' c_dim='' c_ok='' c_warn='' c_crit=''
else
  c_reset=$'\033[0m' c_dim=$'\033[2m'
  c_ok=$'\033[32m'   c_warn=$'\033[33m' c_crit=$'\033[31m'
fi

# Fuller means worse, for both the context window and the rate limits.
pct_colour() {
  if   (( $1 >= CRIT_PCT )); then printf '%s' "$c_crit"
  elif (( $1 >= WARN_PCT )); then printf '%s' "$c_warn"
  else                            printf '%s' "$c_ok"
  fi
}

# --- context meter --------------------------------------------------------
if (( win <= 0 )); then
  line="Context n/a"
else
  (( used_pct < 0 )) && used_pct=0   # null used_percentage = no API call yet
  line="Context $(pct_colour "$used_pct")$(fmt_tokens "$total_in")${c_reset}"
fi

# --- cache hit ratio ------------------------------------------------------
if (( SHOW_CACHE )) && (( cache_pct >= 0 )); then
  line+="${SEP}${c_dim}cache ${cache_pct}%${c_reset}"
fi

# --- directory ------------------------------------------------------------
if (( SHOW_DIR )) && [[ -n $cwd ]]; then
  line+="${SEP}${c_dim}${cwd/#$HOME/\~}${c_reset}"
fi

# --- model ----------------------------------------------------------------
if (( SHOW_MODEL )) && [[ -n $model && $model != '?' ]]; then
  line+="${SEP}${c_dim}${model}${c_reset}"
fi

# --- rate limits ----------------------------------------------------------
if (( SHOW_LIMITS )); then
  limits=''
  if (( rl5 >= 0 )); then
    limits+="${c_dim}5h${c_reset} $(pct_colour "$rl5")${rl5}%${c_reset}"
  fi
  if (( rl7 >= 0 )); then
    [[ -n $limits ]] && limits+=' '
    limits+="${c_dim}7d${c_reset} $(pct_colour "$rl7")${rl7}%${c_reset}"
  fi
  [[ -n $limits ]] && line+="${SEP}${limits}"
fi

printf '%s\n' "$line"
