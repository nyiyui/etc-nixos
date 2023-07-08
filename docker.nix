{ ... }: {
  virtualisation.docker.enable = true;
  systemd.services.docker.unitConfig.enable = false;
  # ↑ docker.socket is still active so not much of an issue (see https://superuser.com/a/1731426)
}
