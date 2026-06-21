#!/bin/sh
# kexec-run.sh — kexec boot script for nixos-anywhere
#
# This script is bundled into the kexec tarball. It:
#   1. Extracts SSH authorized keys from the running system
#   2. Saves network configuration (IPs, routes)
#   3. Appends them to the initrd via cpio
#   4. Loads and executes the new kernel via kexec
#
# @init@ and @kernelParams@ are substituted by the Nix build.

set -eux
if set -o | grep -q pipefail; then
  set -o pipefail
fi

kexec_extra_flags=""

while [ $# -gt 0 ]; do
  case "$1" in
  --kexec-extra-flags)
    kexec_extra_flags="$2"
    shift
    ;;
  esac
  shift
done

# Provided by Nix substitution
init="@init@"
kernelParams="@kernelParams@"

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
INITRD_TMP=$(TMPDIR=$SCRIPT_DIR mktemp -d)

cd "$INITRD_TMP"
cleanup() {
  rm -rf "$INITRD_TMP"
}
trap cleanup EXIT
mkdir -p ssh

extractPubKeys() {
  home="$1"
  for file in .ssh/authorized_keys .ssh/authorized_keys2; do
    key="$home/$file"
    if test -e "$key"; then
      grep -o '\(\(ssh\|ecdsa\|sk\)-[^ ]* .*\)' "$key" >> ssh/authorized_keys || true
    fi
  done
}
extractPubKeys /root

if test -n "${DOAS_USER-}"; then
  SUDO_USER="$DOAS_USER"
fi

if test -n "${SUDO_USER-}"; then
  sudo_home=$(sh -c "echo ~$SUDO_USER")
  extractPubKeys "$sudo_home"
fi

# NixOS-style authorized keys directory
if test -e /etc/ssh/authorized_keys.d/root; then
  cat /etc/ssh/authorized_keys.d/root >> ssh/authorized_keys
fi
if test -n "${SUDO_USER-}" && test -e "/etc/ssh/authorized_keys.d/$SUDO_USER"; then
  cat "/etc/ssh/authorized_keys.d/$SUDO_USER" >> ssh/authorized_keys
fi

# Preserve SSH host keys so the kexec env has the same host identity
for p in /etc/ssh/ssh_host_*; do
  test -e "$p" || continue
  cp -a "$p" ssh
done

# Save network config for later restoration
"$SCRIPT_DIR/ip" --json addr > addrs.json
"$SCRIPT_DIR/ip" -4 --json route > routes-v4.json
"$SCRIPT_DIR/ip" -6 --json route > routes-v6.json

[ -f /etc/machine-id ] && cp /etc/machine-id machine-id

# Append saved state to initrd via cpio
find . | cpio -o -H newc | gzip -9 >> "$SCRIPT_DIR/initrd"

# Determine if we can use --kexec-syscall-auto (kernel >= 6.0)
kexecSyscallFlags=""
if printf "%s\n" "6.1" "$(uname -r)" | sort -c -V 2>&1; then
  kexecSyscallFlags="--kexec-syscall-auto"
fi

# Load the new kernel
if ! sh -c "'$SCRIPT_DIR/kexec' --load '$SCRIPT_DIR/bzImage' \
  $kexecSyscallFlags \
  $kexec_extra_flags \
  --initrd='$SCRIPT_DIR/initrd' --no-checks \
  --command-line 'init=$init $kernelParams'"
then
  echo "kexec failed, dumping dmesg" >&2
  dmesg | tail -n 100
  exit 1
fi

# Prepare to reboot
echo "machine will boot into nixos in 6s..."
if test -e /dev/kmsg; then
  exec > /dev/kmsg 2>&1
else
  exec > /dev/null 2>&1
fi

# Background the kexec -e so we can finish the script before the host goes down
nohup sh -c "sleep 6 && '$SCRIPT_DIR/kexec' -e ${kexec_extra_flags}" &
