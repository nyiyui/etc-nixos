{ config, lib, pkgs, qrystal, ... }:
let cfg = config.miyamizu.services.target; in {
  options.miyamizu.services.target = with lib; with types; {
    enable = mkEnableOption "Miyamizu sync target";
  };
  config = lib.mkIf cfg.enable {
    services.openssh.enable = true;
    users.groups.miyamizu-sync = {};
    users.users.miyamizu-sync = {
      isNormalUser = true; # required for ssh
      group = "miyamizu-sync";
      extraGroups = [ "wheel" ];
      description = "Miyamizu sync";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+luR4QiJF1F4wVwtxt62Nprg+zefnLAXS4RC71zB/v hinanawi.miyamizu.@nyiyui.ca"
      ];
    };
    nix.settings.trusted-users = [ "miyamizu-sync" ];
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    security.doas.extraRules = [{
      users = [ "miyamizu-sync" ];
      keepEnv = true;
      noPass = true;
    }];
    qrystal.services.node.config.srvList = pkgs.writeText "srvlist.json" (builtins.toJSON { Networks = {
      msb = [{
        Service = "_miyamizu";
        Protocol = "_tcp";
        Priority = 10;
        Weight = 10;
        Port = 22;
      }];
    }; });
    qrystal.services.node.config.cs.azusa.networks.msb.allowedSRVs = [{
      service = "_miyamizu";
    }];
  };
}
