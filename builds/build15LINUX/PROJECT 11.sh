#!/bin/sh
echo -ne '\033c\033]0;PROJECT 11\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/PROJECT 11.x86_64" "$@"
