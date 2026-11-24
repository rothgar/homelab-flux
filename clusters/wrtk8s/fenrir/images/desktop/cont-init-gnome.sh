#!/bin/bash
# Runs as root before the session user starts.
source /opt/gow/bash-lib/utils.sh
gow_log "**** GNOME prerequisites ****"
rm -rf /run/systemd/seats
# Mutter's Xwayland refuses an X socket dir without the sticky bit.
mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix
# No system bus here: the base image's system-services.sh starts it later
# in cont-init, and a second dbus-daemon there fails on the pid file and
# aborts the container.
gow_log "DONE"
# Resolve's common data dir (Studio activation state lives here); mounted
# from logan's home volume, so make it writable by the session user.
if [ -d /opt/resolve/bin ]; then
  mkdir -p "/var/BlackmagicDesign/DaVinci Resolve"
  chown -R "${PUID:-1000}:${PGID:-1000}" /var/BlackmagicDesign
fi
# Resolve Studio's RLM activation checks the native hostid (pinned via
# /etc/hostid) and the ethernet MAC; a pod's eth0 gets a random MAC every time,
# which invalidated the activation. Pin it (needs NET_ADMIN; veth allows a
# live change without dropping connectivity).
if [ -n "${FIXED_MAC:-}" ] && [ "$(cat /sys/class/net/eth0/address)" != "$FIXED_MAC" ]; then
  ip link set dev eth0 address "$FIXED_MAC" \
    && gow_log "eth0 MAC pinned to $FIXED_MAC" \
    || gow_log "could not pin eth0 MAC to $FIXED_MAC"
fi
