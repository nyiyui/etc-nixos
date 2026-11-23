{ pkgs, ... }:
let
  theme = ./kawamo_to_seseragi.toml;
  config = pkgs.writeText "helix-config.toml" ''
    theme = "kawamo_to_seseragi"

    [editor]
    line-number = "relative"

    [editor.soft-wrap]
    enable = true
  '';
in
{
  environment.systemPackages = [ pkgs.helix ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # tmpfiles can't be used here as it's user-owned.
  systemd.services.dev-vm-helix-config = {
    description = "Install helix config and theme for kiyurica";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -o kiyurica -g kiyurica -m 0700 \
        /var/home/kiyurica/.config/helix \
        /var/home/kiyurica/.config/helix/themes
      ln -sfn ${config} /var/home/kiyurica/.config/helix/config.toml
      ln -sfn ${theme} /var/home/kiyurica/.config/helix/themes/kawamo_to_seseragi.toml
    '';
  };
}
