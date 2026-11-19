# profiles/indic.nix — end-to-end Indic language support for desktop hosts.
#
#   fonts    Noto (every Indic script), Lohit (17 families), SMC Malayalam
#            fonts, Gubbi (Kannada). fontconfig falls back by script, so any
#            app that asks for "sans-serif" renders Indic text out of the box.
#   locales  ISO 639 / India locales generated for ls, date, sort, ...
#   input    fcitx5 + m17n: transliteration (ITRANS, Swanalekha, phonetic)
#            and InScript/typewriter layouts for the major languages. Toggle
#            with Ctrl+Space; switch engine from the fcitx5 tray menu.
#
# Firefox (UI language packs, dictionaries, per-script fonts) lives in
# home/common/firefox. The default locale stays as the host sets it.
{ lib, pkgs, ... }:

let
  # fcitx5 engine name: m17n_<lang>_<scheme>. The first entry of each language
  # is the one to reach for first (transliteration).
  engines = [
    "ml_swanalekha" "ml_itrans" "ml_inscript2"
    "hi_itrans" "hi_inscript2" "hi_phonetic"
    "ta_tamil99" "ta_itrans" "ta_phonetic"
    "te_itrans" "te_inscript2"
    "kn_itrans" "kn_inscript2"
    "bn_itrans" "bn_probhat" "bn_inscript2"
    "gu_itrans" "gu_inscript2"
    "mr_itrans" "mr_inscript2"
    "pa_itrans" "pa_inscript2-guru"
    "or_itrans" "or_inscript2"
    "as_itrans"
    "ne_rom-translit"
    "ur_phonetic"
    "sa_itrans"
  ];
  items = lib.listToAttrs (lib.imap0
    (i: name: lib.nameValuePair "Groups/0/Items/${toString (i + 1)}" { Name = "m17n_${name}"; })
    engines);
in
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts # Sans/Serif for every Indic script (Devanagari ... Tamil, Telugu)
      noto-fonts-color-emoji
      gubbi-font # Kannada
      font-smc-anjalioldlipi
      font-smc-chilanka
      font-smc-dyuthi
      font-smc-gayathri
      font-smc-karumbi
      font-smc-keraleeyam
      font-smc-malini
      font-smc-manjari
      font-smc-meera
      font-smc-nupuram
      font-smc-rachana
      font-smc-raghumalayalamsans
      font-smc-uroob
    ] ++ lib.attrValues (lib.filterAttrs (_: lib.isDerivation) pkgs.lohit-fonts);
  };

  i18n.extraLocales = map (l: "${l}/UTF-8") [
    "en_IN"
    "hi_IN" "ml_IN" "ta_IN" "te_IN" "kn_IN" "bn_IN" "gu_IN" "mr_IN" "pa_IN"
    "or_IN" "as_IN" "ur_IN" "sa_IN" "ne_NP" "mai_IN" "kok_IN" "sd_IN" "ks_IN"
    "doi_IN" "mni_IN" "brx_IN" "sat_IN"
  ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-m17n
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
      ];
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "keyboard-us";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
      } // items;
    };
  };
}
