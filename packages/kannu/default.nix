# kannu-bin — prebuilt release .app for Kannu, a macOS notch utility that
# shows AI coding agent status (Cursor/Copilot/Codex/Claude) in the notch.
# https://github.com/libinmv/kannu — GPL-3.0, no nixpkgs derivation exists.
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "kannu-bin";
  version = "1.3.4";

  src = fetchurl {
    url = "https://github.com/libinmv/kannu/releases/download/v${version}/Kannu.${version}.dmg";
    hash = "sha256-8gSY6yIJ1mVrbTzdicanePM0jHnVtoQ0f/sdHq02X3o=";
  };

  dontStrip = true;
  sourceRoot = ".";

  # undmg doesn't support APFS-formatted DMGs (which this release uses), so
  # mount via hdiutil instead — same approach nixpkgs uses for lmstudio-bionic.
  unpackCmd = ''
    mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
    trap '/usr/bin/hdiutil detach "$mnt" -force; rm -rf "$mnt"' EXIT
    /usr/bin/hdiutil attach -nobrowse -mountpoint "$mnt" "$curSrc"
    cp -a "$mnt/Kannu.app" "$PWD/"
  '';

  installPhase = ''
    mkdir -p $out/Applications
    cp -r Kannu.app "$out/Applications/"
  '';

  meta = {
    description = "macOS notch utility showing AI coding agent status (Cursor/Copilot/Codex/Claude)";
    homepage = "https://kannu.app";
    license = lib.licenses.gpl3Only;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
