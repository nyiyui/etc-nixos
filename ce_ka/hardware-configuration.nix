{
  config,
  pkgs,
  lib,
  nixos-hardware,
  modulesPath,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.kernelModules = [ "nvme" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
    # ↓ copied from used modules (535feabcd5e9b8498f80e91e679ea3ad0399e5ba)
    "aesni_intel"
    "cryptd"
    "cbc"
    "atkbd"
    "i8042"
    "fat"
    "vfat"
    "nls_cp437"
    "nls_iso8859_1"
    "dm_crypt"
    "dm_mod"
    "btrfs"
  ];
  boot.initrd.includeDefaultModules = false;
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # === Graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
    ];
  };
  hardware.intelgpu = {
    driver = "xe";
    vaapiDriver = "intel-media-driver";
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  # TODO: check w/ vainfo or LIBVA_DRIVER_NAME=iHD vainfo
}
