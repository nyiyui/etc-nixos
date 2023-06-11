{ pkgs, ... }: {
  system.autoUpgrade = {
    enable = true;
    rebootWindow.lower = "03:00";
    rebootWindow.upper = "05:00";
    randomizedDelaySec = "1d";
    persistent = true;
    dates = "Fri 02:30";
    flake = "/etc/nixos";
    allowReboot = true;
  };
  nix.gc = {
    options = "--delete-older-than 14d";
    persistent = true;
    dates = "06:00"; # after reboot window
    automatic = true;
    randomizedDelaySec = "1h";
  };
  users.users.youmu = {
    isSystemUser = true;
    description = "auto-upgrade maintainer";
    group = "youmu";
  };
  users.groups.youmu = {};
  systemd.timers.autoupgrade-pull = {
    enable = true;
    description = "trigger pull of /etc/nixos";
    timerConfig.OnCalendar = "Fri 02:00";
    timerConfig.Persistent = true;
    # see .github/workflows/flake-upgrade.yml (runs on Fri 00:00)
    wantedBy = [ "timers.target" ];
  };
  systemd.services.autoupgrade-pull = {
    enable = true;
    description = "pull /etc/nixos";
    serviceConfig = {
      WorkingDirectory = "/etc/nixos";
      User = "youmu";
    };
    script = ''
      export GIT_SSH_COMMAND='${pkgs.openssh}/bin/ssh -i /etc/nixos/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null'
      ${pkgs.git}/bin/git \
        -c 'safe.directory=/etc/nixos' \
        -c 'core.sharedRepository=group' \
        pull
    '';
  };
}
