{ config, pkgs, ... }:
{
  # https://wiki.nixos.org/wiki/TPM
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
  security.tpm2.abrmd.enable = true; # required for tpm-fido
  users.users.kiyurica.extraGroups = [ config.security.tpm2.tssGroup ]; # tss group has access to TPM devices
  boot.initrd.systemd.tpm2.enable = true;
}
