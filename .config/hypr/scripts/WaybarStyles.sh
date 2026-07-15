#!/bin/sh
set -eu

styles="$HOME/.config/waybar/style"
active="$HOME/.config/waybar/style.css"
rofi_config="$HOME/.config/rofi/config.rasi"

if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi
fi

choice=$(
    find -L "$styles" -maxdepth 1 -type f -name '*.css' -printf '%f\n' |
        sed 's/\.css$//' |
        sort |
        rofi -i -dmenu -config "$rofi_config" -p "Waybar style"
)

[ -n "$choice" ] || exit 0

case "$choice" in
    */*) exit 1 ;;
esac

[ -f "$styles/$choice.css" ] || exit 1
ln -sfn "$styles/$choice.css" "$active"
exec "$HOME/.config/hypr/scripts/wbrestart.sh"
