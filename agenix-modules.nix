{
  # modules that depend on agenix (config.age.*); only import this on hosts
  # whose flake.nix modules list includes agenix.nixosModules.default
  imports = [
    ./tailscale.nix
  ];
}
