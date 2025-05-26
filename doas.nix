{ lib, ... }:
{
  # Priviledge Escalation
  security.sudo.enable = lib.mkDefault false;
  security.doas.enable = true;
  security.doas.extraRules = [
    {
      users = [ "kiyurica" ];
      keepEnv = true;
    }
  ];
}
