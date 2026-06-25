#!/usr/bin/env bash
# Toggle pavucontrol in a dedicated Hyprland special workspace ("audio").
# Bound to the Waybar audio module's right-click for a mouse-friendly per-app
# routing UI. The keybind keeps the rofi per-app flow instead.
#
# Right-click opens the panel; right-click again closes it. Only the instance on
# special:audio is managed, so a pavucontrol opened any other way is untouched.

WS=audio
CLASS=org.pulseaudio.pavucontrol

# Address of a pavucontrol window already living on our special workspace.
addr=$(hyprctl clients -j | jq -r --arg c "$CLASS" --arg w "special:$WS" \
  'first(.[] | select(.class == $c and .workspace.name == $w) | .address) // empty')

if [ -n "$addr" ]; then
  # Panel is open: close it, then hide the now-empty workspace if it's showing.
  hyprctl dispatch closewindow "address:$addr"
  if hyprctl monitors -j | jq -e --arg w "special:$WS" \
      'any(.[]; .specialWorkspace.name == $w)' >/dev/null; then
    hyprctl dispatch togglespecialworkspace "$WS"
  fi
else
  # Show the (empty) special workspace, then launch pavucontrol with inline exec
  # rules so only this instance is floated and sent to special:audio.
  hyprctl dispatch togglespecialworkspace "$WS"
  hyprctl dispatch exec "[float; size 700 500; center; workspace special:$WS silent] pavucontrol"
fi
