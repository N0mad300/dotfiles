#!/bin/sh
set -eu

pkill -x waybar >/dev/null 2>&1 || true
pkill -x swaync >/dev/null 2>&1 || true

attempt=0
while pgrep -x waybar >/dev/null 2>&1 || pgrep -x swaync >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    [ "$attempt" -ge 20 ] && break
    sleep 0.1
done

swaync >/dev/null 2>&1 &

config="$HOME/.config/waybar/config"
style="$HOME/.config/waybar/style.css"
state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
log_dir="$state_home/void-hyprland"

mkdir -p "$log_dir"
[ -f "$config" ] || { printf 'Missing Waybar config: %s\n' "$config" >&2; exit 1; }
[ -f "$style" ] || { printf 'Missing Waybar stylesheet: %s\n' "$style" >&2; exit 1; }
waybar -c "$config" -s "$style" >"$log_dir/waybar.log" 2>&1 &
