# tmplayer-bin — TMPlayer desktop app (unofficial Telegram media player),
# repackaged from the upstream release tarball.
#
# A local stopgap until this is packaged properly for nixpkgs: the release
# tarball is a jpackage app image (bundled JRE + a Compose app), and the
# upstream Arch PKGBUILD (desktop/packaging/aur) is the reference for how it
# is laid out. TDLib and libmpv/ffmpeg live inside the app's jars and are
# extracted at run time, so the system libraries they dlopen are provided
# through LD_LIBRARY_PATH in the wrapper instead of by patching them.
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, makeWrapper
, alsa-lib
, fontconfig
, freetype
, libdrm
, libglvnd
, libpulseaudio
, libx11
, libxcb
, libxext
, libxi
, libxrender
, libxtst
, openssl
, vulkan-loader
, zlib
}:

let
  runtimeLibs = [
    alsa-lib
    fontconfig
    freetype
    libdrm
    libglvnd
    libpulseaudio
    libx11
    libxcb
    libxext
    libxi
    libxrender
    libxtst
    openssl
    stdenv.cc.cc.lib
    vulkan-loader
    zlib
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "tmplayer-bin";
  version = "1.28.5";

  src = fetchurl {
    url = "https://github.com/dracu-lah/TMPlayer/releases/download/v${finalAttrs.version}/TMPlayer-${finalAttrs.version}-linux-x64.tar.xz";
    hash = "sha256-1JRVymFRLAV72QmovDl22SCWV7aPs5n4JQqj2EldC3o=";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = runtimeLibs;

  # libskiko-linux-x64.so is verified against a bundled checksum, so it must
  # stay byte-identical: no stripping and no patching of it. Everything else
  # that needs an interpreter or RPATH is patched explicitly below.
  dontStrip = true;
  dontAutoPatchelf = true;

  installPhase = ''
    runHook preInstall

    app=$out/opt/tmplayer
    mkdir -p $app $out/bin $out/share
    cp -a bin lib $app/
    cp -a share/applications share/metainfo share/icons $out/share/
    install -Dm644 -t $out/share/licenses/tmplayer share/doc/tmplayer/*

    makeWrapper $app/bin/TMPlayer $out/bin/tmplayer \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}

    runHook postInstall
  '';

  postFixup = ''
    autoPatchelf $out/opt/tmplayer/bin $out/opt/tmplayer/lib/runtime $out/opt/tmplayer/lib/libapplauncher.so
  '';

  meta = {
    description = "Watch the videos in your Telegram chats while they download (unofficial client)";
    homepage = "https://tmplayer.org";
    changelog = "https://github.com/dracu-lah/TMPlayer/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode binaryBytecode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "tmplayer";
  };
})
