{ config, ... }:
let
  hostName = config.networking.hostName;
  passwordKey = "autoupgrade-${hostName}.password";
in {
  imports = [ ./autoUpgrade.nix ];

  autoUpgrade.config.authMethod.https = {
    username = "nyiyui";
    passwordFile = config.age.secrets.${passwordKey}.path;
  };

  age.secrets.${passwordKey} = {
    file = ./secrets/autoupgrade-${hostName}.password.age;
    owner = "youmu";
    group = "youmu";
    mode = "400";
  };
}
