#!/bin/sh
set -eu

icon_dir="$HOME/.config/swaync/icons"
sink="@DEFAULT_AUDIO_SINK@"
source="@DEFAULT_AUDIO_SOURCE@"

get_raw() {
    wpctl get-volume "$1"
}

get_percent() {
    get_raw "$1" | awk '/Volume:/ { printf "%.0f\n", $2 * 100 }'
}

is_muted() {
    get_raw "$1" | grep -q '\[MUTED\]'
}

volume_icon() {
    current=$(get_percent "$sink")
    if is_muted "$sink"; then
        printf '%s\n' "$icon_dir/volume-mute.png"
    elif [ "$current" -le 30 ]; then
        printf '%s\n' "$icon_dir/volume-low.png"
    elif [ "$current" -le 60 ]; then
        printf '%s\n' "$icon_dir/volume-mid.png"
    else
        printf '%s\n' "$icon_dir/volume-high.png"
    fi
}

notify_sink() {
    current=$(get_percent "$sink")
    if is_muted "$sink"; then
        notify-send -t 1000 -u low -i "$icon_dir/volume-mute.png" "Volume" "Muted"
    else
        notify-send -t 1000 -u low             -h string:x-canonical-private-synchronous:volume             -h int:value:"$current"             -i "$(volume_icon)" "Volume" "$current%"
    fi
}

notify_source() {
    current=$(get_percent "$source")
    if is_muted "$source"; then
        icon="$icon_dir/microphone-mute.png"
        text="Muted"
    else
        icon="$icon_dir/microphone.png"
        text="$current%"
    fi
    notify-send -t 1000 -u low         -h string:x-canonical-private-synchronous:microphone         -h int:value:"$current"         -i "$icon" "Microphone" "$text"
}

case "${1:---get}" in
    --get)
        if is_muted "$sink"; then printf 'Muted\n'; else printf '%s %%\n' "$(get_percent "$sink")"; fi
        ;;
    --get-icon)
        volume_icon
        ;;
    --inc)
        wpctl set-volume -l 1.5 "$sink" 5%+
        notify_sink
        ;;
    --dec)
        wpctl set-volume "$sink" 5%-
        notify_sink
        ;;
    --toggle)
        wpctl set-mute "$sink" toggle
        notify_sink
        ;;
    --toggle-mic)
        wpctl set-mute "$source" toggle
        notify_source
        ;;
    --mic-inc)
        wpctl set-volume -l 1.5 "$source" 5%+
        notify_source
        ;;
    --mic-dec)
        wpctl set-volume "$source" 5%-
        notify_source
        ;;
    --get-mic-icon)
        if is_muted "$source"; then
            printf '%s\n' "$icon_dir/microphone-mute.png"
        else
            printf '%s\n' "$icon_dir/microphone.png"
        fi
        ;;
    *)
        printf 'Usage: %s {--get|--get-icon|--inc|--dec|--toggle|--toggle-mic|--mic-inc|--mic-dec|--get-mic-icon}\n' "$0" >&2
        exit 2
        ;;
esac
