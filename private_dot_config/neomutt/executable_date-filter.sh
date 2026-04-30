#!/bin/sh
awk '
/^Date:[[:space:]]/ {
    raw = substr($0, index($0, ":") + 1)
    sub(/^[[:space:]]+/, "", raw)
    gsub(/"/, "", raw)
    cmd = "date +\"Date: %a, %d %b %Y %H:%M:%S %z\" -d \"" raw "\" 2>/dev/null"
    if ((cmd | getline converted) > 0 && converted != "") {
        print converted
        close(cmd)
        next
    }
    close(cmd)
}
{ print }
'
