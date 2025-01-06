{ config, pkgs, ... }:
let
  genRcloneMount =
    { path, remote }:
    {
      Unit.Description = "rclone: Google Drive";
      Unit.Documentation = "man:rclone(1)";
      Unit.After = "network-online.target";
      Unit.Wants = "network-online.target";
      Service = {
        Type = "notify";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${path}";
        ExecStart = pkgs.writeShellScript "rclone.sh" ''
          env PATH=${pkgs.fuse}/bin ${pkgs.rclone}/bin/rclone mount \
            --config ${config.home.homeDirectory}/.config/rclone/rclone.conf \
            --vfs-cache-mode full \
            --vfs-cache-max-size 1G \
            --log-level INFO \
            ${remote} ${path}
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -u ${path}";
      };
      Install.WantedBy = [ "default.target" ];
    };
in
{
  home.packages = with pkgs; [
    rclone
    restic
  ];
  systemd.user.services.rclone-google-drive = genRcloneMount {
    path = "${config.home.homeDirectory}/google-drive";
    remote = "gdrive:";
  };
}
