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
exec dbus-run-session -- bash -c '
  /usr/libexec/gsd-xsettings & /usr/libexec/gsd-a11y-settings & /usr/libexec/gsd-color &
  /usr/libexec/gsd-keyboard & /usr/libexec/gsd-media-keys & /usr/libexec/gsd-sound &
  exec gnome-shell --nested --wayland'
