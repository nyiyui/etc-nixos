{ config, qrystal, ... }: let
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
      (token { name = "rei"; hash = "qrystalcth_f59740d9888c97c224558099862bbc4daac66b27a098555151fbd751628e3003"; })
      (token { name = "hinanawi"; hash = "qrystalcth_5dfd42f22115f71c986b415404a954e91098f021bc394a7a298fa235611da6de"; })
      (token { name = "naha"; hash = "qrystalcth_196fde3337c9c3ee07823feb3de5f3d622b0e0e26fc62f75b625a0b031f519f0"; })
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
