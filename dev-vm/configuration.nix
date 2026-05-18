{
  lib,
  pkgs,
  ...
}:
{
  microvm = {
    hypervisor = "cloud-hypervisor";
    mem = 4096;
    vcpu = 4;

    shares = [
      # Host nix store mounted read-only; combined with the writable overlay
      # below this gives the guest a fully functional /nix/store without a daemon.
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      # Host home directory exposed as /workspace inside the VM.
      {
        proto = "virtiofs";
        tag = "workspace";
        source = "/home/kiyurica";
        mountPoint = "/workspace";
      }
    ];

    # Writable tmpfs overlay over the ro-store so activation scripts can
    # register gc-roots, etc. Destroyed on VM exit — intentionally ephemeral.
    writableStoreOverlay = "/nix/.rw-store";
  };

  # Backing tmpfs for the writable store overlay (ephemeral by design).
  fileSystems."/nix/.rw-store" = {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
    neededForBoot = true;
  };

  # No nix daemon — store is read-only from the host.
  systemd.services.nix-daemon.enable = false;
  systemd.sockets.nix-daemon.enable = false;

  # Auto-login as root; drop straight into /workspace.
  services.getty.autologinUser = lib.mkDefault "root";
  programs.bash.loginShellInit = "[ -d /workspace ] && cd /workspace";

  users.users.root.shell = pkgs.bash;

  environment.systemPackages = with pkgs; [
    bash
    coreutils
    git
    curl
    file
    htop
  ];

  networking.hostName = "dev-vm";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.11";
}
