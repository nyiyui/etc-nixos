{ config, pkgs, ... }: let
  port = 29679;
in {
  home.packages = with pkgs; [ restic ];
  systemd.user.services.backup-restic = {
    Unit.Description = "restic backup";
    Unit.After = "network-online.target";
    Unit.Wants = "network-online.target";
    Service = {
      ExecStart = pkgs.writeShellScript "backup-restic.sh" ''
        export RESTIC_PASSWORD="$"
        export RESTIC_REPOSITORY='rest:http://localhost:${toString port}'
        rclone serve restic -v \
          --addr localhost:${toString port} \
          onedrive:restic-${config.home.file.hostname.text}
      '';
    };
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.services.backup-rclone-serve = {
    Unit.Description = "rclone serve for restic backup";
    Unit.After = "network-online.target";
    Unit.Wants = "network-online.target";
    Service = {
      ExecStart = pkgs.writeShellScript "backup-rclone-serve.sh" ''
        rclone serve restic -v \
          --config ${config.users.users.nyiyui}/.config/rclone/rclone.conf \
          --addr localhost:${toString port} \
          onedrive:restic-${config.home.file.hostname.text}
      '';
    };
    Install.WantedBy = [ "default.target" ];
  };

  users.groups.backup-rclone = {};
  users.users.backup-rclone = {
    isNormalUser = true;
    description = "just for 'rclone serve restic'";
    group = "backup-rclone";
  };

  age.secrets."${hostName}.rclone.conf" = {
    file = ./secrets/{hostName}.rclone.conf.age;
    owner = "backup-rclone";
    group = "backup-rclone";
    mode = "400";
  };
}
