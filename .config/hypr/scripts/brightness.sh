#!/bin/sh
set -eu

icon_dir="$HOME/.config/swaync/icons"
step=10

get_brightness() {
    brightnessctl -m | awk -F, '{ gsub(/%/, "", $4); print $4; exit }'
}

get_icon() {
    value=$1
    if [ "$value" -le 20 ]; then
        printf '%s\n' "$icon_dir/brightness-20.png"
    elif [ "$value" -le 40 ]; then
        printf '%s\n' "$icon_dir/brightness-40.png"
    elif [ "$value" -le 60 ]; then
        printf '%s\n' "$icon_dir/brightness-60.png"
    elif [ "$value" -le 80 ]; then
        printf '%s\n' "$icon_dir/brightness-80.png"
    else
        printf '%s\n' "$icon_dir/brightness-100.png"
    fi
}

notify_brightness() {
    current=$(get_brightness)
    notify-send -t 1000 -u low         -h string:x-canonical-private-synchronous:brightness         -h int:value:"$current"         -i "$(get_icon "$current")"         "Screen brightness" "$current%"
}

case "${1:---get}" in
    --get)
        get_brightness
        ;;
    --inc)
        brightnessctl -e4 -n2 set "${step}%+" >/dev/null
        notify_brightness
        ;;
    --dec)
        brightnessctl -e4 -n2 set "${step}%-" >/dev/null
        notify_brightness
        ;;
    *)
        printf 'Usage: %s {--get|--inc|--dec}\n' "$0" >&2
        exit 2
        ;;
esac
