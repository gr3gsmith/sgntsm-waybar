#!/usr/bin/env bash
# Toggle the resident pavucontrol popup on its special workspace ("audio"),
# positioned just below the Waybar audio module.
#
# A resident pavucontrol is launched onto special:audio (hidden) and kept there;
# toggling is a single atomic `togglespecialworkspace`, so it's smooth and safe
# to click rapidly. Just before showing it, we position the window under the
# audio module on whichever monitor is focused -- Hyprland's `move` window rule
# only accepts absolute pixels (no monitor-relative expressions), so the per-
# monitor maths is done here instead.
#
# Usage:
#   audio-pavu.sh          Toggle the popup (used by the module's right-click).
#   audio-pavu.sh ensure   Launch the resident instance if missing, leave hidden
#                          (used by autostart at login).

WS=audio
CLASS=org.pulseaudio.pavucontrol

WIN_W=700
WIN_H=500
# Distance from a monitor's right edge to the audio module's centre. Increase to
# slide the popup left, decrease to slide it right.
MODULE_CENTER_FROM_RIGHT=360
TOP_GAP=6   # vertical gap between the bar and the popup

launch_rule="[workspace special:$WS silent; float; size $WIN_W $WIN_H]"

addr_on_special() {
  hyprctl clients -j | jq -r --arg c "$CLASS" --arg w "special:$WS" \
    'first(.[] | select(.class == $c and .workspace.name == $w) | .address) // empty'
}

# Ensure the resident instance exists, waiting briefly for its window if we had
# to launch it (so the first toggle can position it correctly).
addr=$(addr_on_special)
if [ -z "$addr" ]; then
  hyprctl dispatch exec "$launch_rule" "uwsm app -- pavucontrol" >/dev/null
  for _ in $(seq 1 30); do
    addr=$(addr_on_special)
    [ -n "$addr" ] && break
    sleep 0.1
  done
fi

# Autostart path: leave it hidden and ready.
[ "$1" = ensure ] && exit 0

# Position the window under the module on the focused monitor, but only when
# we're about to show it (it isn't currently visible on any monitor).
if [ -n "$addr" ] &&
   [ "$(hyprctl monitors -j | jq -r --arg w "special:$WS" 'any(.[]; .specialWorkspace.name == $w)')" != true ]; then
  read -r mx my mw rtop < <(hyprctl monitors -j |
    jq -r 'first(.[] | select(.focused)) | "\(.x) \(.y) \(.width) \([.reserved[]] | max)"')
  x=$(( mx + mw - MODULE_CENTER_FROM_RIGHT - WIN_W / 2 ))
  y=$(( my + rtop + TOP_GAP ))
  hyprctl dispatch movewindowpixel "exact $x $y,address:$addr"
fi

hyprctl dispatch togglespecialworkspace "$WS"
