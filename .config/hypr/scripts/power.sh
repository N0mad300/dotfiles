#!/bin/sh
set -eu

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        printf 'Neither doas nor sudo is available; run as root: %s\n' "$*" >&2
        return 1
    fi
}

elogind_action() {
    command -v loginctl >/dev/null 2>&1 && loginctl "$@"
}

lock_screen() {
    if ! pgrep -x hyprlock >/dev/null 2>&1; then
        hyprlock &
        sleep 0.3
    fi
}

case "${1:-}" in
    lock)
        lock_screen
        ;;
    logout)
        hyprctl dispatch 'hl.dsp.exit()'
        ;;
    suspend)
        lock_screen
        elogind_action suspend || run_as_root zzz
        ;;
    hibernate)
        lock_screen
        elogind_action hibernate || run_as_root ZZZ
        ;;
    reboot)
        elogind_action reboot || run_as_root /sbin/reboot
        ;;
    poweroff)
        elogind_action poweroff || run_as_root /sbin/poweroff
        ;;
    *)
        printf 'Usage: %s {lock|logout|suspend|hibernate|reboot|poweroff}\n' "$0" >&2
        exit 2
        ;;
esac
