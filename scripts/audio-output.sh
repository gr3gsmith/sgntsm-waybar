#!/usr/bin/env bash
# Audio output switcher for the two outputs I use day to day: the Pebble
# speakers and the MiniFuse interface (headphones). Shared by the Waybar
# module and a Hyprland keybind.
#
# Usage:
#   audio-output.sh status    Emit Waybar JSON for the current default output.
#   audio-output.sh toggle    Flip the default output between Pebble and MiniFuse,
#                             moving every active stream to the new output.
#   audio-output.sh per-app   rofi flow to send a single app to a chosen output.

# Stable name patterns for my two preferred sinks. Matched against the sink
# name (column 2 of `pactl list sinks short`) so they survive ID changes and
# reconnects. The MiniFuse exposes several sinks; Line1 is its main output.
PEBBLE_PAT='Pebble'
MINIFUSE_PAT='MiniFuse.*Line1__sink'

# Icons, defined via \u escapes so the glyph codepoints survive editing.
# f028 = volume-up (speakers), f025 = headphones, f026 = volume-off (other).
PEBBLE_ICON=$(printf '')
MINIFUSE_ICON=$(printf '')
UNKNOWN_ICON=$(printf '')

# Resolve the actual sink name matching a pattern, or empty if not present.
sink_by_pattern() {
  pactl list sinks short | awk -v pat="$1" '$2 ~ pat { print $2; exit }'
}

# Move every active playback stream to the given sink.
move_all_streams() {
  local sink="$1"
  pactl list sink-inputs short | awk '{ print $1 }' | while read -r id; do
    [[ -n "$id" ]] && pactl move-sink-input "$id" "$sink" 2>/dev/null
  done
}

cmd_status() {
  local current pebble minifuse icon class label
  current=$(pactl get-default-sink)
  pebble=$(sink_by_pattern "$PEBBLE_PAT")
  minifuse=$(sink_by_pattern "$MINIFUSE_PAT")

  if [[ -n "$pebble" && "$current" == "$pebble" ]]; then
    icon="$PEBBLE_ICON"; class="pebble"; label="Pebble speakers"
  elif [[ -n "$minifuse" && "$current" == "$minifuse" ]]; then
    icon="$MINIFUSE_ICON"; class="minifuse"; label="MiniFuse headphones"
  else
    icon="$UNKNOWN_ICON"; class="other"
    label=$(pactl list sinks | awk -v n="$current" '
      /^[[:space:]]*Name:/ { name=$2 }
      /^[[:space:]]*Description:/ { sub(/^[[:space:]]*Description:[[:space:]]*/,""); if (name==n) { print; exit } }')
  fi

  printf '{"text": "%s", "class": "%s", "tooltip": "Output: %s"}\n' "$icon" "$class" "$label"
}

cmd_toggle() {
  local current pebble minifuse target
  current=$(pactl get-default-sink)
  pebble=$(sink_by_pattern "$PEBBLE_PAT")
  minifuse=$(sink_by_pattern "$MINIFUSE_PAT")

  # If currently on Pebble, switch to MiniFuse; otherwise switch to Pebble.
  # This means a third device also toggles back to Pebble.
  if [[ -n "$pebble" && "$current" == "$pebble" ]]; then
    target="$minifuse"
  else
    target="$pebble"
  fi

  if [[ -z "$target" ]]; then
    notify-send -a "Audio" "Audio output" "Target output not connected" 2>/dev/null
    exit 1
  fi

  pactl set-default-sink "$target"
  move_all_streams "$target"
}

cmd_per_app() {
  # Stage 1: pick an active playback stream.
  local inputs id app media menu choice sink_menu sink_choice sink
  declare -A input_label
  menu=""
  while read -r id; do
    [[ -z "$id" ]] && continue
    app=$(pactl list sink-inputs | awk -v id="$id" '
      $0 ~ "Sink Input #"id"$" { found=1 }
      found && /application.name = / { gsub(/.*= "|"$/,""); print; exit }')
    media=$(pactl list sink-inputs | awk -v id="$id" '
      $0 ~ "Sink Input #"id"$" { found=1 }
      found && /media.name = / { gsub(/.*= "|"$/,""); print; exit }')
    local label="${app:-Stream $id}"
    [[ -n "$media" ]] && label="$label — $media"
    input_label["$label"]="$id"
    menu+="$label"$'\n'
  done < <(pactl list sink-inputs short | awk '{ print $1 }')

  if [[ -z "$menu" ]]; then
    notify-send -a "Audio" "Audio output" "No apps are currently playing" 2>/dev/null
    exit 0
  fi

  choice=$(printf '%s' "$menu" | rofi -dmenu -i -p "Move app")
  [[ -z "$choice" ]] && exit 0
  id="${input_label[$choice]}"
  [[ -z "$id" ]] && exit 0

  # Stage 2: pick a destination sink (by description).
  declare -A sink_name
  sink_menu=""
  while IFS=$'\t' read -r desc name; do
    [[ -z "$name" ]] && continue
    sink_name["$desc"]="$name"
    sink_menu+="$desc"$'\n'
  done < <(pactl list sinks | awk '
    /^[[:space:]]*Name:/ { name=$2 }
    /^[[:space:]]*Description:/ { sub(/^[[:space:]]*Description:[[:space:]]*/,""); print $0 "\t" name }')

  sink_choice=$(printf '%s' "$sink_menu" | rofi -dmenu -i -p "Send to")
  [[ -z "$sink_choice" ]] && exit 0
  sink="${sink_name[$sink_choice]}"
  [[ -z "$sink" ]] && exit 0

  pactl move-sink-input "$id" "$sink"
}

case "$1" in
  status)  cmd_status ;;
  toggle)  cmd_toggle ;;
  per-app) cmd_per_app ;;
  *) echo "Usage: $0 {status|toggle|per-app}" >&2; exit 1 ;;
esac
