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
        "KKFQLLW-KWKGN3M-EIWQUL5-4DBNSB5-VAE6X7W-XXPFNB2-E27QFLO-DPLX3QV";
      "minato".id =
        "6ROWFH5-WMAJ5JO-TDJA22O-AOQYET7-SCRIF6T-Q6A3HMA-VP7263N-JMIIRQO";
      "hinanawi".id = "Q3DTKLX-XRLSA2W-UIFZHEV-X4EEVXH-6GNXGV6-EI3D2TZ-XVTXJ4X-4FZJDQT";
      "chikusa".id = "CC2QX3A-7ZX6BFF-QUBMGCH-6MXQ6JP-LGCUYU7-PXD34ZW-CIDIY4K-FG5WYQ6";
      "sawako".id = "6UX4AQF-M2V2BIC-GUKGHBI-67CMCYC-KCLGCZN-D5HPIIB-T3IKTCX-5DIFFQ7";
    };
    settings.folders = {
      "inaba" = {
        id = "pugdv-kmejz";
        path = "/home/nyiyui/inaba";
        devices = [ "hinanawi" "makura" "minato" "chikusa" ];
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
        devices = [ "hinanawi" "makura" "chikusa" ];
        versioning.type = "trashcan";
        versioning.params.cleanoutDays = "0"; # never
        ignoreDelete = true;
      };
      "spool" = {
        id = "wofgx-gaqxc";
        label = "spool";
        path = "/home/nyiyui/inaba/spool";
        devices = [ "hinanawi" "makura" "asuna" "chikusa" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
      "3d-spool" = {
        id = "jjxwg-tol2t";
        label = "3d-spool";
        path = "/home/nyiyui/inaba/3d-spool";
        devices = [ "hinanawi" "makura" "asuna" "chikusa" "sawako" "minato" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
    };
  };
}
