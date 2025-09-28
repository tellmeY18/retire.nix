{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    mas
    zoxide
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];
}
