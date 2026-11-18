#!/bin/bash
# Runs as root before the session user starts.
source /opt/gow/bash-lib/utils.sh
gow_log "**** GNOME prerequisites ****"
rm -rf /run/systemd/seats
# Mutter's Xwayland refuses an X socket dir without the sticky bit.
mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
# GNOME components (accounts, polkit lookups) expect a system bus.
if [ ! -S /run/dbus/system_bus_socket ]; then
  mkdir -p /run/dbus && dbus-daemon --system --fork || gow_log "system dbus failed to start"
fi
gow_log "DONE"
