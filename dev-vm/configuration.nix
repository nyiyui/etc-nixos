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

    writableStoreOverlay = "/nix/.rw-store";

    # Persistent disk volumes. Images live in the workspace directory on the
    # host; the wrapper script creates them on first launch and symlinks them
    # to the paths below before running microvm-run.
    volumes = [
      {
        # Writable overlay for /nix/store. neededForBoot — must be present
        # before the overlayfs is assembled.
        image = "/run/user/1000/dev-vm-nix-store.img";
        label = "nix-store";
        size = 20480; # MiB
      }
      {
        # General persistent storage mounted at /home/kiyurica.
        image = "/run/user/1000/dev-vm-state.img";
        label = "dev-vm-state";
        size = 51200; # MiB (50 GiB)
      }
    ];
  };

  # Writable overlay upper dir backed by the virtio-blk nix-store volume.
  # ext4 supports the trusted.* xattrs that overlayfs requires.
  fileSystems."/nix/.rw-store" = {
    device = "/dev/disk/by-label/nix-store";
    fsType = "ext4";
    options = [
      "noatime"
      "discard"
    ];
    neededForBoot = true;
  };

  # General persistent storage. Sparse 50 GiB image; only written blocks
  # consume real disk space on the host.
  fileSystems."/home/kiyurica" = {
    device = "/dev/disk/by-label/dev-vm-state";
    fsType = "ext4";
    options = [
      "noatime"
      "discard"
    ];
  };

  # virtio-blk must be available before filesystems are mounted.
  boot.initrd.availableKernelModules = [ "virtio_blk" ];

  # Nix daemon runs in the VM for building. The host store is available
  # read-only via virtiofs so pre-built paths need not be re-fetched.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "kiyurica" ];
  };

  users.groups.kiyurica = { gid = 1000; };
  users.users.kiyurica = {
    uid = 1000;
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
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";
}
