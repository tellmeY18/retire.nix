{
  # Template host — copy this directory to create a new host
  hostname = "template";
  system = "x86_64-linux";
  # hostId = "CHANGEME";  # Generate with: head -c 4 /dev/urandom | od -A none -t x4 | tr -d ' '
  timezone = "UTC";
  locale = "en_US.UTF-8";
  stateVersion = "25.11";
  type = "nixos"; # "nixos" or "darwin"
  users = [ ];
  roles = [ ];
}
