{ lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
    with pkgs;
    [
      mas
      vscode
      zoxide
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.gke-gcloud-auth-plugin
      ])
    ]
  );
}
