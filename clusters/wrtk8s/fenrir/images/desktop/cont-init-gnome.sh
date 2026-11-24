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
# GNOME runs thumbnailers and glycin image decoders (Nautilus previews, Loupe)
# in bwrap --unshare-all, which mounts a fresh /proc. The NVIDIA container
# toolkit/CDI overmounts /proc/driver/nvidia/params, and the kernel refuses a
# new proc mount while one is layered over the old one. Needs the privileged
# container (see desktop.yaml).
if mountpoint -q /proc/driver/nvidia/params 2>/dev/null; then
  umount /proc/driver/nvidia/params \
    && gow_log "unmounted /proc/driver/nvidia/params for bwrap" \
    || gow_log "could not unmount /proc/driver/nvidia/params; previews and image viewers will fail"
fi
