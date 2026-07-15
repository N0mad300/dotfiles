#!/bin/sh
set -eu

icon="$HOME/.config/swaync/images/airplane.png"

if rfkill list wifi | grep -q "Soft blocked: yes"; then
    rfkill unblock wifi
    notify-send -t 1500 -u low -i "$icon" "Airplane mode" "Off"
else
    rfkill block wifi
    notify-send -t 1500 -u low -i "$icon" "Airplane mode" "On"
fi
