#!/bin/sh
# Emit one neomutt folder-hook per local maildir folder so that Ctrl+F
# (vfolder-from-query) pre-fills the query prompt with a notmuch folder:
# term scoped to the folder being viewed.
# Run by private_dot_config/neomutt/search-hooks.tmpl at chezmoi apply time.

set -u
MAILROOT="$HOME/.local/share/mail"
[ -d "$MAILROOT" ] || exit 0

find "$MAILROOT" -type d -name cur | sed 's|/cur$||' | LC_ALL=C sort |
while IFS= read -r dir; do
  rel="${dir#"$MAILROOT"/}"
  # escape ERE metacharacters for the hook pattern
  # (neomutt compiles hook patterns with REG_EXTENDED)
  pat=$(printf '%s\n' "$rel" | sed 's/[][\\.*^$+?(){}|]/\\&/g')
  printf 'folder-hook '\''mail/%s$'\'' '\''macro index,pager \\Cf "<vfolder-from-query>folder:\\"%s\\" "'\''\n' "$pat" "$rel"
done
