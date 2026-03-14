{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshAgentImplementation = config.assr.ssh-agent.implementation;
in
{
  options.assr.ssh-agent.implementation = lib.mkOption {
    type = lib.types.enum [
      "fish_ssh_agent"
      "ssh-tpm-agent"
    ];
    default = "fish_ssh_agent";
    description = "Which SSH agent implementation to use.";
  };

  config = {
    programs.fish = {
      shellInit = lib.optionalString (sshAgentImplementation == "fish_ssh_agent") ''
        if status is-interactive; and test -z "$KIYURICA_IN_SANDBOX_DEV"
            fish_ssh_agent
            set key ~/.ssh/id_inaba
            test -e "$key"
            or set key ~/inaba/geofront/id_inaba
            ssh-add -l | grep -q 'WBykfqqS1+mkkNe0XEtCzvoV3oms/Mli+bz0FhOPWzg' || ssh-add "$key"
        end
      '';
      plugins = lib.optional (sshAgentImplementation == "fish_ssh_agent") {
        name = "ssh_agent";
        src = pkgs.fetchFromGitHub {
          owner = "ivakyb";
          repo = "fish_ssh_agent";
          rev = "c7aa080d5210f5f525d078df6fdeedfba8db7f9b";
          sha256 = "bfd5596390c2a3e89665ac11295805bec8b7dd42b0b6b892a54ceb3212f44b5e";
        };
      };
    };
  };
}
