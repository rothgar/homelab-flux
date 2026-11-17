# DaVinci Resolve Studio container for Wolf sessions on 3d.
#
# Build arg points at a Blackmagic .run installer the build context
# provides (we mount /public/install/resolve into the context at build
# time — see build.sh). The installer is extracted with
# `--appimage-extract` and then run with `-i -y -a` for a silent
# install into /opt/resolve. No EULA prompt because `SKIP_PACKAGE_CHECK`
# + `-y` auto-accepts for the already-downloaded bundle.
#
# Target runtime: Wolf session pod. Wolf injects a Wayland socket at
# $WAYLAND_DISPLAY and a PulseAudio socket at $PULSE_SERVER via CDI, so
# the entrypoint is just `resolve` with those env vars inherited.

ARG RESOLVE_VERSION=20.3.1
FROM ubuntu:24.04 AS stage

ARG RESOLVE_INSTALLER=DaVinci_Resolve_Studio_20.3.1_Linux.run
ENV DEBIAN_FRONTEND=noninteractive

# Resolve 20 prereqs on Ubuntu 24.04 — the installer refuses to run
# without libasound / libxcb-cursor / libxkbcommon0 / an OpenCL ICD, and
# fails silently on missing fuse for appimage extraction.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils fuse3 libfuse2t64 \
      libasound2t64 libgl1 libglu1-mesa \
      libxcb-cursor0 libxcb-xinput0 libxcb-xkb1 libxcb-randr0 \
      libxkbcommon0 libxkbcommon-x11-0 \
      libgtk-3-0 libglib2.0-0 libdrm2 libegl1 libwayland-client0 \
      ocl-icd-libopencl1 \
      libapr1t64 libaprutil1t64 \
      unzip \
      && rm -rf /var/lib/apt/lists/*

# Installer is mounted from the build context (populated from the
# Synology /public/install/resolve share by build.sh).
COPY installer/${RESOLVE_INSTALLER} /tmp/resolve.run
RUN chmod +x /tmp/resolve.run \
    && cd /tmp \
    && ./resolve.run --appimage-extract >/dev/null \
    && SKIP_PACKAGE_CHECK=1 ./squashfs-root/AppRun -i -y -a \
    && rm -rf /tmp/resolve.run /tmp/squashfs-root

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps only (no fuse/xz/curl needed at run time).
RUN apt-get update && apt-get install -y --no-install-recommends \
      libasound2t64 libgl1 libglu1-mesa \
      libxcb-cursor0 libxcb-xinput0 libxcb-xkb1 libxcb-randr0 \
      libxkbcommon0 libxkbcommon-x11-0 \
      libgtk-3-0 libglib2.0-0 libdrm2 libegl1 libwayland-client0 \
      ocl-icd-libopencl1 \
      libapr1t64 libaprutil1t64 \
      && rm -rf /var/lib/apt/lists/*

COPY --from=stage /opt/resolve /opt/resolve

# Wolf injects XDG_RUNTIME_DIR / WAYLAND_DISPLAY / PULSE_SERVER, so
# Resolve just needs to find its libs. Resolve expects /opt/resolve/bin
# on PATH; its binary resolves against /opt/resolve/libs.
ENV PATH=/opt/resolve/bin:${PATH} \
    LD_LIBRARY_PATH=/opt/resolve/libs:/opt/resolve/libs/plugins:${LD_LIBRARY_PATH}

ENTRYPOINT ["/opt/resolve/bin/resolve"]
