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
waybar >/dev/null 2>&1 &
