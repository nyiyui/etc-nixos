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
      # this lets the guest use all host store paths without re-downloading,
      # while new build outputs go to the tmpfs overlay (ephemeral).
      {
        proto = "virtiofs";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      # Project directory mounted as /workspace.
      # Source is a placeholder — the actual path is supplied at launch time
      # by the dev-vm wrapper script via its own virtiofsd invocation.
      {
        proto = "virtiofs";
        tag = "workspace";
        source = "/tmp";
        mountPoint = "/workspace";
      }
    ];

    interfaces = [
      {
        type = "tap";
        id = "vm-dev";
        mac = "02:00:00:00:00:01";
      }
    ];

    # Writable tmpfs overlay over the ro-store for build outputs.
    # Destroyed on VM exit — intentionally ephemeral.
    writableStoreOverlay = "/nix/.rw-store";
  };

  # Backing tmpfs for the writable store overlay.
  fileSystems."/nix/.rw-store" = {
    fsType = "tmpfs";
    options = [ "mode=0755" ];
    neededForBoot = true;
  };

  # Nix daemon runs in the VM for building. The host store is available
  # read-only via virtiofs so pre-built paths need not be re-fetched.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "kiyurica" ];
  };

  users.groups.kiyurica = { };
  users.users.kiyurica = {
    isNormalUser = true;
    group = "kiyurica";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };

  security.sudo.wheelNeedsPassword = false;
  programs.fish.enable = true;

  # Auto-login as kiyurica; drop into /workspace; poweroff on logout.
  services.getty.autologinUser = lib.mkDefault "kiyurica";
  programs.fish.loginShellInit = ''
    if test -d /workspace; cd /workspace; end
    function _poweroff_on_exit --on-event fish_exit
      sudo poweroff
    end
  '';

  # Apply hostname written by the host wrapper into /workspace/.dev-vm-hostname.
  systemd.services.dev-vm-hostname = {
    description = "Set VM hostname from workspace config";
    wantedBy = [ "multi-user.target" ];
    after = [ "workspace.mount" ];
    requires = [ "workspace.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ -f /workspace/.dev-vm-hostname ]; then
        read -r name < /workspace/.dev-vm-hostname
        echo "$name" > /proc/sys/kernel/hostname
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    coreutils
    git
    curl
    file
    htop
    claude-code
    codex
    gemini-cli
  ];

  networking.hostName = "dev-vm";
  networking.useDHCP = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "25.11";
}
