#!/bin/sh
set -u

attempt=0
while ! awww query >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    [ "$attempt" -ge 50 ] && exit 1
    sleep 0.1
done

if awww restore >/dev/null 2>&1; then
    exit 0
fi

wallpaper="$HOME/.config/hypr/current_wallpaper"
if [ -e "$wallpaper" ]; then
    exec awww img --transition-type none "$wallpaper"
fi
