{
  config,
  lib,
  pkgs,
  self,
  specialArgs,
  nixos-hardware,
  nixpkgs-unstable,
  hjem-rum,
  ...
}:

{
  imports = [
    ./kernel-modules.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ./overlays.nix
    ./hardware-configuration.nix
    ../niri-hjem
    ../hjem
    ./disko-config.nix
    ../appliance
    ./impermanence.nix
    ../dev-vm/host.nix
    ../fprint.nix
    ../syncthing.nix
    ../thunderbolt.nix
    ../common.nix
    ../sound.nix
    ../virt.nix
    ../tpm.nix
    # ../vnc.nix # TODO: re-enable
    # ../codex.nix # not used
    ../nixpak/packages/org.keepassxc.KeePassXC.nix
    # ../nixpak/packages/org.kde.ark.nix
    ../nixpak/packages/org.mozilla.firefox.nix
    ../nixpak/packages/org.mozilla.Thunderbird.nix
    # ../nixpak/packages/org.libreoffice.LibreOffice.nix
    # ../nixpak/packages/io.github.alainm23.planify.nix
    ../nixpak/packages/org.signal.Signal.nix
    ../tarmak.nix
    # ../nixpak/packages/org.strawberrymusicplayer.strawberry.nix
    # ../nixpak/packages/org.chromium.Chromium.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0; # press space at POST and hold to select boot entry

  users.users.kiyurica = {
    initialHashedPassword = "$y$j9T$g5xm0pLBFbK4W4c5BIENt/$D18bkwRRxH/MjSlInTZfvd2vE4Mxa.RQXARitTirV64";
    # TODO: TPM-backed password hash, and rotate password
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

  networking.hostName = "suzaku";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/persist" ];
  };

  assr.desktop.niri = {
    enable = true;
    enableUWSM = true;
  };
  kiyurica.greeter.gtkgreet = {
    enable = true;
  };
  # TODO: add moonlight-qt package

  hjem.users.kiyurica.kiyurica.icsUrlPath = config.age.secrets.icsUrlPath.path;

  age.secrets.icsUrlPath = {
    file = ../secrets/ics-url-path.txt.age;
    owner = "kiyurica";
    group = "kiyurica";
    mode = "400";
  };

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  services.automatic-timezoned.enable = true;
  services.geoclue2.geoProviderUrl = "https://api.positon.xyz/v1/geolocate?key=56aba903-ae67-4f26-919b-15288b44bda9";
  # automatic-timezoned and its geoclue agent have Before=graphical.target by default, which pulls
  # geoclue → network-online.target → tailscaled → NM-wait-online into the greeter's critical path.
  # Remove the ordering so these services start concurrently with (not before) graphical.target.
  systemd.services.automatic-timezoned = {
    wantedBy = lib.mkForce [ "multi-user.target" ];
    before = lib.mkForce [ ];
  };
  systemd.services.automatic-timezoned-geoclue-agent = {
    wantedBy = lib.mkForce [ "multi-user.target" ];
    before = lib.mkForce [ ];
  };
  # To use the Positon geolocation service, uncomment this URL.
  #
  # NOTE: Distributors of geoclue may only uncomment this URL if the
  #       service is used in a non-commercial manner, to quote Positon:
  #
  #         We generally consider a service or software commercial, when it is only
  #         intended to be available (beyond free trials or other restrictions) via
  #         a one-time payment, subscription, account registration or similar.
  #         Funding the development through donations or optional support contracts
  #         does not make the software itself commercial.
  #
  #         Fedora Linux, CentOS Stream, Rocky Linux or AlmaLinux all would not be
  #         considered commercial by us, neither would e.g. Debian, Ubuntu or
  #         elementary OS. However, RedHat Enterprise Linux and various SUSE Linux
  #         Enterprise versions would be considered commercial.
  #
  #       For more information, contact Positon or consult their website:
  #       https://positon.xyz/docs/

  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00fc", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';

  kiyurica.tailscale.enable = true;
  kiyurica.syncthing.tailscaleOnly = true;
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ]; # we may not always be connected to the Internet and therefore the tailnet

  # Enable mDNS for LAN hostname resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  kiyurica.laptop.enable = true;

  kiyurica.displaylink.enable = true;

  kiyurica.networks.eduroam.enable = true;

  # kiyurica.gatech-vpn.enable = true; # TODO: remove home-manager dependency

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
    helix
  ];

  users.users.kiyurica.extraGroups = [ "kvm" ];

  kiyurica.quaderno-sync = {
    enable = true;
    autoSync.enable = true;
  };

  assr.power-logger.enable = true;

  # TODO: Enable when Fall 2026 semester starts
  # kiyurica.caldav-canvas-gradescope = {
  #   enable = true;
  #   credFile = ./caldav-canvas-gradescope-env.cred;
  # };

  services.xserver.xkb.layout = "tarmak1";
  services.xserver.xkb.options = "compose:caps";
  # niri reads XKB_DEFAULT_* env vars rather than services.xserver.xkb directly
  environment.variables = {
    XKB_DEFAULT_LAYOUT = "tarmak1";
    XKB_DEFAULT_OPTIONS = "compose:caps";
  };
  # apply the xkb layout to the Linux console (TTY) as well
  console.useXkbConfig = true;

  nix.settings.cores = 16; # keep at least 4 cores open for UI

  assr.ssh-agent.implementation = "ssh-tpm-agent";

  services.tlp.settings = {
    DISK_DEVICES = "nvme0n1";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";
  };

  boot.initrd.systemd.repart.device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2506E9A48456";

  boot.kernelParams = [
    # Zero memory on alloc/free — closes uninitialised-data and use-after-free info-leak classes.
    "init_on_alloc=1"
    "init_on_free=1"
    # Randomise page allocator free-list order.
    "page_alloc.shuffle=1"
    # Prevent allocator from merging slabs of compatible layout (anti-heap-grooming).
    "slab_nomerge"
    # Randomise kernel stack offset per syscall.
    "randomize_kstack_offset=on"
    # Disable the legacy vsyscall table (fixed-address ROP gadget source).
    "vsyscall=none"
    # Hide debugfs from unprivileged users.
    "debugfs=off"
    # Kernel lockdown: prevents root from loading unsigned modules, writing /dev/mem, etc.
    # Only meaningful because Secure Boot is enabled.
    # Use "confidentiality" to also disable hibernate if that tradeoff is acceptable.
    "lockdown=integrity"
  ];

  boot.kernel.sysctl = {
    # Hide kernel symbol addresses from all users (even root).
    "kernel.kptr_restrict" = 2;
    # Restrict dmesg to root — many exploit primitives rely on dmesg leaks.
    "kernel.dmesg_restrict" = 1;
    # Disable unprivileged eBPF — highest-frequency kernel CVE surface of recent years.
    "kernel.unprivileged_bpf_disabled" = 1;
    # Harden BPF JIT output against JIT-spray attacks.
    "net.core.bpf_jit_harden" = 2;
    # Restrict ptrace to parent→child only (breaks cross-process gdb attach).
    "kernel.yama.ptrace_scope" = 1;
    # Restrict perf_event_open to root.
    "kernel.perf_event_paranoid" = 3;
    # Disable /proc/sysrq-trigger for unprivileged users.
    "kernel.sysrq" = 0;
  };

  kiyurica.hjem.enable = true;
  kiyurica.home-manager.enable = lib.mkForce false;

  systemd.services."hjem-activate@".environment.RUST_BACKTRACE = "1";
  hjem.linkerOptions = [ "--verbose" ];
}
