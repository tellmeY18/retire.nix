{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

let
  version = "0.2606.0";
in
buildGoModule rec {
  pname = "gomuks";
  inherit version;

  src = fetchFromGitHub {
    owner = "gomuks";
    repo = "gomuks";
    rev = "v${version}";
    hash = "sha256-Q4hu3bcB16iuqASZvlv7nDvxj8CFX66qWp6DHIUTmh4=";
  };

  proxyVendor = true;
  vendorHash = "sha256-iuSu5MvNRt+eCZ9wxUwMo6X0joos7q9WPyXBwhn/0yE=";

  doCheck = false;

  preBuild = ''
    mkdir -p web/dist
    touch web/dist/empty
  '';

  tags = [
    "goolm"
    "sqlite_fts5"
  ];

  subPackages = [
    "cmd/gomuks"
    "cmd/gomuks-terminal"
  ];

  ldflags = [
    "-X 'go.mau.fi/gomuks/version.Tag=v${version}'"
    "-X 'go.mau.fi/gomuks/version.Commit=${src.rev}'"
    "-X 'go.mau.fi/gomuks/version.BuildTime=0'"
  ];

  meta = {
    mainProgram = "gomuks";
    description = "Matrix client written in Go (backend + terminal frontend)";
    homepage = "https://github.com/gomuks/gomuks";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.unix;
  };
}
