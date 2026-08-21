#!/bin/sh
printf '\033c\033]0;%s\a' Galactic Fighters Prototype
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Galactic Fighters (Linux Release).x86_64" "$@"
