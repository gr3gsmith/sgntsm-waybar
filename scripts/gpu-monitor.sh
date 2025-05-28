#!/bin/bash

# Get GPU utilization and temperature (without %, °C)
read -r util temp <<< $(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | tr -d ' %' | sed 's/,/ /')

# Format utilisation to always be at least 2 digits.
util=$(printf "%2d" "$util")

# Default values
class="temperature-cool"
icon=""  # Cold icon

# Temperature thresholds and corresponding class/icon
if [ "$temp" -ge 80 ]; then
    class="temperature-hot"
    icon=""
elif [ "$temp" -ge 60 ]; then
    class="temperature-warm"
    icon=""
fi

# Output JSON for Waybar
echo "{\"text\": \"󰢮  ${util}% ${icon} ${temp}°C\", \"class\": \"$class\"}"

