{
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  seekback-server = specialArgs.seekback-server;
  port = "8712";
  tokens = pkgs.writeText "tokens.json" (builtins.toJSON { });
in
{
  users.groups.seekback-server = { };
  users.users.seekback-server = {
    isSystemUser = true;
    description = "seekback-server services";
    group = "seekback-server";
  };
  systemd.services.seekback-server = {
    script = ''
      source ${config.age.secrets.seekback-server-config.path}
      export SEEKBACK_SERVER_OAUTH_REDIRECT_URI=https://seekback-server.nyiyui.ca/login/callback
      export SEEKBACK_SERVER_SAMPLES_PATH=${config.services.syncthing.settings.folders.inaba.path}/seekback
      export PATH=${pkgs.ffmpeg}/bin:$PATH # ffprobe used to get sample duration
      ${seekback-server.outputs.packages.aarch64-linux.default}/bin/server \
        -bind localhost:${port} \
        -db-path $STATE_DIRECTORY/db.sqlite3 \
        -tokens-path ${tokens}
    '';
    serviceConfig.User = "seekback-server";
    serviceConfig.StateDirectory = "seekback-server";
    wantedBy = [ "multi-user.target" ];
  };
  age.secrets.seekback-server-config = {
    file = ./secrets/seekback-server-config.sh.age;
    owner = "seekback-server";
    mode = "400";
  };
  age.secrets.seekback-server-origincert = {
    file = ./secrets/seekback-server.nyiyui.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.seekback-server-privkey = {
    file = ./secrets/seekback-server.nyiyui.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."seekback-server.nyiyui.ca" = {
      extraConfig = ''
        encode gzip
        reverse_proxy http://localhost:${port}
        tls ${config.age.secrets.seekback-server-origincert.path} ${config.age.secrets.seekback-server-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
