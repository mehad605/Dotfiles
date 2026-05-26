#!/bin/bash

# $1 is the image path sent by imv
IMAGE_PATH="$1"
CONFIG_FILE="$HOME/.config/cosmic/com.system76.CosmicBackground/v1/all"

cat <<EOF > "$CONFIG_FILE"
(
    output: "all",
    source: Path("$IMAGE_PATH"),
    filter_by_theme: false,
    rotation_frequency: 300,
    filter_method: Lanczos,
    scaling_mode: Zoom,
    sampling_method: Alphanumeric,
)
EOF

