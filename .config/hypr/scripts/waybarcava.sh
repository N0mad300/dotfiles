#!/bin/bash
set -euo pipefail

bar="▁▂▃▄▅▆▇█"
dict="s/;//g"
for ((i = 0; i < ${#bar}; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
config_file="$runtime_dir/waybar-cava-${UID}.conf"
trap 'rm -f "$config_file"' EXIT

cat >"$config_file" <<'EOF'
[general]
framerate = 30
bars = 10

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

pkill -f "cava -p $config_file" >/dev/null 2>&1 || true
cava -p "$config_file" | sed -u "$dict"
