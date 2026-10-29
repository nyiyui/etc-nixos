{
  config,
  specialArgs,
  lib,
  pkgs,
  assr,
  hjem,
  ...
}:

{
  imports = [
    specialArgs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko-config.nix
    assr.nixosModules.appliance
    ../fprint.nix
    ../thunderbolt.nix
    ../common.nix
    ../sound.nix
    ../tpm.nix
    ../niri-hjem
    ../hjem
    ../tarmak.nix
    hjem.nixosModules.default
  ];

  # Ce_ka has no persistent system-level disk. Consequently:
  # - /var is stored in a LUKS partition with the key held by the TPM without a PIN
  # - System files must be stored on ephemeral storage à la assr's ephemeral-sysroot (i.e., an ext4 partition freshly made on each boot).
  # - /etc/machine-id is regenerated on every boot (I couldn't find any problems when I did this, and it's one less persistence to worry about).
  # - User-level persistence is handled by mounting dedicated btrfs subvolumes (on the
  #   "userdata" LUKS volume) directly at their target paths, with the LUKS key held by the
  #   TPM with a PIN.

  # === Early Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0; # press space at POST and hold to select boot entry
  boot.kernelParams = [
    "systemd.machine_id=uninitialized"
  ];

  users.users.kiyurica = {
    initialHashedPassword = "$6$06vlZ9HBdM/5kbi.$5AN3KD/nmSzcHZO0iu5tMvS4S1xxggYZJhXt.N789GQsdBDRTkzazGYIHei3d9PLepbKXOqHsgwQw4Ha.RY42.";
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
  system.stateVersion = "26.05"; # Did you read the comment?

  networking.hostName = "ce_ka";

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/home/kiyurica/inaba"
      "/var"
    ];
  };

  services.openssh.hostKeys = [
    {
      path = "/var/lib/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  assr.desktop.niri = {
    enable = true;
    enableUWSM = true;
  };
  kiyurica.greeter.gtkgreet = {
    enable = true;
  };

  # === Timezones
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

  environment.systemPackages = with pkgs; [
    helix
    intel-gpu-tools
    libva-utils # vainfo
    powertop
    usbutils
    yubikey-manager
    yubikey-personalization
    guvcview # test USB webcam (C720) outside the firefox sandbox
    v4l-utils # v4l2-ctl, for checking whether the kernel sees the webcam at all
  ];

  users.users.kiyurica.extraGroups = [ "kvm" ];

  assr.power-logger.enable = true;
  assr.ssh-agent.enable = true;

  services.tlp.settings = {
    DISK_DEVICES = "nvme0n1";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";
  };

  boot.initrd.systemd.repart.device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2506E9A48456";

  # Expose repart.d for bootstrapping the repart-managed partitions (i.e., root, root-verity, ephemeral-sysroot) on a live system.
  system.build.repart = config.environment.etc."repart.d".source;

  kiyurica.hjem.enable = true;

  systemd.services."hjem-activate@".environment.RUST_BACKTRACE = "1";
  hjem.linkerOptions = [ "--verbose" ];
}
