{
  config,
  lib,
  nixwrap,
  ...
}:
{
  imports = [
    ./shell-sandbox.nix
    ./editor-sandbox
  ];

  options.assr.dev-sandbox.enable = lib.mkEnableOption "complete development sandbox (shell + editor)";

  config = lib.mkIf config.assr.dev-sandbox.enable {
    nixpkgs.overlays = [
      (final: prev: {
        nixwrap-wrap =
          let
            wrap = nixwrap.packages.${final.system}.wrap;
          in
          final.runCommand "wrap-fixed" { nativeBuildInputs = [ final.makeWrapper ]; } ''
            mkdir -p $out/bin
            makeWrapper ${wrap}/bin/wrap $out/bin/wrap \
              --prefix PATH : ${final.lib.makeBinPath [ final.coreutils ]}
          '';
      })
    ];
    assr.shell-sandbox.enable = true;
    assr.editor-sandbox.enable = true;
  };
}
