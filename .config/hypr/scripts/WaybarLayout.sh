#!/bin/sh
set -eu

layouts="$HOME/.config/waybar/configs"
active="$HOME/.config/waybar/config"
rofi_config="$HOME/.config/rofi/config.rasi"

if pgrep -x rofi >/dev/null 2>&1; then
    pkill -x rofi
fi

choice=$(
    {
        printf '%s\n' "no panel"
        find -L "$layouts" -maxdepth 1 -type f -printf '%f\n' | sort
    } | rofi -i -dmenu -config "$rofi_config" -p "Waybar layout"
)

[ -n "$choice" ] || exit 0

if [ "$choice" = "no panel" ]; then
    pkill -x waybar >/dev/null 2>&1 || true
    exit 0
fi

case "$choice" in
    */*) exit 1 ;;
esac

[ -f "$layouts/$choice" ] || exit 1
ln -sfn "$layouts/$choice" "$active"
exec "$HOME/.config/hypr/scripts/wbrestart.sh"
