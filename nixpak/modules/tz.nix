{ config, lib, ... }:
{
  config.bubblewrap.bind.rw = [
    "/etc/localtime"
  ];
}
