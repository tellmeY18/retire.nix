# super-productivity-bin — prebuilt release .app, skipping the source build
# (nixpkgs' super-productivity compiles 15 npm plugins from source, which is slow
# and hits a transient libuv/kqueue abort on macOS).
{ lib, stdenv, fetchurl, undmg }:

stdenv.mkDerivation rec {
  pname = "super-productivity-bin";
  version = "18.19.0";

  src = fetchurl {
    url = "https://github.com/super-productivity/super-productivity/releases/download/v${version}/superProductivity-arm64.dmg";
    hash = "sha256-b4Vvdod0kfL/gofbTaC4tppAcCPdgiSs2YUQ3dqoJS0=";
  };

  nativeBuildInputs = [ undmg ];

  dontStrip = true;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/Applications
    undmg "$src"
    cp -r "Super Productivity.app" "$out/Applications/"
  '';

  meta = {
    description = "To Do List / Time Tracker with Jira Integration";
    homepage = "https://super-productivity.com";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
