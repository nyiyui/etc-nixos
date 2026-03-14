{ config, pkgs, ... }:
{
  # https://nixos.wiki/wiki/TPM
  security.tpm2.enable = true;
  security.tpm2.pkcs11.enable = true; # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.tctiEnvironment.enable = true; # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
  security.tpm2.abrmd.enable = true; # required for tpm-fido
  users.users.kiyurica.extraGroups = [ config.security.tpm2.tssGroup ]; # tss group has access to TPM devices

  # tpm-fido: https://github.com/psanford/tpm-fido
  # FIDO token implementation that uses TPM for key protection
  # ssh-tpm-agent: https://github.com/Foxboron/ssh-tpm-agent
  # SSH agent that uses TPM for key protection
  environment.systemPackages = [
    pkgs.tpm-fido
    pkgs.ssh-tpm-agent
    pkgs.pinentry-curses # required by tpm-fido and ssh-tpm-agent for user authentication
  ];

  # Set SSH_AUTH_SOCK to point to ssh-tpm-agent socket
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-tpm-agent.sock";
  };

  # Load uhid kernel module at boot so tpm-fido can emulate a USB HID device
  boot.kernelModules = [ "uhid" ];

  # Grant tss group access to /dev/uhid so tpm-fido can create virtual USB device
  # Users in tss group already have access to /dev/tpmrm0
  services.udev.extraRules = ''
    KERNEL=="uhid", SUBSYSTEM=="misc", GROUP="${config.security.tpm2.tssGroup}", MODE="0660"
  '';

  systemd.user.services.tpm-fido = {
    description = "TPM-backed FIDO token";
    documentation = [ "https://github.com/psanford/tpm-fido" ];
    unitConfig.PartOf = [
      "graphical-session.target"
    ];
    path = [
      pkgs.pinentry-curses
    ];
    serviceConfig.ExecStart = "/run/current-system/sw/bin/tpm-fido";
    wantedBy = [ "default.target" ];
  };

  systemd.user.sockets.ssh-tpm-agent = {
    description = "SSH TPM agent socket";
    socketConfig = {
      ListenStream = "%t/ssh-tpm-agent.sock";
      Service = "ssh-tpm-agent.service";
    };
    wantedBy = [ "sockets.target" ];
  };

  systemd.user.services.ssh-tpm-agent = {
    description = "SSH TPM Agent";
    documentation = [ "https://github.com/Foxboron/ssh-tpm-agent" ];
    unitConfig.PartOf = [
      "graphical-session.target"
    ];
    path = [
      pkgs.pinentry-curses
    ];
    serviceConfig = {
      ExecStart = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent";
      StandardInput = "socket";
      Restart = "always";
    };
  };
}
