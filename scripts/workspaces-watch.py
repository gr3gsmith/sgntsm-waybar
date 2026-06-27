#!/usr/bin/env python3
"""Hidden Waybar "engine" for the custom workspaces module.

Streams Hyprland's event socket (.socket2.sock) and, whenever the workspace
or window layout changes, signals Waybar to re-run the workspace buttons.
The buttons are configured with "interval": "once" and "signal": 1, so a
single SIGRTMIN+1 to Waybar refreshes all of them at once.

This is the `exec` of the custom/ws-engine module, so it lives and dies with
Waybar -- there's no separate autostart process to manage. It prints one empty
JSON line so the engine module itself renders nothing.
"""
import ctypes
import fcntl
import os
import signal
import socket
import subprocess

SIGNAL = 1  # must match "signal": 1 on the custom/ws-* modules -> SIGRTMIN+1


def die_with_parent():
    """Ask the kernel to SIGTERM us if Waybar (our parent) dies, so we never
    linger as an orphan blocked on the event socket."""
    try:
        libc = ctypes.CDLL("libc.so.6", use_errno=True)
        PR_SET_PDEATHSIG = 1
        libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
    except Exception:
        pass

# Hyprland event names (text before ">>") that change which workspaces are
# active or occupied. Window focus changes (activewindow) are deliberately
# omitted -- they don't change the active/occupied set, so they'd only cause
# needless refreshes. startswith() also catches the "v2" variants.
REFRESH_PREFIXES = (
    "workspace",         # workspace / workspacev2 (switch)
    "createworkspace",   # new workspace appeared
    "destroyworkspace",  # workspace removed
    "moveworkspace",     # workspace moved between monitors
    "focusedmon",        # monitor focus changed
    "activespecial",     # special workspace toggled
    "openwindow",        # occupied state may change
    "closewindow",
    "movewindow",
)


def refresh():
    """Tell Waybar to re-run every module listening on SIGRTMIN+SIGNAL."""
    subprocess.run(["pkill", f"-RTMIN+{SIGNAL}", "waybar"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    die_with_parent()

    # The engine module renders nothing.
    print('{"text":""}', flush=True)

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

    # Waybar runs one bar per monitor, so this engine module is started once per
    # monitor. Only one needs to watch and signal refreshes; the rest grab no
    # lock and exit. (The lock fd is intentionally never closed so it's held for
    # the life of the winning process.)
    lock_fp = open(f"{runtime}/waybar-ws-watch.lock", "w")
    try:
        fcntl.flock(lock_fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # another watcher already owns the lock

    path = f"{runtime}/hypr/{sig}/.socket2.sock"

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)

    refresh()  # ensure buttons are correct right after startup

    buf = b""
    with sock:
        while True:
            data = sock.recv(4096)
            if not data:
                break  # socket closed (Hyprland exiting)
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                event = line.split(b">>", 1)[0].decode(errors="ignore")
                if event.startswith(REFRESH_PREFIXES):
                    refresh()


if __name__ == "__main__":
    main()
