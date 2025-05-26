{ config, lib, ... }: 
let
  makeBuildMachine = { name, system ? "x86_64-linux", publicHostKey, speedFactor ? 1, maxJobs ? 1 }: {
    inherit system;
    sshUser = "remote-build";
    sshKey = "/root/.ssh/id_ed25519";
    inherit speedFactor;
    inherit publicHostKey;
    protocol = "ssh-ng";
    inherit maxJobs;
    hostName = "${name}.tailcbbed9.ts.net";
  };
in
{
  # see ./remote-builder.nix
  options.kiyurica.remote-builder.use-remote-builder = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use remote builders";
  };

  config = lib.mkIf config.kiyurica.remote-builder.use-remote-builder {
    nix.distributedBuilds = true;
    nix.buildMachines = [
      (makeBuildMachine { name = "inaho"; publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUxrUjVkeldlK3I0dCtwcVVXUk1qYWtNcWFjdit4WXMwQ3F1M2I3SWVncXQgcm9vdEBpbmFobwo="; maxJobs = 3; })
      (makeBuildMachine { name = "mitsu8"; publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSVBzQzdIUUs2MURETDFCN1I0c0JBTzZ2SWRGRUE3cTZMRE0za3cydjNwa2Qgcm9vdEBuaXhvcwo="; maxJobs = 3; })
    ];
  };
}

