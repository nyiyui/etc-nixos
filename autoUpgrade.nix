{
  config,
  pkgs,
  lib,
  ...
}:
let
  hostName = config.networking.hostName;
  sshKey = "autoupgrade-${hostName}.id_ed25519";
  cfg = config.autoUpgrade.config;
in
{
  options.autoUpgrade.config.daemonUser =
    with lib;
    with types;
    mkOption {
      type = "str";
      description = "User to own/maintain the /etc/nixos folder.";
      default = "youmu";
    };
  options.autoUpgrade.config.authMethod =
    with lib;
    with types;
    mkOption {
      type = oneOf [
        (enum [ "ssh" ])
        (submodule {
          options = {
            https = mkOption {
              type = submodule {
                options = {
                  username = mkOption {
                    type = str;
                    description = "Username to use with HTTPS authentication.";
                  };
                  passwordFile = mkOption {
                    type = str;
                    description = "Path to file with password to use with HTTPS authentication.";
                  };
                };
              };
            };
          };
        })
      ];
      default = "ssh";
      description = ''
        Which authentication method to use.
        SSH requires an SSH key; HTTPS requires a username-password pair.
        Note that TDSB-WIFI and friends very much dislike SSH.
      '';
    };

  config = {
    system.autoUpgrade = {
      enable = true;
      rebootWindow.lower = "01:00";
      rebootWindow.upper = "05:00";
      randomizedDelaySec = "1d";
      persistent = true;
      dates = lib.mkDefault "Fri 02:30";
      flake = "/etc/nixos";
      allowReboot = true;
    };
    nix.gc = {
      options = "--delete-older-than 14d";
      persistent = true;
      dates = lib.mkDefault "06:00"; # after reboot window
      automatic = true;
      randomizedDelaySec = "1h";
    };
    users.users.youmu = {
      isSystemUser = true;
      description = "auto-upgrade maintainer";
      group = "youmu";
    };
    users.groups.youmu = { };
    systemd.timers.autoupgrade-pull = {
      enable = true;
      description = "trigger pull of /etc/nixos";
      timerConfig.OnCalendar = lib.mkDefault "Fri 02:00";
      timerConfig.Persistent = true;
      # see .github/workflows/flake-upgrade.yml (runs on Fri 00:00)
      wantedBy = [ "timers.target" ];
    };
    systemd.services.autoupgrade-reset-perms = {
      enable = true;
      description = "reset perms for /etc/nixos";
      script = ''
        set -eu
        chmod g+rwX /etc/nixos -R
        chgrp youmu /etc/nixos -R
      '';
    };
    systemd.services.autoupgrade-pull = {
      enable = true;
      description = "pull /etc/nixos";
      serviceConfig = {
        WorkingDirectory = "/etc/nixos";
        User = "youmu";
      };
      wants = [ "autoupgrade-reset-perms.service" ];
      after = [ "autoupgrade-reset-perms.service" ];
      script =
        if cfg.authMethod == "ssh" then
          ''
            export GIT_SSH_COMMAND='${pkgs.openssh}/bin/ssh -i ${
              config.age.secrets.${sshKey}.path
            } -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null'
            ${pkgs.git}/bin/git \
              -c 'safe.directory=/etc/nixos' \
              -c 'core.sharedRepository=group' \
              pull
          ''
        else
          ''
            export GIT_TERMINAL_PROMPT=0
            ${pkgs.git}/bin/git \
              -c credential.helper='!f() { echo "username=${cfg.authMethod.https.username}" && printf "password=" && cat "${cfg.authMethod.https.passwordFile}" | tr -d "[:space:]"; }; f' \
              -c 'safe.directory=/etc/nixos' \
              -c 'core.sharedRepository=group' \
              pull
          '';
    };

    age.secrets.${sshKey} = lib.mkIf (cfg.authMethod == "ssh") {
      file = ./secrets/autoupgrade-${hostName}.id_ed25519.age;
      owner = "youmu";
      group = "youmu";
      mode = "400";
    };
  };
}
