#!/bin/bash
# Configuration
cache_dir="$HOME/.cache/cliphist/thumbnails"
max_items=200
mkdir -p "$cache_dir"

# 1. Cleanup once a day (non-blocking, runs in background)
if [ ! -f "$cache_dir/.last_cleanup" ] || [ $(( $(date +%s) - $(stat -c %Y "$cache_dir/.last_cleanup") )) -gt 86400 ]; then
    {
        find "$cache_dir" -type f -atime +7 -delete >/dev/null 2>&1
        cliphist list | tail -n +$max_items | awk '{print $1}' | xargs -I {} cliphist delete-query {} >/dev/null 2>&1
        touch "$cache_dir/.last_cleanup"
    } &
fi

# 2. Pre-generate thumbnails for first 8 items synchronously so first launch shows images immediately
pre_cache() {
    cliphist list | head -n 8 | while read -r line; do
        id=$(echo "$line" | cut -f1)
        content=$(echo "$line" | cut -f2-)
        if [[ "$content" == *"[ binary data"* ]]; then
            thumb="$cache_dir/$id.png"
            if [ ! -f "$thumb" ]; then
                cliphist decode "$id" > "$thumb" 2>/dev/null
                command -v convert &>/dev/null && \
                    convert "$thumb" -resize 500x140\! "$thumb" 2>/dev/null || true
            fi
        fi
    done
}
pre_cache

# 3. Build list — first 8 thumbnails already ready, rest generated in background
list_items() {
    counter=1
    cliphist list | while read -r line; do
        id=$(echo "$line" | cut -f1)
        content=$(echo "$line" | cut -f2-)

        if [[ "$content" == *"[ binary data"* ]]; then
            thumb="$cache_dir/$id.png"
            if [ ! -f "$thumb" ]; then
                {
                    cliphist decode "$id" > "$thumb" 2>/dev/null
                    command -v convert &>/dev/null && \
                        convert "$thumb" -resize 500x140\! "$thumb" 2>/dev/null || true
                } &
                echo -e "$id\t${counter}  [image — open again to load]"
            else
                if command -v identify &>/dev/null; then
                    orig_dims=$(identify -format '%wx%h' "$thumb" 2>/dev/null)
                    size=$(du -h "$thumb" 2>/dev/null | cut -f1)
                    meta="[PNG] ${orig_dims} • ${size}"
                else
                    meta="[image]"
                fi
                echo -en "$id\t${counter}  ${meta}\0icon\x1f${thumb}\n"
            fi
        else
            display=$(echo "$content" | head -n1 | tr -s '[:space:]' ' ' | cut -c1-110)
            echo -e "$id\t${counter}  ${display}"
        fi
        ((counter++))
    done
}

# 4. Show Rofi — type numbers to filter, e.g. "5" brings item 5 to top
selected=$(list_items | rofi -dmenu -i -p "Clipboard" \
    -display-columns 2 \
    -sep-column 1 \
    -show-icons \
    -theme-str '
    * {
        background:                       #1e1e2e;
        foreground:                       #cdd6f4;
        normal-background:                #1e1e2e;
        normal-foreground:                #cdd6f4;
        urgent-background:                #f38ba8;
        urgent-foreground:                #1e1e2e;
        active-background:                #a6e3a1;
        active-foreground:                #1e1e2e;
        selected-normal-background:       #585b70;
        selected-normal-foreground:       #cdd6f4;
        selected-urgent-background:       #f38ba8;
        selected-urgent-foreground:       #1e1e2e;
        selected-active-background:       #a6e3a1;
        selected-active-foreground:       #1e1e2e;
        alternate-normal-background:      #181825;
        alternate-normal-foreground:      #cdd6f4;
        alternate-urgent-background:      #f38ba8;
        alternate-urgent-foreground:      #1e1e2e;
        alternate-active-background:      #a6e3a1;
        alternate-active-foreground:      #1e1e2e;
        separatorcolor:                   #45475a;
        scrollbar-handle:                 #585b70;
    }
    window { width: 650px; }
    listview { lines: 8; fixed-height: false; scrollbar: false; spacing: 0px; }
    element { padding: 3px 10px; }
    element-icon { size: 2em; }
    element-text { vertical-align: 0.5; }')

# 5. Paste
if [ -n "$selected" ]; then
    id=$(echo "$selected" | cut -f1)
    cliphist decode "$id" | wl-copy
    sleep 0.1
    wtype -M ctrl -k v -m ctrl
fi
