{ config, pkgs, ... }:
let secretName = "github-runner-token";
in {
  services.github-runners.etc-nixos = {
    enable = true;
    user = "github-runner";
    group = "github-runner";
    tokenFile = config.age.secrets.${secretName}.path;
    url = "https://github.com/yiurin";
  };

  age.secrets.${secretName} = {
    file = ./github-runner-token.age;
    owner = config.services.github-runners.etc-nixos.user;
    group = config.services.github-runners.etc-nixos.group;
    mode = "400";
  };

  users.users.github-runner = {
    isSystemUser = true;
    description = "runs github-runner";
    group = "github-runner";
  };
  users.groups.github-runner = { };
}
