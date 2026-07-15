#!/bin/sh
set -eu

pgrep -x hyprlock >/dev/null 2>&1 || exec hyprlock
