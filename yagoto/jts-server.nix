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
      "jts_server_token_hash_765786e9efaecfc958d5b46d347e65d3af25b0d02d36d9a9272f88a1a4b44159" = {
        Name = "hinanawi";
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
