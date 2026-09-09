#!/usr/bin/sh
# Move mail tagged 'deleted' into its own account's Trash, then sync.
# Called by the neomutt S macro and by mbsync.service.

set -u
MAILROOT="$HOME/.local/share/mail"

/usr/bin/notmuch search --exclude=false --output=files -- tag:deleted |
while IFS= read -r f; do
  case "$f" in
    "$MAILROOT"/*) ;;
    *) continue ;;                # outside the mail root, don't touch
  esac
  case "$f" in
    */Trash/*) continue ;;        # already in a trash folder ([Gmail]/Trash too)
  esac

  rel="${f#"$MAILROOT"/}"
  acct="${rel%%/*}"
  if [ "$acct" = "gmail" ]; then
    trash="$MAILROOT/gmail/[Gmail]/Trash"
  else
    trash="$MAILROOT/$acct/Trash"
  fi
  [ -d "$trash" ] || continue     # unknown account layout, leave it alone

  case "$f" in
    */new/*) sub="new" ;;
    *) sub="cur" ;;
  esac

  # strip the mbsync UID so mbsync uploads it as a new message in Trash
  name=$(printf '%s' "${f##*/}" | sed 's/,U=[0-9]*//')
  mv -n "$f" "$trash/$sub/$name"
done

# Sync, tolerating transient network hiccups.  mbsync exits non-zero if *any*
# channel fails, so one dropped connection marked mbsync.service failed every
# 3 minutes while the other accounts synced fine.  Retry once, and stay failed
# only when something other than a socket error is involved.
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

rc=0
attempt=1
while [ "$attempt" -le 2 ]; do
  { /usr/bin/mbsync -Vac "$HOME/.config/isync/mbsyncrc" 2>&1; echo $? >"$tmp/rc"; } | tee "$tmp/log"
  rc=$(cat "$tmp/rc")
  [ "$rc" -eq 0 ] && break

  # Forgive only a run whose every error was the server hanging up on us:
  # socket timeouts/resets, or gmail's transient "unexpected BYE".  Anything
  # else (auth, config, maildir) is real.  An unexplained non-zero exit with no
  # error line at all stays a failure too - better red than silently wrong.
  errs=$(grep -icE '^(socket error|imap error|maildir error|error|fatal)' "$tmp/log")
  ok=$(grep -icE '^(socket error|imap error: unexpected bye response)' "$tmp/log")
  if [ "$errs" -eq 0 ] || [ "$errs" -ne "$ok" ]; then
    break                         # real failure (auth, config, disk) - keep rc
  fi

  if [ "$attempt" -eq 1 ]; then
    echo "sync-mail: transient socket error, retrying once..." >&2
  else
    echo "sync-mail: transient socket error persisted; other channels synced." >&2
    rc=0
  fi
  attempt=$((attempt + 1))
done

/usr/bin/notmuch new
exit "$rc"
