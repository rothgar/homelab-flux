# Fenrir game streaming (3d)

Moonlight game and desktop streaming from **3d** (RTX 3060, Talos), built on
[Games on Whales Fenrir](https://github.com/games-on-whales/fenrir): a
Kubernetes-native [Wolf](https://games-on-whales.github.io/wolf/). A paired
Moonlight client lists the Apps in its Profile. Launching one makes the
operator start a pod for that App, and wolf-agent encodes its display with
NVENC and streams it to the client.

## Architecture

```
Moonlight client ──47984/47989──▶ moonlight-proxy (hostNetwork, 3d)
        │                                 │ Pairing / Profile / App CRs
        │                                 ▼
        │                         direwolf-operator ──▶ Lobby + StatefulSet per App
        │                                                    │ (app pod on 3d)
        └──RTSP 48010 / RTP UDP──▶ wolf-agent (hostNetwork, 3d) ◀─ Wayland socket
                                   wolf + agent, NVENC (h265/av1)
```

| Component | Image | Notes |
| --- | --- | --- |
| `direwolf-operator` | `cr.jgarr.net/fenrir/operator:dev` | Reconciles Apps, Profiles, Sessions and Lobbies. Pinned to amd64. |
| `moonlight-proxy` | `cr.jgarr.net/fenrir/moonlight-proxy:dev` | GameStream HTTP/HTTPS endpoint. `hostNetwork` on 3d. |
| `wolf-agent` | `cr.jgarr.net/fenrir/wolf-agent:dev` + `ghcr.io/games-on-whales/wolf:stable` | Persistent pod (not one per session). Publishes `wolf.dra.io` devices. `hostNetwork` so RTSP/RTP sit on 3d's LAN IP. |
| `generic-device-plugin-gaming` | `ghcr.io/squat/generic-device-plugin` | Exposes `/dev/uinput` as `devic.es/uinput` for virtual input. |
| `app-image-prepull` | DaemonSet | Keeps app images cached on 3d so a cold pull doesn't blow the proxy's 25s launch deadline. |

The operator, proxy and wolf-agent are built from the fork at
`~/src/fenrir` (`git@github.com:rothgar/fenrir.git`, remote `upstream` =
`games-on-whales/fenrir`). It tracks upstream's post-DRA code
(`feature/direwolf-dra`) plus our fixes. Those fixes are also open upstream:

- [#66](https://github.com/games-on-whales/fenrir/pull/66): k8s client QPS/Burst
- [#67](https://github.com/games-on-whales/fenrir/pull/67): return `<resume>` on `/resume`
- [#68](https://github.com/games-on-whales/fenrir/pull/68) (draft): taint the node while a session is live

### GPU

- The GPU goes through **DRA**, not `nvidia.com/gpu`. The ResourceClaim
  `shared-nvidia-gpu` (in `wolf-agent.yaml`, `gpu.nvidia.com` class) is shared
  by wolf-agent and every App pod.
- The `default-wolf` DeviceClass (`deviceclass.yaml`) sets
  `video_producer_buffer_caps` to CUDA memory. Without it, the NVIDIA encoder
  gets no frames and clients see a black screen.
- The `egl-glvnd-nvidia` ConfigMap supplies `10_nvidia.json`. The DRA driver
  doesn't inject it the way the classic toolkit does, so EGL fell back to Mesa
  and failed.
- All pods use `runtimeClassName: nvidia`. App pods also set
  `GBM_BACKENDS_PATH=/usr/lib/gbm` and `NVIDIA_DRIVER_CAPABILITIES=all`.

### Node: 3d

Defined in `../cluster.yaml` (machine `c828b893…`) and `../patches/3d.yaml`:

- Extensions: `nonfree-kmod-nvidia-production`,
  `nvidia-container-toolkit-production`, `iscsi-tools`, `uinput`, `uhid` and
  `joydev`.
- EPHEMERAL is capped at **50 GiB**. That's where images live, so keep big
  things out of images.
- The `home` UserVolume takes the rest of the NVMe and mounts at
  `/var/mnt/home`.
- Label `games-on-whales.io/gaming=true`, taint
  `dedicated=gaming:PreferNoSchedule`.
- `KernelModuleConfig uinput`.
- `SysctlConfig user.max_user_namespaces=11255`. Steam won't start without it.

Changes to `cluster.yaml` or the patches **don't apply on git push**. Sync them
by hand:

```sh
source ~/.talos/omni/omni.env
omnictl cluster template diff -f clusters/wrtk8s/cluster.yaml
omnictl cluster template sync -f clusters/wrtk8s/cluster.yaml
```

## User and storage

There is a single Profile, **`logan`** (`profile.yaml`), with every App.

`home.yaml` makes these objects, all `Retain`, so deleting them never touches
data:

- StorageClass `local-3d`
- PV `3d-home`, a hostPath of `/var/mnt/home` pinned to 3d
- PVC `logan-home`

Every App mounts `logan-home` at `/home/logan` with `UNAME=logan`. The home is
the one restored from the old Ubuntu install, so the absolute paths in the
Steam install (`~/.steam/debian-installation`, `libraryfolders.vdf`) still
resolve.

| Path on the volume | Mounted at | Contents |
| --- | --- | --- |
| `/` | `/home/logan` | dotfiles, Steam library, Resolve projects/media |
| `.fenrir/opt-resolve` | `/opt/resolve` | DaVinci Resolve Studio install (~15 GB, too big for EPHEMERAL) |
| `.fenrir/var-blackmagicdesign` | `/var/BlackmagicDesign` | Resolve machine-wide state, including Studio activation |

## Apps

| App | id | Image | What it runs |
| --- | --- | --- | --- |
| `firefox` | 1 | `ghcr.io/games-on-whales/firefox:edge` | Firefox |
| `steam` | 2 | `ghcr.io/games-on-whales/steam:edge` | Steam Big Picture under sway |
| `desktop` | 4 | `cr.jgarr.net/fenrir/desktop:latest` | GNOME 48 (nested in sway), with Firefox, Steam and Resolve in the dock |
| `davinci-resolve` | 5 | `cr.jgarr.net/fenrir/desktop:latest` | Resolve directly, no desktop |

Every App template has:

- `nodeSelector games-on-whales.io/gaming=true`
- the `shared-nvidia-gpu` claim
- `devic.es/uinput: 1`
- `cpu: 2` requested
- no `volumeClaimTemplates`

Steam, Desktop and Resolve also get:

- caps `SYS_ADMIN`, `SYS_NICE`, `SYS_PTRACE`, `NET_RAW`, `MKNOD` and `NET_ADMIN`
- seccomp/apparmor `Unconfined` (needed by Steam's bwrap)
- a 4Gi memory `emptyDir` at `/dev/shm`. The 64Mi default gives Steam's CEF UI
  a black screen.

`steam.yaml` also ships the `sway-steam` ConfigMap, which forces the
`Steam Big Picture Mode` window fullscreen. Without it, quitting a game left a
blank screen with Big Picture at 0x0.

### Desktop image (`images/desktop/`)

The image is `FROM ghcr.io/games-on-whales/steam:edge` and adds:

- GNOME Shell, with the Ubuntu dock and desktop-icons extensions
- the Yaru theme
- Firefox from Mozilla's APT repo (Ubuntu's `firefox` package is a snap shim)
- the libraries Resolve needs at runtime

`startup-app.sh` switches on `DESKTOP_APP`:

- `steam`: GOW's original startup (renamed to `startup-steam.sh`)
- `gnome`: `gnome-session.sh` runs `gnome-shell --nested --wayland` inside
  GOW's sway launcher. The window size comes from
  `MUTTER_DEBUG_DUMMY_MODE_SPECS`, and the sway rule in `sway-gnome.conf`
  makes it fullscreen.
- `resolve`: `/opt/resolve/bin/resolve` with `QT_QPA_PLATFORM=xcb`

`cont-init-gnome.sh` runs as root at start. It works around what nested GNOME
needs:

- removes `/run/systemd/seats`, otherwise mutter tries logind
- creates `/tmp/.X11-unix` with mode 1777
- starts a system D-Bus
- fixes ownership of `/var/BlackmagicDesign`

`90-fenrir.gschema.override` sets the dock favourites and turns off the
screen lock, idle blanking and Tracker indexing.

Build and push the image (amd64 only, because the GOW steam base is):

```sh
cd clusters/wrtk8s/fenrir/images/desktop
docker buildx build --platform linux/amd64 -t cr.jgarr.net/fenrir/desktop:latest --push .
kubectl -n direwolf-dev rollout restart ds/app-image-prepull   # re-cache on 3d
```

### DaVinci Resolve install

Resolve isn't baked into the image; it goes onto logan's volume. To install or
upgrade it:

1. Put the zip on the Synology share `public/install/resolve`.
2. Set `RESOLVE_ZIP` in `jobs/resolve-install.yaml`.
3. Run the Job (it isn't part of the kustomization):

```sh
kubectl -n direwolf-dev delete job resolve-install --ignore-not-found
kubectl apply -f clusters/wrtk8s/fenrir/jobs/resolve-install.yaml
kubectl -n direwolf-dev logs -f job/resolve-install
```

The Job:

1. Extracts the AppImage installer and installs it headless into
   `/opt/resolve`.
2. Patches Resolve to link the system glib/gdk-pixbuf/gio/gmodule.
3. Disables the BRAW OpenCL decoders, the same fixes davincibox applies.
4. Chowns everything to 1000:1000.

Studio may ask to be activated again the first time it runs in a container.

## Operations

### Pair a new device

1. Pair from Moonlight as usual. The proxy creates a `Pairing` CR.
2. Find it with `kubectl -n direwolf-dev get pairings`.
3. Add its name to `spec.pairings` in `profile.yaml` and commit. Flux owns the
   Profile, so an edit made with kubectl is overwritten on the next
   reconcile. Re-pairing the same machine reuses its Pairing CR.

### Add an App

1. Copy an existing App manifest and give it a unique `spec.id`.
2. Add the file to `kustomization.yaml` and the App name to `profile.yaml`.
3. If it uses a new image, also add the image to `image-prepull.yaml`.

### Health checks

```sh
kubectl -n direwolf-dev get pods,lobbies,sessions -o wide
kubectl -n direwolf-dev logs deploy/wolf-agent -c wolf | grep -E 'nvh26|nvav1|x264'   # want NVENC, not x264
kubectl debug node/3d -it --image=busybox -- cat /proc/sys/user/max_user_namespaces  # 11255
```

## Known issues

- **One live session per Profile.** The session ID is per Profile, so
  resuming the same stream from a second device crashes wolf (exit 11, crash
  loop). Quit on one device before starting on another. To recover, restart
  wolf-agent and delete the Lobby.
- **Pairings live in git.** The proxy never writes `Profile.spec.pairings`.
- **Launch deadline is 25s.** That's why images are pre-pulled. Upstream
  #52 makes it configurable.
- **GPU sharing isn't enforced.** Priority-based preemption doesn't work here,
  because the 3060 is advertised twice: once through DRA and once through the
  device plugin's `nvidia.com/gpu`. Other GPU pods (bambustudio) can still land
  on 3d through the `PreferNoSchedule` taint. Draft PR #68 adds a NoExecute
  taint while a session is live.
- **Steam has no CPU limit**, so it can starve wolf on the 12-core box.
- **DLSS under Proton isn't set up.** The Talos NVIDIA extension removes the
  `nvngx.dll` bridge. See
  [biggs.dog's notes](https://github.com/shrinedogg/biggs.dog/blob/main/docs/NOTES.md#dreamcast-on-kubernetes-implementation-notes)
  for a fix: an `nvngx-bridge` initContainer plus `PROTON_ENABLE_NVAPI=1`.
- **Gamepad hotplug is untested.** Steam isn't privileged. If pads don't show
  up in Big Picture, look at per-session `/dev/input` (fake-udev) or a
  privileged Steam container.
