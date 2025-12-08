{ pkgs, ... }:

pkgs.testers.runNixOSTest ({ lib, ... }: {
  name = "headless-boot-test";

  nodes.machine =
    { pkgs, modulesPath, ... }:
    {
      imports = [
        ../all-modules.nix
        # "${modulesPath}/profiles/headless.nix"
        # "${modulesPath}/profiles/minimal.nix"
      ];

      # Basic configuration needed for the test
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "headless-test";

      # Ensure we have a basic user setup
      users.users.testuser = {
        isNormalUser = true;
        password = "test";
      };

      system.stateVersion = "25.05";
    };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl status")
    machine.succeed("hostname | grep headless-test")
    machine.succeed("id testuser")
    machine.wait_for_unit("fail2ban.service")
    machine.succeed("nix --version")
  '';
})
