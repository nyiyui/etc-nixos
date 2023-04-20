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
    devices = {
      "miyo".id =
        "M7X7VPF-QU4SBMZ-3EBZT2T-IAARHKV-FL7J2CV-DLUKDZ6-QCUX727-RLHHYAC";
      "asuna".id =
        "Q5BN7WM-NFZG7XU-4Y266W3-OSAR4VJ-WI3GQOG-56Q54AR-X5XYMTL-RHSZTQJ";
      "makura".id =
        "Y3IYLHZ-SUS5JCX-QQENQUL-PI4XK7E-CPWJT3P-MVJGZVS-4XIM4HB-N4UNFAU";
      "x1".id =
        "KKFQLLW-KWKGN3M-EIWQUL5-4DBNSB5-VAE6X7W-XXPFNB2-E27QFLO-DPLX3QV";
    };
    folders = {
      "inaba" = {
        id = "pugdv-kmejz";
        path = "/home/nyiyui/inaba";
        devices = [ "miyo" "makura" "x1" ];
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
        devices = [ "miyo" ];
        versioning.type = "trashcan";
        versioning.params.cleanoutDays = "0"; # never
        ignoreDelete = true;
      };
      "spool" = {
        id = "wofgx-gaqxc";
        label = "spool";
        path = "/home/nyiyui/inaba/spool";
        devices = [ "miyo" "makura" "asuna" ];
        versioning.type = "staggered";
        versioning.params = {
          cleanInterval = "86400";
          maxAge = "31536000";
        };
      };
    };
  };
}
