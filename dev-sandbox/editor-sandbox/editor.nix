{
  config,
  lib,
  pkgs,
  nixpak,
  ...
}:

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = [
          ../../nixpak/modules/xdg-home2.nix
          (import ../../nixpak/modules/flatpak.nix { appId = "com.helix_editor.Helix"; })
          ../../nixpak/modules/gui-base.nix
          ../../nixpak/modules/network.nix
        ];
        app.package = pkgs.helix;

        # Disable X11 explicitly to avoid XAUTHORITY panic in launcher
        bubblewrap.sockets.x11 = false;
        gpu.enable = false; # Disable GPU to avoid X11 dependencies

        # Allow access to the whole home directory (equivalent to --filesystem=home)
        # Note: --filesystem=host would be even more permissive, but we'll start with home.
        bubblewrap.bind.rw = [
          [ sloth.homeDir sloth.homeDir ]
        ];

        # Allow access to all devices (equivalent to --device=all)
        bubblewrap.bind.dev = [ "/dev" ];

        # Ensure Helix finds its runtime files
        bubblewrap.env.HELIX_RUNTIME = "${pkgs.helix}/lib/runtime";
        bubblewrap.env.COLORTERM = "truecolor";
        bubblewrap.env.HELIX_DISABLE_CLIPBOARD = "1";

        # Add some common terminal environment variables
        bubblewrap.env.TERM = { key = "TERM"; type = "env"; };
      };
  };
in
{
  imports = [ ../../home-manager.nix ];

  config = lib.mkIf config.assr.editor-sandbox.enable {
    environment.systemPackages = [ sandboxed.config.env ];
    environment.variables.editor = lib.mkOverride 900 "hx";
    kiyurica.home-manager.enable = true;
    home-manager.users.kiyurica =
      { ... }:
      {
        programs.helix = {
          package = sandboxed.config.env;
          themes = {
            "kawamo_to_seseragi" = ./kawamo_to_seseragi.toml;
          };
          enable = true;
          defaultEditor = true;
          settings = {
            theme = "kawamo_to_seseragi";
            editor.line-number = "relative";
          };
        };
      };
  };
}
