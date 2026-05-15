{
  config,
  lib,
  ...
}:
let
  cfg = config.kiyurica.ics-next-event;
in
{
  options.kiyurica.ics-next-event.icsUrlPath =
    with lib;
    with types;
    mkOption {
      type = nullOr str;
      default = null;
      description = "waybar: path to ICS URL list for the next event module";
    };

  config = lib.mkIf (cfg.icsUrlPath != null) {
    home-manager.users.kiyurica.kiyurica.icsUrlPath = cfg.icsUrlPath;
  };
}
