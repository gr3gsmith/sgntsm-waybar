#!/bin/bash

# Get CPU utilisation (total usage across all cores over 1 second)
# Use mpstat if available for more accuracy, fallback to top
if command -v mpstat &>/dev/null; then
    # mpstat gives idle %, so we subtract from 100
    util=$(mpstat 1 1 | awk '/Average:/ { printf("%.0f", 100 - $NF) }')
else
    util=$(top -bn2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8}' | cut -d'.' -f1)
fi

# Format utilisation to always be at least 2 digits.
util=$(printf "%2d" "$util")

# Get CPU temperature from k10temp (Tctl)
temp=$(sensors | awk '/^Tctl:/ { gsub(/\+|°C/, "", $2); print $2 }' | cut -d'.' -f1)

# Default values
class="temperature-cool"
icon=""  # Cold icon

# Temperature thresholds and corresponding class/icon
if [ "$temp" -ge 85 ]; then
    class="temperature-hot"
    icon=""
elif [ "$temp" -ge 60 ]; then
    class="temperature-warm"
    icon=""
fi

# Output JSON for Waybar
echo "{\"text\": \"  ${util}% ${icon} ${temp}°C\", \"class\": \"$class\"}"

