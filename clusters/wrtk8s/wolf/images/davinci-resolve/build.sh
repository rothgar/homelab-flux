#!/bin/bash
# Build the DaVinci Resolve Studio image using the installer parked on
# the Synology /public/install/resolve share, push to cr.jgarr.net.
#
# Usage:
#   ./build.sh                       # default: Resolve 20.3.1
#   RESOLVE_VERSION=20.3.1 ./build.sh
#
# Requires: docker or podman on the workstation; NFS access to Synology
# /volume1/public/install/resolve.
set -euo pipefail

RESOLVE_VERSION="${RESOLVE_VERSION:-20.3.1}"
INSTALLER="DaVinci_Resolve_Studio_${RESOLVE_VERSION}_Linux.run"
SYNOLOGY_PATH="${SYNOLOGY_PATH:-10.1.1.4:/volume1/public/install/resolve}"
REGISTRY="${REGISTRY:-cr.jgarr.net}"
IMAGE="${REGISTRY}/wolf/davinci-resolve"

cd "$(dirname "$0")"

# Pull the installer into the build context (it has to be in the
# context because Docker can't read from an NFS bind outside it).
mkdir -p installer
if [[ ! -f "installer/${INSTALLER}" ]]; then
  echo "Mounting ${SYNOLOGY_PATH} to copy ${INSTALLER}..."
  tmp="$(mktemp -d)"
  trap 'sudo umount -l "$tmp" 2>/dev/null || true; rmdir "$tmp" 2>/dev/null || true' EXIT
  sudo mount -t nfs -o ro,nfsvers=4.1 "${SYNOLOGY_PATH}" "$tmp"
  cp "$tmp/${INSTALLER}" "installer/${INSTALLER}"
  sudo umount -l "$tmp"
  rmdir "$tmp"
  trap - EXIT
fi

docker build \
  --build-arg RESOLVE_VERSION="${RESOLVE_VERSION}" \
  --build-arg RESOLVE_INSTALLER="${INSTALLER}" \
  -t "${IMAGE}:${RESOLVE_VERSION}" \
  -t "${IMAGE}:latest" \
  .

docker push "${IMAGE}:${RESOLVE_VERSION}"
docker push "${IMAGE}:latest"

echo "Pushed ${IMAGE}:${RESOLVE_VERSION}"
