{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mas
    zoxide
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];
}
