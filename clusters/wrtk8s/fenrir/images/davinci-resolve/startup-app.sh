#!/bin/bash
set -e
source /opt/gow/launch-comp.sh
# Resolve is X11-only; run it under sway's Xwayland.
export QT_QPA_PLATFORM=xcb
launcher /opt/resolve/bin/resolve
