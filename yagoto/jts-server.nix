{
  config,
  pkgs,
  specialArgs,
  ...
}:
let
  jts = specialArgs.jts;
  port = "8713";
  tokens = pkgs.writeText "tokens.json" (
    builtins.toJSON {
      "jts_server_token_hash_e50cc3489331d46734b0b20e18148510159d7e8cc62823e38cfe73b6b7ce498f" = {
        Name = "hinanawi";
        Permissions = [ "database:sync" ];
      };
      "jts_server_token_hash_1b92521afdc51441c463cd8061ed684ba9874f05640ab04aa95a312c5adcb9b3" = {
        Name = "shion";
        Permissions = [ "database:sync" ];
      };
      "jts_server_token_hash_e84fb02d9a44799e039c3d2b9d74781dba278ec77d16043832f1e36945107ea7" = {
        Name = "mitsu8";
        Permissions = [ "database:sync" ];
      };
    }
  );
in
{
  users.groups.jts-server = { };
  users.users.jts-server = {
    isSystemUser = true;
    description = "jts-server services";
    group = "jts-server";
  };
  systemd.services.jts-server = {
    script = ''
      source ${config.age.secrets.jts-server-config.path}
      export SEEKBACK_SERVER_OAUTH_REDIRECT_URI=https://jts.kiyuri.ca/login/callback
      ${jts.outputs.packages.aarch64-linux.default}/bin/server \
        -bind localhost:${port} \
        -db-path $STATE_DIRECTORY/db.sqlite3 \
        -tokens-path ${tokens}
    '';
    serviceConfig.User = "jts-server";
    serviceConfig.StateDirectory = "jts-server";
    wantedBy = [ "multi-user.target" ];
  };
  age.secrets.jts-server-config = {
    file = ../secrets/jts-server-config.sh.age;
    owner = "jts-server";
    mode = "400";
  };
  age.secrets.jts-origincert = {
    file = ../secrets/jts.kiyuri.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.jts-privkey = {
    file = ../secrets/jts.kiyuri.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."jts.kiyuri.ca" = {
      extraConfig = ''
        encode gzip
        reverse_proxy http://localhost:${port}
        tls ${config.age.secrets.jts-origincert.path} ${config.age.secrets.jts-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
