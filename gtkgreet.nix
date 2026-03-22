{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kiyurica.greeter.gtkgreet = {
    enable = lib.mkEnableOption "greeter based on greetd with gtkgreet running on sway";
    extraSwayConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "extra sway config to add to the greeter's sway";
    };
    compositor = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "default" ];
      description = ''
        List of compositor command lines; either an executable path (recommended), Desktop Entry ID, "select", or "default".
        Run uwsm start --help for details.
      '';
    };
  };

  config = lib.mkIf config.kiyurica.greeter.gtkgreet.enable {
    services.greetd = {
      enable = true;
      settings.default_session =
        let
          # TODO: use sunset options from home-manager/wlsunset.nix
          swayConfig = pkgs.writeText "greetd-sway-config" (
            ''
              exec "${pkgs.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
              exec "${pkgs.wlsunset}/bin/wlsunset -L -79.38 -T 6500 -g 1.000000 -l 43.65 -t 2000"
              bindsym Mod4+shift+e exec swaynag -t warning -m 'Action?' -b 'Poweroff' 'systemctl poweroff' -b 'Reboot' 'systemctl reboot'
            ''
            + config.kiyurica.greeter.gtkgreet.extraSwayConfig
          );
          script = pkgs.writeShellScriptBin "greet.sh" ''
            ${pkgs.sway}/bin/sway --unsupported-gpu --config ${swayConfig}
          '';
        in
        {
          command = "${script}/bin/greet.sh";
          user = "greeter";
        };
    };
    environment.etc."greetd/environments" = {
      enable = true;
      text =
        lib.concatMapStringsSep "\n" (c: "uwsm start -- ${c}") (
          lib.unique config.kiyurica.greeter.gtkgreet.compositor
        )
        + "\n";
    };
  };
}
