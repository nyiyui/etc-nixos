{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.assr.ssh-agent;
in
{
  options.assr.ssh-agent.enable = lib.mkEnableOption {
    description = "SSH agent";
  }

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ssh-tpm-agent
      pkgs.pinentry-curses
    ];

    environment.variables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-tpm-agent.sock";
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
      unitConfig.PartOf = [ "graphical-session.target" ];
      path = [ pkgs.pinentry-curses ];
      serviceConfig = {
        ExecStart = "${pkgs.ssh-tpm-agent}/bin/ssh-tpm-agent";
        StandardInput = "socket";
        Restart = "always";
      };
    };
  };
}
