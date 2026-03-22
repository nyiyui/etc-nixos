{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.wlsunset;

  wlsunset-geoclue-pkg =
    {
      wlsunset,
      python3Packages,
      writers,
      runCommand,
      makeWrapper,
    }:
    let
      pythonScript = writers.writePython3 "wlsunset-geoclue-unwrapped" {
        libraries = [ python3Packages.dbus-next ];
      } (builtins.readFile ./wlsunset-geoclue.py);
    in
    runCommand "wlsunset-geoclue"
      {
        nativeBuildInputs = [ makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        makeWrapper ${pythonScript} $out/bin/wlsunset \
          --set WLSUNSET_BIN "${wlsunset}/bin/wlsunset"
      '';
in
{
  options.assr.wlsunset = {
    enable = lib.mkEnableOption "wlsunset with geoclue2 support";
    temperature = {
      day = lib.mkOption {
        type = lib.types.int;
        default = 6500;
        description = "Daytime temperature";
      };
      night = lib.mkOption {
        type = lib.types.int;
        default = 2000;
        description = "Nighttime temperature";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        wlsunset = final.callPackage wlsunset-geoclue-pkg {
          wlsunset = prev.wlsunset;
        };
      })
    ];

    services.geoclue2.enable = true;

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "sunrise" ''
        systemctl --user stop wlsunset-geoclue
      '')
      (pkgs.writeShellScriptBin "sunset" ''
        systemctl --user restart wlsunset-geoclue
      '')
    ];

    systemd.user.services.wlsunset-geoclue = {
      description = "wlsunset with geoclue2 location updates";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t ${toString cfg.temperature.night} -T ${toString cfg.temperature.day}";
        Restart = "always";
      };
    };
  };
}
