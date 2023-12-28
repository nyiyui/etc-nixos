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
    canSRVUpdate = true;
    srvAllowancesAny = true;
  };
in {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.cs ];

  qrystal.services.cs = {
    enable = true;
    config.tls = {
      certPath = ../kuromiya-cert.pem;
      keyPath = config.age.secrets."kuromiya.nyiyui.ca.key.pem".path;
    };
    config.tokens = [
      (token {
        name = "chocolate-lemon";
        hash =
          "qrystalcth_d40ec13487018cd0976ec5701301cf6abe3c7021d3dc495b8faa470044315edb";
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
        name = "mitsu8";
        hash =
          "qrystalcth_c8f7c45f3af3ddd98da52f9082301242c5725f86877c2c27e27365a2a91188c3";
      })
      (token {
        name = "flan";
        hash =
          "qrystalcth_660427dd2c67e4936a22f7bd3e23e96a71f1b65ec2d89a85f3364e60f4909774";
      })
      (token {
        name = "sawako";
        hash =
          "qrystalcth_9d660067ed0dde4ba2707a40cf60bf2d2ec8792092353e4a82b2eb03cb3ae80d";
      })
    ];
    config.central.networks.msb = {
      keepalive = "30s";
      listenPort = 39570;
      ips = [ "10.59.0.0/24" "10.6.0.0/16" ];
    };
  };

  # fw disbaled on GCE
  networking.firewall.allowedUDPPorts =
    [ 39252 config.qrystal.services.cs.config.central.networks.msb.listenPort ];
  networking.firewall.allowedTCPPorts = [ 39252 ];

  age.secrets."kuromiya.nyiyui.ca.key.pem" = {
    file = ../secrets/kuromiya.nyiyui.ca.key.pem.age;
    owner = "qrystal-cs";
    group = "qrystal-cs";
    mode = "400";
  };
}
