#!/bin/bash

# Get all enabled outputs with their geometries
outputs=$(cosmic-randr list --kdl 2>/dev/null)
output_count=$(echo "$outputs" | grep -c '^output.*enabled=#true')

if [ "$output_count" -le 1 ]; then
  geometry=$(echo "$outputs" | awk '
    /^output.*enabled=#true/ { out=1 }
    out && /position/ { px=$2; py=$3 }
    out && /mode.*current=#true/ { w=$2; h=$3; print w "x" h "+" px "+" py; exit }
  ')
fi

if [ -n "$geometry" ]; then
  XDG_CURRENT_DESKTOP=Sway flameshot gui --region "$geometry"
elif command -v slurp &>/dev/null; then
  geometry=$(slurp -o -f "%wx%h+%x+%y")
  if [ -n "$geometry" ]; then
    XDG_CURRENT_DESKTOP=Sway flameshot gui --region "$geometry"
  else
    XDG_CURRENT_DESKTOP=Sway flameshot screen -p ~/Pictures/
  fi
else
  XDG_CURRENT_DESKTOP=Sway flameshot screen -p ~/Pictures/
fi
