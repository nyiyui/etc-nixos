{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kiyurica.services.flatpak-managed;
in
{
  options.kiyurica.services.flatpak-managed = {
    enable = mkEnableOption "Flatpak package manager";

    packages = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            appId = mkOption {
              type = str;
              description = "Application ID (e.g., org.gimp.GIMP)";
              example = "com.spotify.Client";
            };

            origin = mkOption {
              type = str;
              description = "Flatpak remote (e.g., flathub)";
              default = "flathub";
              example = "flathub-beta";
            };
          };
        });
      default = [ ];
      description = "List of Flatpak packages to install";
      example = literalExpression ''
        [
          { appId = "com.spotify.Client"; }
          { appId = "org.signal.Signal"; }
          { appId = "com.discordapp.Discord"; }
        ]
      '';
    };

    removeUnmanagedPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to remove Flatpak packages not specified in packages";
      example = false;
    };

    remotes = mkOption {
      type =
        with types;
        attrsOf (submodule {
          options = {
            url = mkOption {
              type = str;
              description = "URL of the Flatpak remote";
              example = "https://flathub.org/repo/flathub.flatpakrepo";
            };
          };
        });
      default = {
        flathub = {
          url = "https://flathub.org/repo/flathub.flatpakrepo";
        };
      };
      description = "Flatpak remotes to configure";
      example = literalExpression ''
        {
          flathub = {
            url = "https://flathub.org/repo/flathub.flatpakrepo";
          };
          flathub-beta = {
            url = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.flatpak ];

    system.activationScripts.flatpak =
      let
        allowedPackages = concatStringsSep " " (map (pkg: "${pkg.appId}") cfg.packages);

        setupCommands = concatStringsSep "\n" (
          # Add remotes
          (mapAttrsToList (name: remote: ''
            $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists ${name} ${remote.url}
          '') cfg.remotes)
          ++

            # Install packages
            (map (pkg: ''
              $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install --noninteractive --or-update ${pkg.origin} ${pkg.appId}
            '') cfg.packages)
          ++

            # Optionally remove unmanaged packages
            (
              if cfg.removeUnmanagedPackages then
                [
                  ''
                    # Remove packages not in the allowed list
                    for app in $($DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak list --app --columns=application); do
                      if ! echo "${allowedPackages}" | grep -qw "$app"; then
                        echo "Removing unmanaged Flatpak package: $app"
                        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak uninstall --noninteractive --force-remove "$app"
                      fi
                    done
                  ''
                ]
              else
                [ ]
            )
        );
      in
      ''
        # Flatpak setup
        ${setupCommands}
      '';
  };
}
