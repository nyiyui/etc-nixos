{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:
let
  wrap = nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap;
  wrap-lsps = pkgs.buildGoModule {
    pname = "wrap-lsps";
    version = "0.1.0";
    src = ./wrap-lsps;
    vendorHash = "sha256-pbA/AlBz3cQYRTMnQ/qBPcinYOKokrBLNhkbRTq54gE=";
    ldflags = [
      "-X main.interpreter=${pkgs.dash}/bin/dash"
      "-X main.wrapCommand=${wrap}/bin/wrap"
    ];
  };
in
{
  imports = [ ../../home-manager.nix ];

  config = lib.mkIf config.assr.editor-sandbox.enable {
    kiyurica.home-manager.enable = true;
    home-manager.users.kiyurica =
      { ... }:
      {
        home.packages = [ wrap-lsps ];
      };
  };
}
