{ pkgs, ... }: {
  # cf. https://discourse.nixos.org/t/tpm2-luks-unlock-not-working/52342

  environment.systemPackages = with pkgs; [
    sbctl
  ];
  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  # This is needed to auto-unlock LUKS with TPM 2 - https://discourse.nixos.org/t/full-disk-encryption-tpm2/29454/2
  boot.initrd.systemd.enable = true;
}
