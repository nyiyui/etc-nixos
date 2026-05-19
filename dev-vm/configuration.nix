{
  lib,
  pkgs,
  ...
}:
{
  microvm = {
    hypervisor = "cloud-hypervisor";
    mem = 16384;
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
        mountPoint = "/nix/.rw-store";
        size = 65536; # MiB (64 GiB)
      }
      {
        # General persistent storage mounted at /home/kiyurica.
        image = "/run/user/1000/dev-vm-state.img";
        label = "dev-vm-state";
        mountPoint = "/home/kiyurica";
        size = 65536; # MiB (64 GiB)
      }
    ];
  };

  # zram swap: compressed in-RAM swap; no host disk I/O, low latency.
  # Lets the VM overcommit within its 16 GiB window without touching disk.
  zramSwap.enable = true;

  # virtio-blk must be available before filesystems are mounted.
  boot.initrd.availableKernelModules = [ "virtio_blk" ];

  # The state volume is a freshly-formatted ext4 whose root is owned by root.
  # tmpfiles runs after all mounts and fixes ownership on every boot.
  systemd.tmpfiles.rules = [ "d /home/kiyurica 0700 kiyurica kiyurica -" ];

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
