{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kiyurica.persisted-symlinks;
  syncScript = pkgs.writeShellScriptBin "persisted-symlinks-sync" ''
    exec ${pkgs.python3}/bin/python3 ${./persisted-symlinks.py} --config "${cfg.configPath}" "$@"
  '';
in
{
  options.kiyurica.persisted-symlinks = {
    enable = lib.mkEnableOption "syncing temporary symlinks from persisted storage";
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/persisted-symlinks.json";
      description = "Path to a user-managed JSON config file.";
    };
    timer.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run automatic periodic sync.";
    };
    timer.onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "systemd timer OnCalendar schedule for symlink sync.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ syncScript ];

    systemd.user.services.persisted-symlinks-sync = {
      Unit.Description = "Sync user-defined persisted symlinks";
      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}/bin/persisted-symlinks-sync";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.timers.persisted-symlinks-sync = lib.mkIf cfg.timer.enable {
      Unit.Description = "Periodic persisted symlink sync";
      Timer = {
        OnBootSec = "1m";
        OnCalendar = cfg.timer.onCalendar;
        Unit = "persisted-symlinks-sync.service";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
