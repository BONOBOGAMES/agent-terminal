#!/bin/bash

# grok-login-url — extract the most recent OAuth/login URL from the Grok
# tmux session and save it to /config, where it can be opened via the Home
# Assistant File Editor or Samba and copied without going through the
# terminal clipboard at all.
#
# Why: the browser terminal's OSC 52 clipboard path truncates long payloads
# (~400 chars). capture-pane with -J joins soft-wrapped lines so the URL
# comes out intact regardless of terminal width.
# Pattern adapted from Claude Terminal's claude-login-url.sh (MIT).

OUT="${1:-/config/grok-login-url.txt}"

url=$(tmux capture-pane -p -J -t grok -S -500 2>/dev/null \
    | grep -oE "https://(accounts\.x\.ai|auth\.x\.ai|x\.ai|console\.x\.ai)[^[:space:]\"'\`)<>]*" \
    | tail -1)

if [ -z "$url" ]; then
    # Broader fallback: any https URL that looks like OAuth (code/state/login)
    url=$(tmux capture-pane -p -J -t grok -S -500 2>/dev/null \
        | grep -oE "https://[^[:space:]\"'\`)<>]+" \
        | grep -iE "login|oauth|auth|authorize|sign-in|device" \
        | tail -1)
fi

if [ -z "$url" ]; then
    echo "No login URL found in the Grok session." >&2
    echo "Start login in Grok first (or use xai_api_key in add-on options)," >&2
    echo "then run this command again." >&2
    echo "" >&2
    echo "Recommended for HA: set option xai_api_key (password field) and restart." >&2
    exit 1
fi

printf '%s\n' "$url" > "$OUT"
chmod 600 "$OUT"

echo "Login URL saved to: $OUT"
echo "Open it with the Home Assistant File Editor (or over Samba), copy the"
echo "whole line into your browser, and authorize. Delete the file afterwards."
