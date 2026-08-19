#!/bin/sh
printf '\033c\033]0;%s\a' Galactic Fighters Prototype
base_path="$(dirname "$(realpath "$0")")"
"$base_path/signaling_server.x86_64" "$@"
