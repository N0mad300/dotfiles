#!/bin/sh
set -eu

pid=$(hyprctl -j activewindow | jq -er '.pid // empty')
case "$pid" in
    ''|*[!0-9]*) exit 1 ;;
esac

[ "$pid" -gt 1 ] || exit 1
kill -TERM "$pid"
