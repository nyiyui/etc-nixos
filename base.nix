{ pkgs, lib, ... }:
{
  imports = [ ./all-modules.nix ];

  users.groups.kiyurica = { };
  users.users.kiyurica = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "kiyurica";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJ2Nn9F1Feco7kb3BmJjE+VLZgMJQU43PnMf4uhX3WDoNW4n1PRCaYHRB4mCKIsZwZjAQ41/debHFvZ+8vhwqVM= kiyurica@suzaku"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOpcXjT5V7pbiRluEcYPlNy1179aI++jGlLRPcPlP/kZQEVkOOlpjjy+JcGC3XCcjmEXRREFhUfJmgm77L4RS18= @pixel-6a"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ8YtgEk7+PgyVSdOMsmJ5ale6iWdixMg0ZG1NJ+CVOV rqv"
    ];
    homeMode = "700";
  };

  nix.settings.trusted-users = [ "kiyurica" ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;
  assr.services.backup-persist-push = {
    enable = true;
    storageDevice = "inaho";
    backedUpDevices = [
      "suzaku"
      "minamo"
    ];
  };

  services.openssh.enable = true;
  services.openssh.extraConfig = "PerSourcePenalties crash:90s authfail:5s refuseconnection:10s noauth:1s grace-exceeded:10s max:10m min:15s max-sources4:65536 max-sources6:65536 overflow:permissive";
  kiyurica.mosh.enable = true;

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
  programs.git.enable = true;
  programs.htop.enable = true;
  environment.systemPackages = with pkgs; [
    shpool
    wget
    curl
    file
    btop # htop but more fancy; nice when seeing overview of sys perf
    powertop
    rsync
  ];

  # === Reduce Perl
  # Remove perl from activation
  boot.initrd.systemd.enable = lib.mkDefault true;
  system.etc.overlay.enable = lib.mkDefault true;
  services.userborn.enable = lib.mkDefault true;

  # Random perl remnants
  system.tools.nixos-generate-config.enable = lib.mkDefault false;
  boot.loader.grub.enable = lib.mkDefault false;
  environment.defaultPackages = lib.mkDefault [ ];
  documentation.info.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;

  # TODO: [nixos 26.11] remove
  # evaluation warning: `boot.zfs.forceImportRoot` is using the default value of `true`. It is highly recommended to set it to `false`, the new default from 26.11 on, to reduce the risk of data loss. Alternatively, you can silence this warning by explicitly setting it to `true`.
  boot.zfs.forceImportRoot = false;
}
