#!/bin/sh

if ! command -v xbps-install >/dev/null 2>&1; then
    printf '0\n'
    exit 0
fi

xbps-install -Mun 2>/dev/null |
    awk 'NF && $1 !~ /^Name$/ && $1 !~ /^Size$/ { count++ } END { print count + 0 }'
