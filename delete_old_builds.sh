#!/usr/bin/env bash

if [ -f "static/current.txt" ]; then
    find static \
        | grep -E '*hashed*' \
        | grep -v "$(cat static/current.txt 2>/dev/null || echo)" \
        | xargs -r rm
fi
