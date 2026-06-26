{ lib
, stdenv
, fetchurl
}:

let
  moduleVersion = "0.34.0";

  modules = {
    x86_64-linux = {
      asset = "ghostel-module-x86_64-linux.so";
      hash = "sha256-VhuKgSi/GszlalJjUMfvBWycDJEzutuf6g1hu165QyE=";
    };
    aarch64-linux = {
      asset = "ghostel-module-aarch64-linux.so";
      hash = "sha256-1ZaFFmLAwY/mYLbaim16zEp0bHGousjrS/WoJldyrFo=";
    };
    x86_64-darwin = {
      asset = "ghostel-module-x86_64-macos.dylib";
      hash = "sha256-3+DbexbhTfgYUIrz78R8TyJOD1tDOsc2J3dYahCLr9Q=";
    };
    aarch64-darwin = {
      asset = "ghostel-module-aarch64-macos.dylib";
      hash = "sha256-z7mTLgaf+c2hXWQrO8P1yUni6Yok6MRznXDwPS8j1qg=";
    };
  };

  system = stdenv.hostPlatform.system;
  module = modules.${system} or
    (throw "ghostel: no prebuilt native module for system ${system}");

  prebuiltModule = fetchurl {
    url = "https://github.com/dakra/ghostel/releases/download/v${moduleVersion}/${module.asset}";
    inherit (module) hash;
  };

  libExt = stdenv.hostPlatform.extensions.sharedLibrary;
in
elisp: elisp.overrideAttrs (_: {
  preBuild = ''
    install -m444 ${prebuiltModule} ghostel-module${libExt}
  '';
})
