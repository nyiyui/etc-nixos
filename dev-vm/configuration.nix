{
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./helix.nix ];
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
      # Project directory mounted as /mnt/workspace (staging point).
      # A systemd service then bind-mounts it to the real host path read from
      # /vm-meta/workspace-path so paths inside the VM match the host exactly.
      # Source is a placeholder — the actual path is supplied at launch time
      # by the dev-vm wrapper script via its own virtiofsd invocation.
      {
        proto = "virtiofs";
        tag = "workspace";
        source = "/tmp";
        mountPoint = "/mnt/workspace";
      }
      # Per-workspace metadata directory shared from the host.
      # Contains: hostname, id_ed25519.pub (SSH key), ip (written by guest).
      # Source is a placeholder — actual path is $VM_DIR supplied at launch time.
      {
        proto = "virtiofs";
        tag = "vm-meta";
        source = "/tmp";
        mountPoint = "/vm-meta";
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

    # Persistent disk volumes. Images live in /var/lib/dev-vm/<hash>/ on the
    # host; the wrapper script creates them on first launch and symlinks them
    # to the paths below before running microvm-run.
    volumes = [
      {
        # Writable overlay for /nix/store. neededForBoot — must be present
        # before the overlayfs is assembled.
        image = "/run/user/1000/dev-vm-nix-store.img";
        label = "nix-store";
        mountPoint = "/nix/.rw-store";
        size = 131072; # MiB (128 GiB)
      }
      {
        # General persistent storage mounted at /var.
        image = "/run/user/1000/dev-vm-state.img";
        label = "dev-vm-state";
        mountPoint = "/var";
        size = 131072; # MiB (128 GiB)
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
  systemd.tmpfiles.rules = [
    # nix-daemon socket dir; root is tmpfs so this must be created on every boot.
    "d /nix/var/nix/daemon-socket 0755 root root -"
    "d /var/home/kiyurica 0700 kiyurica kiyurica -"
    # Pre-create standard XDG dirs so no other tmpfiles rule creates them as root.
    "d /var/home/kiyurica/.config 0700 kiyurica kiyurica -"
    "d /var/home/kiyurica/.local 0700 kiyurica kiyurica -"
    "d /var/home/kiyurica/.cache 0700 kiyurica kiyurica -"
    "d /var/tmp 1777 root root -"
    # nix build-dir must not be world-writable; separate from /var/tmp
    "d /var/builds 0755 root root -"
  ];

  # /tmp is bind-mounted from the 64 GiB state disk so that nix build
  # sandboxes (which mount /tmp inside their chroot) and all other processes
  # have disk-backed scratch space rather than the in-memory root tmpfs.
  boot.tmp.useTmpfs = false;
  boot.tmp.cleanOnBoot = true;

  # Create /var/tmp (and /var/builds) on the state disk before the bind-mount.
  # DefaultDependencies=false is required: without it, systemd implicitly adds
  # After=basic.target to this service. Combined with Before=tmp.mount, that
  # creates a cycle (sysinit.target → tmpfiles-setup → local-fs.target →
  # tmp.mount → this service → basic.target → sysinit.target) that causes
  # systemd to drop systemd-tmpfiles-setup and local-fs.target entirely,
  # breaking nsncd, sshd, and all mounts.
  systemd.services.dev-vm-prepare-var = {
    description = "Create /var directories needed before mounts";
    after = [ "var.mount" ];
    requires = [ "var.mount" ];
    before = [ "tmp.mount" ];
    wantedBy = [ "tmp.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/tmp
      chmod 1777 /var/tmp
      mkdir -p /var/builds
      chmod 755 /var/builds
    '';
  };

  systemd.mounts = [
    {
      type = "none";
      what = "/var/tmp";
      where = "/tmp";
      options = "bind";
      requires = [
        "var.mount"
        "dev-vm-prepare-var.service"
      ];
      after = [
        "var.mount"
        "dev-vm-prepare-var.service"
      ];
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Nix daemon runs in the VM for building. The host store is available
  # read-only via virtiofs so pre-built paths need not be re-fetched.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "kiyurica" ];
    build-dir = "/var/builds";
  };

  users.groups.kiyurica = {
    gid = 1000;
  };
  users.users.kiyurica = {
    uid = 1000;
    isNormalUser = true;
    group = "kiyurica";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
    home = "/var/home/kiyurica";
  };

  security.sudo.wheelNeedsPassword = false;
  programs.fish.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  # Auto-login as kiyurica; drop into /workspace on login.
  services.getty.autologinUser = lib.mkDefault "kiyurica";
  programs.fish.loginShellInit = ''
    if test -f /vm-meta/workspace-path
      set -l _ws (cat /vm-meta/workspace-path)
      if test -d $_ws
        cd $_ws
      else
        echo "warning: workspace '$_ws' not mounted yet" >&2
      end
    end
    # Poweroff the VM when the console session ends. SSH sessions are excluded
    # so that attaching extra shells does not trigger an early shutdown.
    if not set -q SSH_TTY
      function _poweroff_on_exit --on-event fish_exit
        sudo poweroff
      end
    end
  '';

  # Apply hostname written by the host wrapper into /vm-meta/hostname.
  systemd.services.dev-vm-hostname = {
    description = "Set VM hostname from vm-meta";
    wantedBy = [ "multi-user.target" ];
    after = [ "vm\\x2dmeta.mount" ];
    requires = [ "vm\\x2dmeta.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      read -r name < /vm-meta/hostname
      echo "$name" > /proc/sys/kernel/hostname
    '';
  };

  # Copy the per-workspace SSH public key into authorized_keys before sshd starts.
  systemd.services.dev-vm-sshkeys = {
    description = "Install SSH authorized key from host";
    wantedBy = [ "sshd.service" ];
    before = [ "sshd.service" ];
    after = [
      "vm\\x2dmeta.mount"
      "systemd-tmpfiles-setup.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /etc/ssh/authorized_keys.d
      cp /vm-meta/id_ed25519.pub /etc/ssh/authorized_keys.d/kiyurica
      chmod 644 /etc/ssh/authorized_keys.d/kiyurica
    '';
  };

  # Bind-mount /mnt/workspace to the real host path (read from /vm-meta/workspace-path)
  # so that paths inside the VM match those on the host exactly.
  systemd.services.dev-vm-workspace-mount = {
    description = "Bind-mount workspace at its real host path";
    wantedBy = [ "multi-user.target" ];
    after = [
      "vm\\x2dmeta.mount"
      "mnt-workspace.mount"
    ];
    requires = [
      "vm\\x2dmeta.mount"
      "mnt-workspace.mount"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [
      util-linux
      coreutils
    ];
    script = ''
      target=$(cat /vm-meta/workspace-path)
      mkdir -p "$target"
      mount --bind /mnt/workspace "$target"
    '';
  };

  # Write the guest's DHCP-assigned IP back to /vm-meta/ip so the host wrapper
  # knows where to SSH. Retries until an address appears.
  systemd.services.dev-vm-report-ip = {
    description = "Report VM IP to host via vm-meta";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "vm\\x2dmeta.mount"
    ];
    path = with pkgs; [
      iproute2
      gawk
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "3s";
    };
    script = ''
      IP=$(ip -4 addr show scope global | awk '/inet /{sub("/.*","", $2); print $2; exit}')
      if [ -n "$IP" ]; then
        echo "$IP" > /vm-meta/ip
      else
        exit 1
      fi
    '';
  };

  # SSH server; password auth disabled — key-only via vm-meta pubkey.
  services.openssh = {
    enable = true;
    authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = true;
      XAuthLocation = "/var/home/kiyurica/.nix-profile/bin/xauth";
    };
  };

  environment.systemPackages = with pkgs; [
    coreutils
    git
    curl
    file
    htop
    waypipe

    claude-code
    codex
    gemini-cli
  ];

  networking.hostName = "dev-vm";
  networking.useDHCP = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "25.11";

  boot.kernelParams = [ "systemd.show_status=true" ];

  services.journald.extraConfig = ''
    ForwardToConsole=yes
    TTYPath=/dev/ttyS0
    MaxLevelConsole=debug
  '';
}
