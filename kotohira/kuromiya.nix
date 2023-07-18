{ config, qrystal, ... }:
let
  token = { name, hash }: {
    inherit name;
    inherit hash;
    networks.msb = name; # 結び 君の名は
    canPull = true;
    canPush.networks.msb = {
      name = name;
      canSeeElement = "any";
    };
  };
in {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.cs ];

  qrystal.services.cs = {
    enable = true;
    config.tls = {
      certPath = ./kuromiya-cert.pem;
      keyPath = config.age.secrets."kuromiya-key.pem".path;
    };
    config.tokens = [
      (token {
        name = "kotohira";
        hash =
          "qrystalcth_437ac9b547aa4403443b0064cfbd79f5bbff05d442a3e86812d0b7de2d8d036a";
      })
      (token {
        name = "hinanawi";
        hash =
          "qrystalcth_5dfd42f22115f71c986b415404a954e91098f021bc394a7a298fa235611da6de";
      })
      (token {
        name = "naha";
        hash =
          "qrystalcth_196fde3337c9c3ee07823feb3de5f3d622b0e0e26fc62f75b625a0b031f519f0";
      })
      (token {
        name = "cirno";
        hash =
          "qrystalcth_110d9b50a031eedefdb3e6ec7d114fa0171874fbcbfe9a0510bd290c8fc56c42";
      })
      (token {
        name = "mitsu8";
        hash =
          "qrystalcth_c8f7c45f3af3ddd98da52f9082301242c5725f86877c2c27e27365a2a91188c3";
      })
    ];
    config.central.networks.msb = {
      keepalive = "30s";
      listenPort = 39570;
      ips = [ "10.59.0.0/8" ];
    };
  };

  # fw disbaled on GCE
  # networking.firewall.allowedUDPPorts = [ 39570 ];

  age.secrets."kuromiya-key.pem" = {
    file = ../secrets/kuromiya-key.pem.age;
    owner = "qrystal-cs";
    group = "qrystal-cs";
    mode = "400";
  };
}
