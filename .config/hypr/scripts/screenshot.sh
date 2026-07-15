#!/bin/sh
set -eu

directory="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$directory"

geometry=$(slurp) || exit 0
file="$directory/$(date +'%Y-%m-%d_%H-%M-%S').png"

grim -g "$geometry" "$file"
if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$file"
fi

notify-send -t 2000 -u low -i "$file" "Screenshot saved" "$file"
