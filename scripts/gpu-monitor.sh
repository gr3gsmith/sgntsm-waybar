#!/bin/bash

# Dump GPU data as json.
amdgpu_json=$(amdgpu_top -J -n 1)

# Extract the temperature and format it to 2 digits.
temp=$(jq '.devices[0].gpu_metrics.temperature_hotspot' <<< "$amdgpu_json")
temp=$(printf "%2d" "$temp")

# Alternative method for finding temperature.
# temp=$(sensors -j | jq '.["amdgpu-pci-0300"].junction.temp2_input')

# Extract utilisation and format it to two digits.
util=$(jq '.devices[0].gpu_activity.GFX.value' <<< "$amdgpu_json")
util=$(printf "%2d" "$util")

# Default values
class="temperature-cool"
icon=""  # Cold icon

# Temperature thresholds and corresponding class/icon
if [ "$temp" -ge 90 ]; then
    class="temperature-hot"
    icon=""
elif [ "$temp" -ge 70 ]; then
    class="temperature-warm"
    icon=""
fi

# Output JSON for Waybar
echo "{\"text\": \"󰢮   ${util}%  ${icon}  ${temp}°C\", \"class\": \"$class\"}"

