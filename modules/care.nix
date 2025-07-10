{ lib, python3, fetchFromGitHub }:

let
  python = python3;
in
python.pkgs.buildPythonApplication rec {
  pname = "care";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "ohcnetwork";
    repo = "care";
    rev = "v${version}";
    sha256 = lib.fakeSha256; # replace with actual hash
  };

  # Runtime dependencies, matching Pipfile.lock
  propagatedBuildInputs = with python.pkgs; [
    argon2-cffi
    authlib
    boto3
    celery
    django
    django-environ
    django-cors-headers
    django-filter
    django-maintenance-mode
    django-queryset-csv
    django-ratelimit
    django-redis
    django-rest-passwordreset
    django-simple-history
    djangoql
    djangorestframework
    djangorestframework-simplejwt
    dry-rest-permissions
    drf-nested-routers
    drf-spectacular
    gunicorn
    healthy-django
    jsonschema
    pillow
    psycopg
    pydantic
    pyjwt
    pyotp
    python-slugify
    pywebpush
    (redis.override { extras = [ "hiredis" ]; })
    redis-om
    requests
    simplejson
    sentry-sdk
    whitenoise
    django-anymail
    pydantic-extra-types
    phonenumberslite
    python-magic-bin
    evalidate
  ];

  checkInputs = [ python.pkgs.pytest ];
  doCheck = false; # set to true and add dev dependencies when ready

  # Metadata
  meta = {
    description = "CARE EMR backend for healthcare management";
    homepage = "https://github.com/ohcnetwork/care";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ vysakh ];
  };
}
