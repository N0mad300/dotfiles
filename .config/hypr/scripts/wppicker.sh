#!/bin/bash
set -euo pipefail

wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
current_wallpaper="$HOME/.config/hypr/current_wallpaper"
rofi_config="$HOME/.config/rofi/config.rasi"

for command in awww awww-daemon matugen rofi; do
    command -v "$command" >/dev/null 2>&1 || {
        notify-send -u critical "Wallpaper picker" "Missing command: $command"
        exit 1
    }
done

[ -d "$wallpaper_dir" ] || {
    notify-send -u normal "Wallpaper picker" "Directory does not exist: $wallpaper_dir"
    exit 1
}

if ! awww query >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    for _ in {1..50}; do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

selected=$(
    find -L "$wallpaper_dir" -maxdepth 1 -type f         \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' \)         -printf '%T@ %p\n' |
        sort -nr |
        while IFS= read -r entry; do
            path="${entry#* }"
            name="${path##*/}"
            printf '%s\0icon\x1f%s\n' "$name" "$path"
        done |
        rofi -dmenu -i -config "$rofi_config" -p "Wallpaper"
)

[ -n "$selected" ] || exit 0
selected_path="$wallpaper_dir/$selected"
[ -f "$selected_path" ] || exit 1

mkdir -p "$(dirname "$current_wallpaper")"
ln -sfn "$selected_path" "$current_wallpaper"

if matugen image "$selected_path"; then
    notify-send -t 1500 -u low -i "$selected_path" "Wallpaper changed" "$selected"
else
    notify-send -u critical "Wallpaper picker" "Matugen failed for: $selected"
    exit 1
fi
