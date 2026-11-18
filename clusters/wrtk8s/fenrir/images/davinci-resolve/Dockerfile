# DaVinci Resolve on the games-on-whales app base (Ubuntu 25.04, sway +
# Xwayland). Blackmagic's installer isn't redistributable: drop the
# downloaded DaVinci_Resolve_*_Linux.zip next to this file, then
#   docker buildx build --platform linux/amd64 -t cr.jgarr.net/fenrir/davinci-resolve:latest --push .
FROM ghcr.io/games-on-whales/base-app:edge

RUN apt-get update && apt-get install -y --no-install-recommends \
      unzip libapr1t64 libaprutil1t64 libasound2t64 libglib2.0-0t64 \
      libxcb-composite0 libxcb-cursor0 libxcb-damage0 libxcb-xinerama0 \
      libxcb-xinput0 libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 \
      libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
      libxcb-xfixes0 libxcb-xkb1 libgl1 libegl1 libglu1-mesa ocl-icd-libopencl1 \
      libfontconfig1 libfreetype6 libxrender1 libxi6 libxtst6 libsm6 \
      xdg-utils fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

COPY DaVinci_Resolve_*_Linux.zip /tmp/resolve.zip
RUN cd /tmp && unzip -q resolve.zip && \
    ./DaVinci_Resolve_*_Linux.run --appimage-extract >/dev/null && \
    SKIP_PACKAGE_CHECK=1 ./squashfs-root/AppRun -i -y -a && \
    # Resolve bundles an old glib that breaks against Ubuntu's; use the system one.
    rm -f /opt/resolve/libs/libglib-2.0.so* /opt/resolve/libs/libgio-2.0.so* \
          /opt/resolve/libs/libgmodule-2.0.so* && \
    rm -rf /tmp/*

COPY startup-app.sh /opt/gow/startup-app.sh
RUN chmod +x /opt/gow/startup-app.sh
