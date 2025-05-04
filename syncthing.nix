{ config, lib, ... }: {
  imports = [ ./home-manager.nix ];

  services.syncthing = {
    enable = true;
    dataDir = "/home/kiyurica";
    openDefaultPorts = true; # not include web
    configDir = "/home/kiyurica/.config/syncthing";
    user = "kiyurica";
    group = "users";
    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;
    settings.devices = {
      "makura".id =
        "Y3IYLHZ-SUS5JCX-QQENQUL-PI4XK7E-CPWJT3P-MVJGZVS-4XIM4HB-N4UNFAU";
      "minato".id =
        "6ROWFH5-WMAJ5JO-TDJA22O-AOQYET7-SCRIF6T-Q6A3HMA-VP7263N-JMIIRQO";
      "sawako".id =
        "6UX4AQF-M2V2BIC-GUKGHBI-67CMCYC-KCLGCZN-D5HPIIB-T3IKTCX-5DIFFQ7";
      "yagoto".id =
        "DAORBQH-BYFZ4WX-6BQA6FB-QBQ5MU3-LQL3OGL-HBX6QW2-654SDTK-E6ZW4AK";
      "sekisho".id =
        "GZI3EIZ-THXPOCR-3JW4BSP-GVQDDF7-ENZ3N3Z-PTLLRG2-4VPUKI7-XZOIHQ6";
      "sekisho2".id =
        "U4JDJNS-R4HRVK4-VZC7TZ5-IP74TKJ-TUVNTYJ-L3MUM3Y-AMGBYKO-NFSQGQW";
      "suzaku".id =
        "5DES2YX-7XTFTK7-SGP4VRD-KVS5DAO-VPMXEC7-RDAGYKE-QDRZDDD-NS5ANAZ";
    };
    settings.folders = {
      "inaba" = {
        id = "pugdv-kmejz";
        path = "/home/kiyurica/inaba";
        devices = [ "makura" "minato" "yagoto" "sekisho" "sekisho2" "suzaku" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
      "geofront" = {
        id = "e2kwg-rebhd";
        label = "GF-01";
        path = "/home/kiyurica/inaba/geofront";
        devices = [ "makura" "sekisho" "yagoto" "sekisho2" "suzaku" ];
        versioning.type = "trashcan";
        versioning.params.cleanoutDays = "0"; # never
        ignoreDelete = true;
      };
      "hisame" = {
        id = "fzewo-z2hef";
        label = "hisame";
        path = "/home/kiyurica/inaba/hisame";
        devices = [ "yagoto" "sekisho" "sekisho2" "suzaku" ];
      };
    };
  };

  # Syncthing
  networking.firewall = {
    allowedUDPPorts = [ 22000 21027 ];
    allowedTCPPorts = [ 22 22000 ];
  };

  home-manager.users.kiyurica = { lib, ... }: {
    home.file."${config.services.syncthing.settings.folders.inaba.path}/.stignore".text =
      lib.mkDefault ''
        .direnv
        /hisame
        __pycache__
        .direnv
      '';
  };
}
