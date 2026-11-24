#!/bin/bash
# GNOME Shell nested in GOW's sway (as an Xwayland window that sway
# fullscreens). Apps launched from the shell inherit its own Wayland and
# Xwayland displays.
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_SESSION_TYPE=wayland
# Size of the nested GNOME monitor; matches the stream resolution.
export MUTTER_DEBUG_DUMMY_MODE_SPECS="${GAMESCOPE_WIDTH:-1920}x${GAMESCOPE_HEIGHT:-1080}@${GAMESCOPE_REFRESH:-60}"
# Steam games need the same env GOW's Steam startup sets.
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0
xdg-user-dirs-update || true
# D-Bus-activated apps (Nautilus, Loupe, Totem) inherit the session bus's
# activation environment, which dbus-run-session snapshots before GNOME Shell
# exists, so it points at sway's displays and their windows opened behind
# GNOME. gnome-session normally fixes this; without it, copy GNOME's
# WAYLAND_DISPLAY/DISPLAY/XAUTHORITY from one of the shell's children
# (mutter-x11-frames) into the activation environment once it's up.
exec dbus-run-session -- bash -c '
  /usr/libexec/gsd-xsettings & /usr/libexec/gsd-a11y-settings & /usr/libexec/gsd-color &
  /usr/libexec/gsd-keyboard & /usr/libexec/gsd-media-keys & /usr/libexec/gsd-sound &
  gnome-shell --nested --wayland & GS=$!
  (
    for _ in $(seq 120); do
      C=$(pgrep -P "$GS" -f mutter-x11-frames | head -1)
      if [ -n "$C" ]; then
        VARS=$(tr "\0" "\n" < "/proc/$C/environ" | grep -E "^(WAYLAND_DISPLAY|DISPLAY|XAUTHORITY)=")
        if [ -n "$VARS" ]; then
          dbus-update-activation-environment $VARS XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
          break
        fi
      fi
      sleep 1
    done
  ) &
  wait "$GS"'
