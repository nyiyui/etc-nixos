{ config, lib, ... }:
{
  options.kiyurica.syncthing.tailscaleOnly = lib.mkEnableOption "restrict syncthing firewall ports to tailscale0 interface";

  config = {
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
      settings.options.urAccepted = -1;
      settings.options.localAnnounceEnabled = lib.mkIf config.kiyurica.syncthing.tailscaleOnly false;
      settings.devices = {
        "minato".id = "6ROWFH5-WMAJ5JO-TDJA22O-AOQYET7-SCRIF6T-Q6A3HMA-VP7263N-JMIIRQO";
        "suzaku".id = "5DES2YX-7XTFTK7-SGP4VRD-KVS5DAO-VPMXEC7-RDAGYKE-QDRZDDD-NS5ANAZ";
        "inaho".id = "THGLO7L-TJ4Q4UF-BE2ZERW-AXHKKSY-CAZTUJY-W5T24JT-VC7WCTR-GJPPMAH";
        "minamo".id = "XP6LLSQ-I2CHH22-Q42BXI6-J5VXT77-7KRE53R-ZP7E42X-Y2RHJK7-IGTEFAN";
        "rqv".id = "KSQQRQV-4AJT6PP-HCBIMZ2-JI5YZCJ-DMUNRRU-CBVTGTN-N2SPXJH-42SDQQS";
        "Macbook-Air.local".id = "KT7BGJ5-5TIKLGV-TB5KQSR-4JQGFZI-FEM36RW-K3SWEYP-VB5UL4K-MIBKLQD";
      };
      settings.folders = {
        "inaba" = {
          id = "pugdv-kmejz";
          path = "/home/kiyurica/inaba";
          devices = [
            "minato"
            "suzaku"
            "inaho"
            "minamo"
          ];
          versioning.type = "staggered";
          versioning.params = {
            cleanInterval = "86400";
            maxAge = "31536000";
          };
          rescanIntervalS = 86400;
        };
        "geofront" = rec {
          enable = builtins.elem config.networking.hostName devices;
          id = "e2kwg-rebhd";
          label = "GF-01";
          path = "/home/kiyurica/inaba/geofront";
          devices = [
            "suzaku"
            "inaho"
            "minamo"
            "rqv"
            "Macbook-Air.local"
          ];
          versioning.type = "trashcan";
          versioning.params.cleanoutDays = "0"; # never
          ignoreDelete = true;
          rescanIntervalS = 86400;
        };
      };
    };

    # Syncthing ports: open globally on machines without tailscale,
    # restrict to tailscale0 on machines with tailscaleOnly enabled.
    networking.firewall.allowedUDPPorts = lib.mkIf (!config.kiyurica.syncthing.tailscaleOnly) [
      22000
      21027
    ];
    networking.firewall.allowedTCPPorts = lib.mkIf (!config.kiyurica.syncthing.tailscaleOnly) [ 22000 ];
    networking.firewall.interfaces.tailscale0.allowedUDPPorts =
      lib.mkIf config.kiyurica.syncthing.tailscaleOnly
        [
          22000
          21027
        ];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts =
      lib.mkIf config.kiyurica.syncthing.tailscaleOnly
        [
          22000
        ];

    # TODO: get syncthing to ignore through other kind of config?
    # home-manager.users.kiyurica =
    #   { lib, ... }:
    #   {
    #     home.file."${config.services.syncthing.settings.folders.inaba.path}/.stignore".text =
    #       lib.mkDefault ''
    #         .direnv
    #         __pycache__
    #       '';
    #   };

    systemd.services.syncthing = {
      environment.GOMAXPROCS = "1";
      serviceConfig = {
        CPUWeight = 20;
        CPUQuota = "50%";
        IOWeight = 20;
      };
    };
  };
}
