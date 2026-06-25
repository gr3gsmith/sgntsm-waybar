#!/usr/bin/env bash
# Dismiss the pavucontrol popup when the user clicks outside it.
#
# Bound to a non-consuming left-click (bindn = ,mouse:272,...) so it runs on
# every click without swallowing it. It acts only when the popup is visible and
# the click landed outside the popup's rectangle -- a focus-based approach can't
# work here, because while the special workspace is active a click on empty
# space doesn't move focus to another window.

WS=audio
CLASS=org.pulseaudio.pavucontrol
SPECIAL="special:$WS"

# Monitor currently showing the popup, if any.
showing=$(hyprctl monitors -j | jq -r --arg w "$SPECIAL" \
  'first(.[] | select(.specialWorkspace.name == $w)) | .name // empty')
[ -z "$showing" ] && exit 0

# Popup rectangle (global coordinates).
read -r wx wy ww wh < <(hyprctl clients -j | jq -r --arg c "$CLASS" --arg w "$SPECIAL" \
  'first(.[] | select(.class == $c and .workspace.name == $w)) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"')
[ -z "$wx" ] && exit 0

# Cursor (global coordinates).
read -r cx cy < <(hyprctl cursorpos -j | jq -r '"\(.x) \(.y)"')

# Click inside the popup: leave it open.
if [ "$cx" -ge "$wx" ] && [ "$cx" -lt "$((wx + ww))" ] &&
   [ "$cy" -ge "$wy" ] && [ "$cy" -lt "$((wy + wh))" ]; then
  exit 0
fi

# Click outside: hide it. togglespecialworkspace acts on the focused monitor, so
# if the popup is on another monitor, focus it to toggle, then return focus.
focused=$(hyprctl monitors -j | jq -r 'first(.[] | select(.focused)) | .name')
if [ "$focused" = "$showing" ]; then
  hyprctl dispatch togglespecialworkspace "$WS"
else
  hyprctl --batch "dispatch focusmonitor $showing ; dispatch togglespecialworkspace $WS ; dispatch focusmonitor $focused"
fi
