{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.keepassxc.enable = lib.mkEnableOption "firejailed KeePassXC";

  config = lib.mkIf config.kiyurica.keepassxc.enable {
    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        keepassxc = {
          executable = "${pkgs.keepassxc}/bin/keepassxc";
          profile = "${pkgs.firejail}/etc/firejail/keepassxc.inc";
        };
      };
    };

    environment.etc."firejail/keepassxc.local".text = ''
      whitelist /home/kiyurica/inaba/geofront/*.kdbx
    '';
  };
}
