# chopper: ELAN7001 SPI fingerprint reader (shelved)

Status: **shelved, not enabled.** The reader is reachable and enrolls, but
matching is unreliable and it only supports *swipe* capture. It works
perfectly on Windows with a simple *tap*, so the goal for next time is
tap (press) capture. Re-enable by uncommenting `./parts/fingerprint.nix` in
`hosts/chopper/default.nix` (see "Re-enabling").

## Hardware

- Laptop: ASUS VivoBook X409JA (Ice Lake-LP), kernel 6.18.
- Sensor: ACPI `ELAN7001` at `\_SB.PCI0.SPI0.FPRT`, enumerated as
  `/sys/bus/spi/devices/spi-ELAN7001:00` on the Intel LPSS SPI controller
  `00:1e.2` (`8086:34aa`, `spi1`, driver `spi_pxa2xx`). No kernel driver binds it.
- `spi0.0` is the BIOS flash (`spi-nor`). **Do not touch it.**
- `hidraw0` is the ELAN *touchpad* (`04F3:30EF`, I2C). libfprint resets the
  sensor through it (HID feature report `{0x0e,0,0,0,0}`) and matches on its
  VID:PID.
- Sensor identity read over SPI: raw 96x96, register `0x17 = 0xAF` so IC
  version 1 -> libfprint table entry **`eFSA96SA`** (id 6, **OTP model**). An
  earlier note in this work said `eFSA96S` (non-OTP): that was wrong.
- ACPI (`dsdt-fprt-excerpt.asl`): SPI chip select 0, mode 0 (CPOL low, CPHA
  first), 8-bit, **12 MHz**. Reset GPIO `GNUM(0x0602000F)`, interrupt GPIO
  `GNUM(0x06030010)` (not needed: libfprint resets via HID and polls).

## What works

- Binding `spidev` to the sensor: `driver_override` = `spidev`, then
  `drivers_probe`. `/dev/spidev1.0` appears (root only).
- `elan_probe.py` (this directory) talks to the sensor from userspace:
  HID reset, soft reset `0x31`, reads status/height/width/version/reg17.
  Result: status `0x03` -> `0x01` after reset, 96x96, version/reg17 as above.
- libfprint's in-tree **`elanspi`** driver supports this sensor family; only
  this laptop's touchpad id `04F3:30EF` was missing from its match table.
- Enrollment completes and `fprintd-verify` matched sometimes (NBIS matcher:
  1 match in ~5, mostly `verify-no-match` / `verify-swipe-too-short`).

## What we tried, in order

1. **Match-table patch** for `04F3:30EF` (`NO_ROTATE` guess), spidev bind
   service, `services.fprintd`. Drivers loaded and enrolled.
2. **Thermal lockout.** libfprint's default thermal model (3 min active =
   "hot", then `Device disabled to prevent overheating`) trips because the
   sensor polls while waiting for a finger. Fixed with
   `dev_class->temp_hot_seconds = -1` in `elanspi.c`. Restarting fprintd also
   clears it.
3. **Rotation.** The driver cuts a 43-row strip from the sensor and the
   rotation value (plus an HV-flip bit for the 90-degree cases) chooses the
   axis. Captured images with `fp-img-capture` built per rotation
   (`imgcap-rotation-variant.nix`): `NO_ROTATE` = blobby short ridge pieces,
   **`90LEFT_ROTATE` = long continuous ridges with a visible core.** Adopted
   `ELANSPI_90LEFT_ROTATE`. Matching was still poor.
4. **Research** (below): libfprint's NBIS/bozorth3 matcher cannot tell fingers
   apart on narrow stitched swipe strips. People get this family working with
   **SIGFM** (SIFT/keypoint matcher) and/or **press mode**.
5. **SIGFM.** First tried the old goodix-fp-linux-dev `sigfm` fork (Jan 2023
   base): needs `nss`, `nspr`, `doctest`, a relaxed fprintd version gate
   (`>= 1.94.9`), `FP_DEVICE_RETRY_TOO_FAST`, and `sigfm.hpp` installed. It
   built, but a rebased tree is cleaner: `archeYR/libfprint-CS9711` branch
   `cs9711-rebase` at `3c93fc2d` = upstream **1.94.100 + SIGFM** (same base as
   nixpkgs; fprintd 1.94.5 builds against it unmodified). Patch:
   `hosts/chopper/parts/libfprint-elanspi-sigfm.patch` (30ef + 90LEFT, thermal
   opt-out, `FPI_DEVICE_ALGO_SIGFM`, `score_threshold = 100` (unverified,
   copied from another sensor), native-scale stitching without the 2x upscale
   or `FPI_IMAGE_PARTIAL`, light Gaussian smoothing). The full system built.
6. **Result with SIGFM: `fprintd-verify` hangs.** Debug log (`G_MESSAGES_DEBUG=all
   fprintd --no-timeout`): init/calibration are fine (`eFSA96SA`, OTP VCM mode
   2, "calibration ok, saving bg image"), but afterwards ~72% of frames are
   ambiguous (`<guess> ... is_fp=1, is_empty=1`, stddev ~1e6, 40-60% of pixels
   below background) and **never `is_fp=2`**, so the swipe is never
   recognised. A finger earlier read as `ip` 0-2 with stddev 1.5-2.5e6. Suspected
   cause (not confirmed): the background image is captured ~1.4 s after the
   verify command and can contain a finger already resting on the sensor. It
   never refreshes. A possible fix is to re-capture the background after a long
   all-below-background ("empty", `ip == 100`) stretch, or to gate calibration
   on a finger-free check. Not tried.

## Dead ends / gotchas

- `pkexec` has no setuid wrapper on this NixOS config. `sudo -A` with a zenity
  askpass (`environment.etc."sudo.conf"` in `desktop.nix`) is what works.
- fprintd's `net.reactivated.fprint.device.enroll` is denied for a plain
  terminal here; `sudo fprintd-enroll <user>` works. **Always pass the user:**
  without it `sudo` enrolls `root`.
- The overlay on the old fork replaced nixpkgs' `postPatch`
  (`patchShebangs tests`) and needed Python with `pygobject3` at configure
  time because `tests/unittest_inspector.py` imports `gi`.
- In the new SIGFM tree install steps run in the meson build dir, so source
  paths need `../`.
- A zsh `rm *.rej` with no matches aborted an `&&` chain and silently skipped
  applying a patch once; check the diff size.
- `pkill -f <pattern>` matches the shell running it. Use `pkill -x`.
- Swipe quality: slow (1-2 s), steady, same direction; the driver needs 8-21
  frames per swipe (`enroll-swipe-too-short` otherwise). Keep the hand off the
  sensor until the daemon has started.

## Security notes

- With the stock NBIS matcher a wrong finger may match (other users measured
  an impostor above the genuine range). Treat it as convenience only.
- `fprintAuth` defaults to `services.fprintd.enable` for *every* PAM service
  (login, greetd, hyprlock, polkit-1, su, sshd...), as `sufficient`. If it is
  re-enabled, set `security.pam.services.sudo.fprintAuth = false` (the module
  already does) and consider turning others off until false accepts are
  measured. Fingerprint login cannot unlock the keyring/1Password.
- Password fallback always remains, but pam_fprintd can delay it
  (`max-tries`/`timeout` can be set per service via PAM rule args).

## Next: tap (press) capture - research needed

Goal: reproduce what the Windows driver does (single touch, no swipe). The
hardware returns full 96x96 frames, so a press mode looks feasible; libfprint's
`elanspi` only implements swipe (`FP_SCAN_TYPE_SWIPE`, strip stitching).

Leads:

- **Press-mode ELAN7001 patches:** `ronnaldrangel/asus-vivobook-x1605za-fingerprint-linux`
  (80x80 `eFSA80SC`, press path + SIGFM, `FP_SCAN_TYPE_PRESS`),
  `Ajaneeshwar/x571gt-fingerprint` (press mode + SIGFM, `options spidev
  bufsiz=32768`, threshold 8), `r4nd3l/elan-3104-fingerprint-linux`
  (swipe + SIGFM; its `docs/MATCHING-ANALYSIS.md` explains why NBIS fails).
- **goodix-fp-linux-dev/libfprint open PRs for elanspi + SIGFM:** #44
  (3104, adaptive thresholds), #43 (3128), #41 (3212); SIGFM bug fixes #46
  (serialization buffer release) and #47 (match dedupe).
- `filip-rs/libfprint` branch `elanpress` (USB ELAN `04f3:0c6e`) for a press
  driver structure.
- `mincrmatt12/elan-spi-fingerprint`: original reverse engineering, prototype
  and `eFSA96SA` notes (touchpad PIDs 3057/30c6 use `180_ROTATE` and work with
  NBIS there).
- `buxel/libfprint-27c6-5110` (+ submodule `buxel/libfprint`, branch
  `goodixtls-on-1.94.9`): pure-C SIGFM (FAST-9 + BRIEF-256 + RANSAC, no
  OpenCV) with an offline benchmark method. Lesson: plain SIGFM scoring had
  a 45.7% false-accept rate until RANSAC inlier counting was added (FAR 0%,
  per-attempt FRR ~28%). Capture a labelled corpus, score offline, choose the
  threshold at 0% false accepts.
- Windows behaviour: its ELAN driver appears to use correlation/pattern
  matching with sub-templates, not NBIS minutiae. We chose not to decompile it.

Questions to answer:

1. How do the 96x96 SPI frames behave under a static finger (calibration,
   capture command `0x01` full frame, the "HV"/"old" capture paths in
   `elanspi.c`)? Capture and look at single frames, not stitched strips.
2. Does a single frame carry enough ridge area for SIGFM (80x80 sensors do in
   the reports above)?
3. How should finger-on/off be detected for press mode (the swipe
   `guess_image` heuristic is background-sensitive; see step 6)?

## Re-enabling

1. In `hosts/chopper/default.nix` uncomment `./parts/fingerprint.nix`.
2. `nh os switch`, then `sudo fprintd-delete <user>`, then
   `sudo fprintd-enroll -f right-index-finger <user>` (7+ slow swipes).
3. Debug: stop the service and run
   `sudo G_MESSAGES_DEBUG=all <fprintd-store-path>/libexec/fprintd --no-timeout`.
4. Images: `imgcap-rotation-variant.nix` builds `fp-img-capture` for a given
   rotation constant; stop fprintd first.

## Files

- `hosts/chopper/parts/fingerprint.nix` - module (spidev bind, fprintd, SIGFM
  libfprint); currently not imported.
- `hosts/chopper/parts/libfprint-elanspi-sigfm.patch` - the elanspi patch.
- `docs/fingerprint-elan7001/elan_probe.py` - SPI probe script.
- `docs/fingerprint-elan7001/imgcap-rotation-variant.nix` - scratch builder
  for `fp-img-capture` per rotation (hardcodes `/home/satan/nix-config`).
- `docs/fingerprint-elan7001/dsdt-fprt-excerpt.asl` - ACPI `FPRT` node.
