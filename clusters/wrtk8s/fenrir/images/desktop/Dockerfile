# GNOME desktop for Fenrir sessions on 3d: GOW's Steam image (Steam plus its
# container fixes) + GNOME Shell nested in GOW's sway + Firefox + the runtime
# libraries DaVinci Resolve needs. Resolve itself is NOT baked in (~15 GB):
# the resolve-install Job puts it on logan's home volume and Apps mount it
# at /opt/resolve.
#
# DESKTOP_APP picks what a session starts: gnome (default) | steam | resolve
#
#   docker buildx build --platform linux/amd64 \
#     -t cr.jgarr.net/fenrir/desktop:latest --push .
FROM ghcr.io/games-on-whales/steam:edge

# Firefox from Mozilla's APT repo (Ubuntu's package is a snap shim).
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla

RUN apt-get update && apt-get install -y --no-install-recommends \
      gnome-shell gnome-session gnome-settings-daemon gnome-control-center \
      gnome-terminal nautilus gnome-text-editor gnome-system-monitor \
      gnome-shell-extension-ubuntu-dock gnome-shell-extension-desktop-icons-ng \
      xdg-desktop-portal-gnome xdg-user-dirs-gtk dbus-x11 \
      adwaita-icon-theme yaru-theme-gtk yaru-theme-icon yaru-theme-gnome-shell \
      yaru-theme-sound ubuntu-wallpapers fonts-ubuntu \
      firefox unzip \
      # DaVinci Resolve runtime deps
      libapr1t64 libaprutil1t64 libasound2t64 libglib2.0-0t64 \
      libxcb-composite0 libxcb-cursor0 libxcb-damage0 libxcb-xinerama0 \
      libxcb-xinput0 libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 \
      libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
      libxcb-xfixes0 libxcb-xkb1 libglu1-mesa ocl-icd-libopencl1 \
      libxtst6 libsm6 \
    && rm -rf /var/lib/apt/lists/* \
    # Package installs leave this behind; GNOME Shell takes it to mean
    # systemd-logind is running and dies calling login1.
    && rm -rf /run/systemd/seats

# Keep GOW's Steam startup reachable; our dispatcher replaces startup-app.sh.
RUN mv /opt/gow/startup-app.sh /opt/gow/startup-steam.sh
COPY startup-app.sh gnome-session.sh /opt/gow/
COPY cont-init-gnome.sh /etc/cont-init.d/40-gnome.sh
COPY sway-gnome.conf /etc/sway/config.d/gnome.conf
COPY resolve.desktop /usr/share/applications/com.blackmagicdesign.resolve.desktop
COPY 90-fenrir.gschema.override /usr/share/glib-2.0/schemas/
# NVIDIA 595 EGL only initializes on Wayland through egl-wayland2; the base
# image's 10_nvidia_wayland.json (egl-wayland 1.x) fails, so glvnd fell back
# to Mesa zink. The library itself is injected by the NVIDIA container toolkit.
COPY 09_nvidia_wayland2.json /usr/share/egl/egl_external_platform.d/
RUN chmod +x /opt/gow/startup-app.sh /opt/gow/gnome-session.sh /etc/cont-init.d/40-gnome.sh && \
    glib-compile-schemas /usr/share/glib-2.0/schemas
