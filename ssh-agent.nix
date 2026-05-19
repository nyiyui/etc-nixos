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
  options.assr.ssh-agent.implementation = lib.mkOption {
    type = lib.types.enum [
      "fish_ssh_agent"
      "ssh-tpm-agent"
    ];
    default = "fish_ssh_agent";
    description = "Which SSH agent implementation to use.";
  };

  config = lib.mkMerge [
    (lib.mkIf (config.kiyurica.home-manager.enable) {
      home-manager.users.kiyurica = {
        assr.ssh-agent.implementation = cfg.implementation;
      };
    })
    (lib.mkIf (cfg.implementation == "ssh-tpm-agent") {
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
    })
  ];
}
