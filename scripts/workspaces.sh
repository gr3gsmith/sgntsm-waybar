#!/usr/bin/env bash
# Custom Waybar workspaces module -- a replacement for the built-in
# hyprland/workspaces module, whose click handler still emits the legacy
# dispatcher syntax ("dispatch workspace N") that Hyprland's Lua config rejects.
# See Alexays/waybar#5008. Swap back to the built-in module once that ships.
#
# A Waybar custom module is a single widget, so each workspace is its own
# `custom/ws-*` module. This one script serves all of them via two subcommands:
#
#   workspaces.sh button N [MON]   Emit Waybar JSON for workspace N.
#   workspaces.sh button magic [MON]
#       If MON is given (per-monitor bars, see modules/workspaces-split.jsonc),
#       the button shows ONLY when workspace N is currently on monitor MON. That
#       way each monitor's bar shows its own workspaces, and when monitor-toggle
#       collapses everything onto one monitor, that monitor's bar shows them all.
#       With no MON (the combined module, modules/workspaces-custom.jsonc), it
#       shows whenever the workspace is occupied or active on any monitor.
#       Empty + not shown -> empty text, which Waybar hides.
#
#   workspaces.sh switch N         Switch to workspace N (or toggle the magic
#   workspaces.sh switch magic     special) via the Lua dispatcher.
#
# Refreshes are driven by workspaces-watch.py (the hidden `ws-engine` module).

cmd=$1
arg=$2

case "$cmd" in
  switch)
    if [ "$arg" = magic ]; then
      hyprctl dispatch "hl.dsp.workspace.toggle_special('magic')" >/dev/null
    else
      # Focusing a workspace on another monitor warps the cursor (and, with
      # follow_mouse, focus) over to it. Save the cursor position, switch, then
      # restore it -- so clicking another monitor's workspace just changes what
      # that monitor shows and leaves you where you are. Same-monitor clicks
      # don't warp, so this is a harmless no-op for them.
      pos=$(hyprctl cursorpos -j 2>/dev/null)
      hyprctl dispatch "hl.dsp.focus({ workspace = $arg })" >/dev/null
      if [ -n "$pos" ]; then
        x=$(printf '%s' "$pos" | jq -r '.x // empty')
        y=$(printf '%s' "$pos" | jq -r '.y // empty')
        [ -n "$x" ] && [ -n "$y" ] &&
          hyprctl dispatch "hl.dsp.cursor.move({ x = $x, y = $y })" >/dev/null
      fi
    fi
    ;;

  button)
    mon=$3

    if [ "$arg" = magic ]; then
      if [ -n "$mon" ]; then
        # Per-monitor: show only when magic is visible on THIS monitor.
        active=$(hyprctl monitors -j | jq -r --arg m "$mon" 'any(.[]; .name == $m and .specialWorkspace.name == "special:magic")')
        if [ "$active" = true ]; then printf '{"text":"★","class":"ws-active"}\n'
        else printf '{"text":""}\n'; fi
      else
        active=$(hyprctl monitors -j   | jq -r 'any(.[]; .specialWorkspace.name == "special:magic")')
        exists=$(hyprctl workspaces -j | jq -r 'any(.[]; .name == "special:magic")')
        if [ "$active" = true ]; then printf '{"text":"★","class":"ws-active"}\n'
        elif [ "$exists" = true ]; then printf '{"text":"★"}\n'
        else printf '{"text":""}\n'; fi
      fi
      exit 0
    fi

    # Numbered workspace N. jq's any(...) returns "true"/"false".
    if [ -n "$mon" ]; then
      # Show only if workspace N is currently living on monitor MON.
      on_mon=$(hyprctl workspaces -j | jq -r --argjson n "$arg" --arg m "$mon" 'any(.[]; .id == $n and .monitor == $m)')
      if [ "$on_mon" != true ]; then printf '{"text":""}\n'; exit 0; fi
      active=$(hyprctl monitors -j | jq -r --argjson n "$arg" --arg m "$mon" 'any(.[]; .name == $m and .activeWorkspace.id == $n)')
    else
      # Combined: occupied (has windows) or active on any monitor.
      active=$(hyprctl monitors -j   | jq -r --argjson n "$arg" 'any(.[]; .activeWorkspace.id == $n)')
      occupied=$(hyprctl workspaces -j | jq -r --argjson n "$arg" 'any(.[]; .id == $n and .windows > 0)')
      if [ "$active" != true ] && [ "$occupied" != true ]; then printf '{"text":""}\n'; exit 0; fi
    fi

    if [ "$active" = true ]; then
      printf '{"text":"%s","class":"ws-active"}\n' "$arg"
    else
      printf '{"text":"%s"}\n' "$arg"
    fi
    ;;
esac
