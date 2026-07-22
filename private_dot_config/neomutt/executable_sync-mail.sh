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

rc=0
/usr/bin/mbsync -Vac "$HOME/.config/isync/mbsyncrc" || rc=$?
/usr/bin/notmuch new
exit $rc
