#!/bin/sh
set -eu

enabled=$(hyprctl getoption decoration:blur:enabled -j | jq -r '.int // 0')
if [ "$enabled" -eq 1 ]; then
    value=false
else
    value=true
fi

hyprctl eval "hl.config({ decoration = { blur = { enabled = $value } } })"
