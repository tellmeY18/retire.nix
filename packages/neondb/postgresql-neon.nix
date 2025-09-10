{ stdenv
, lib
, fetchFromGitHub
, fetchurl
, makeWrapper
, pkg-config
, openssl
, zlib
, readline
, libxml2
, icu
, tzdata
, libkrb5
, substituteAll
, darwin
, systemd
, libossp_uuid
, perl
, docbook_xml_dtd_45
, docbook_xsl
, libxslt
, bison
, flex
}:

stdenv.mkDerivation rec {
  pname = "postgresql";
  version = "16.1-neon";

  src = fetchFromGitHub {
    owner = "neondatabase";
    repo = "postgres";
    rev = "863b71572bc441581efb3bbee2ad18af037be1bb";
    hash = "sha256-Ms3YD3NS0+llNzgynwnKyF/R7rbmUQG/ixbbVswvVFA=";
  };

  outputs = [ "out" "lib" "doc" "man" ];
  setOutputFlags = false;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
    perl
    bison
    flex
    (lib.getBin libxslt)
  ];

  buildInputs = [
    zlib
    readline
    openssl
    libxml2
    icu
    tzdata
    libkrb5
  ] ++ lib.optionals (!stdenv.isDarwin) [ libossp_uuid ]
    ++ lib.optionals stdenv.isLinux [ systemd ];

  enableParallelBuilding = !stdenv.isDarwin;
  separateDebugInfo = true;
  buildFlags = [ "world" ];

  env.NIX_CFLAGS_COMPILE = "-I${libxml2.dev}/include/libxml2";

  preConfigure = "CC=${stdenv.cc.targetPrefix}cc";

  configureFlags = [
    "--with-openssl"
    "--with-libxml"
    "--with-icu"
    "--sysconfdir=/etc"
    "--libdir=$(lib)/lib"
    "--with-system-tzdata=${tzdata}/share/zoneinfo"
    "--enable-debug"
    "--with-gssapi"
  ] ++ lib.optionals stdenv.isLinux [ "--with-systemd" ]
    ++ lib.optionals stdenv.isDarwin [ "--with-uuid=e2fs" ]
    ++ lib.optionals (!stdenv.isDarwin) [ "--with-ossp-uuid" ];

  postPatch = ''
    # Fix schema lookups
    substituteInPlace doc/src/sgml/{standalone-install.xml,postgres.sgml,standalone-profile.xsl} \
      --replace http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd \
      ${docbook_xml_dtd_45}/xml/dtd/docbook/docbookx.dtd
    substituteInPlace doc/src/sgml/{stylesheet-text.xsl,stylesheet-man.xsl,stylesheet-fo.xsl,stylesheet.xsl,stylesheet-html-common.xsl,stylesheet-html-nochunk.xsl} \
      --replace http://docbook.sourceforge.net/release/xsl/current/ \
      ${docbook_xsl}/xml/xsl/docbook/
  '';

  installTargets = [ "install-world" ];

  postInstall = ''
    moveToOutput "lib/pgxs" "$out"
    moveToOutput "lib/libpgcommon*.a" "$out"
    moveToOutput "lib/libpgport*.a" "$out"
    moveToOutput "lib/libecpg*" "$out"

    # Prevent a retained dependency on gcc-wrapper.
    substituteInPlace "$out/lib/pgxs/src/Makefile.global" --replace ${stdenv.cc}/bin/ld ld

    if [ -z "''${dontDisableStatic:-}" ]; then
      # Remove static libraries in case dynamic are available.
      for i in $out/lib/*.a $lib/lib/*.a; do
        name="$(basename "$i")"
        ext="${stdenv.hostPlatform.extensions.sharedLibrary}"
        if [ -e "$lib/lib/''${name%.a}$ext" ] || [ -e "''${i%.a}$ext" ]; then
          rm "$i"
        fi
      done
    fi
  '';

  doCheck = !stdenv.isDarwin;
  checkTarget = "check";

  passthru = {
    psqlSchema = "16";
    dlSuffix = stdenv.hostPlatform.extensions.sharedLibrary;
  };

  meta = with lib; {
    homepage = "https://neon.tech/";
    description = "PostgreSQL fork optimized for Neon";
    license = licenses.postgresql;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
  };
}
