#!/bin/bash
set -e
source /opt/gow/bash-lib/utils.sh
source /opt/gow/launch-comp.sh

case "${DESKTOP_APP:-gnome}" in
  steam)
    exec /opt/gow/startup-steam.sh ;;
  resolve)
    gow_log "Starting DaVinci Resolve"
    export QT_QPA_PLATFORM=xcb
    launcher /opt/resolve/bin/resolve ;;
  gnome)
    gow_log "Starting GNOME"
    launcher /opt/gow/gnome-session.sh ;;
  *)
    gow_log "Unknown DESKTOP_APP=${DESKTOP_APP}"; exit 1 ;;
esac
