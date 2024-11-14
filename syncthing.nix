{
  services.syncthing = {
    enable = true;
    dataDir = "/home/nyiyui";
    openDefaultPorts = true; # not include web
    configDir = "/home/nyiyui/.config/syncthing";
    user = "nyiyui";
    group = "users";
    guiAddress = "127.0.0.1:8384";

    overrideDevices = true;
    overrideFolders = true;
    settings.devices = {
      "asuna".id =
        "Q5BN7WM-NFZG7XU-4Y266W3-OSAR4VJ-WI3GQOG-56Q54AR-X5XYMTL-RHSZTQJ";
      "makura".id =
        "Y3IYLHZ-SUS5JCX-QQENQUL-PI4XK7E-CPWJT3P-MVJGZVS-4XIM4HB-N4UNFAU";
      "minato".id =
        "6ROWFH5-WMAJ5JO-TDJA22O-AOQYET7-SCRIF6T-Q6A3HMA-VP7263N-JMIIRQO";
      "hinanawi".id =
        "Q3DTKLX-XRLSA2W-UIFZHEV-X4EEVXH-6GNXGV6-EI3D2TZ-XVTXJ4X-4FZJDQT";
      "sawako".id =
        "6UX4AQF-M2V2BIC-GUKGHBI-67CMCYC-KCLGCZN-D5HPIIB-T3IKTCX-5DIFFQ7";
      "yagoto".id = 
        "O4HUT3G-FXAVISB-MHSFOIU-2Q4CYM3-NRJS5PZ-4DC7TDF-GDU3JOZ-MO4BMQD";
      "sekisho".id =
        "GZI3EIZ-THXPOCR-3JW4BSP-GVQDDF7-ENZ3N3Z-PTLLRG2-4VPUKI7-XZOIHQ6";
    };
    settings.folders = {
      "inaba" = {
        id = "pugdv-kmejz";
        path = "/home/nyiyui/inaba";
        devices = [ "hinanawi" "makura" "minato" "yagoto" "sekisho" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
      "geofront" = {
        id = "e2kwg-rebhd";
        label = "GF-01";
        path = "/home/nyiyui/inaba/geofront";
        devices = [ "hinanawi" "makura" "sekisho" ];
        versioning.type = "trashcan";
        versioning.params.cleanoutDays = "0"; # never
        ignoreDelete = true;
      };
      "hisame" = {
        id = "fzewo-z2hef";
        label = "hisame";
        path = "/home/nyiyui/inaba/hisame";
        devices = [ "hinanawi" "yagoto" "sekisho" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
    };
  };
}
