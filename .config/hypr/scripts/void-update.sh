#!/bin/sh
set -eu

terminal="${TERMINAL:-foot}"

exec "$terminal" sh -lc '
set -e
if command -v doas >/dev/null 2>&1; then
    doas xbps-install -Su
elif command -v sudo >/dev/null 2>&1; then
    sudo xbps-install -Su
else
    printf "Install doas or sudo, then run: xbps-install -Su\n" >&2
    exit 1
fi
printf "\nUpdate complete. Press Enter to close."
read -r _
'
