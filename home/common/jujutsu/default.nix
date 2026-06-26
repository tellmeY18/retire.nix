{ pkgs
, config
, lib
, ...
}:

let
  inherit (config.home) homeDirectory;
  # GPG key fingerprint for satanvysakh identity
  # Generated on 2026-06-14 — key stored in secrets/laptop/jj-gpg-key.asc
  jjGpgKeyId = "FFACE3305061827C";
in
{
  home.packages = with pkgs; [
    gnupg
    sops
    jjui # TUI for jj (magit-style)
  ];

  programs.jujutsu = {
    enable = true;

    settings = {
      # ── User identity (jj-specific, separate from git) ─────────────
      user = {
        name = "satanvysakh";
        email = "satanvysakh@riseup.net";
      };

      signing = {
        sign-all = true;
        backend = "gpg";
        key = jjGpgKeyId;
      };


    };
  };

  # ── Import the dedicated jj GPG key on activation ────────────────
  # The encrypted key lives in the flake at secrets/laptop/jj-gpg-key.asc
  # and is decrypted with sops (which uses the master age key).
  # This activation script is idempotent — it skips if the key is already
  # in the GPG keyring.
  home.activation.importJjGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export GNUPGHOME="${homeDirectory}/.gnupg"
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"

    KEY_FINGERPRINT="${jjGpgKeyId}"

    if ! ${pkgs.gnupg}/bin/gpg --list-keys "$KEY_FINGERPRINT" >/dev/null 2>&1; then
      echo "Importing jj GPG key ($KEY_FINGERPRINT)..."

      # Decrypt the sops-encrypted key from the nix store and import it
      ${pkgs.sops}/bin/sops --decrypt --input-type binary --output-type binary \
        ${../../../secrets/laptop/jj-gpg-key.asc} \
        | ${pkgs.gnupg}/bin/gpg --batch --import

      # Trust ultimately so signing doesn't prompt
      echo "$KEY_FINGERPRINT:6:" | ${pkgs.gnupg}/bin/gpg --batch --import-ownertrust

      echo "jj GPG key imported successfully."
    fi
  '';

  # ── Shell integration ────────────────────────────────────────────
  home.shellAliases = {
    j = "jj";
    jl = "jj log";
    js = "jj status";
    jd = "jj diff";
    jn = "jj new";
    je = "jj edit";
    jf = "jj squash";
    jp = "jj push";
    jpl = "jj pull";
    jc = "jj commit";
    jm = "jj bookmark";
    jgl = "jj git push --changes-in-bookmark";
    jgpl = "jj git fetch";
    jw = "jj workspace";
    jwn = "jj workspace new";
    jwf = "jj workspace forget";
    jjt = "lazyjj";
    jjui = "jjui";
    jjf = "jj-fzf";
  };
}
