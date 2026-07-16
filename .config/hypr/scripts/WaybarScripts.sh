#!/bin/sh
set -eu

terminal="${TERMINAL:-foot}"

case "${1:-}" in
    --nvtop)
        exec "$terminal" nvtop
        ;;
    --btop)
        exec "$terminal" btop
        ;;
    --nmtui)
        exec "$terminal" nmtui
        ;;
    --term)
        exec "$terminal"
        ;;
    *)
        printf 'Usage: %s {--nvtop|--btop|--nmtui|--term}\n' "$0" >&2
        exit 2
        ;;
esac
