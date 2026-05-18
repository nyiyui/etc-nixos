{
  config,
  lib,
  pkgs,
  ...
}:
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
    # TODO: translate fish shell init and plugins to hjem
  };
}