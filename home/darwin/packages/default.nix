{ lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    mas
    vscode
    zoxide
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];
}
