# Login with the TPM PIN protecting userdata for the first login of the boot only.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  userdataDevice = "/dev/disk/by-partlabel/disk-main-userdata";
  userdataVolume = "userdata"; # so /dev/mapper/userdata

  userdataSubvolumes =
    config.disko.devices.disk.main.content.partitions.userdata.content.content.subvolumes;

  userdataMountpoints = map (subvol: subvol.mountpoint) (lib.attrValues userdataSubvolumes);

  userdataMountUnits = map (m: "${utils.escapeSystemdPath m}.mount") userdataMountpoints;

  # Cf. ./userdata-unlock.c
  userdataUnlock =
    pkgs.runCommandCC "userdata-unlock"
      {
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.cryptsetup ];
      }
      ''
        mkdir -p $out/bin
        $CC -O2 -Wall -Wextra -Werror \
          -DUSERDATA_DEVICE='"${userdataDevice}"' \
          -DUSERDATA_VOLUME='"${userdataVolume}"' \
          -DTOKEN_PATH='"${config.systemd.package}/lib/cryptsetup"' \
          -o $out/bin/userdata-unlock ${./userdata-unlock.c} \
          $(pkg-config --cflags --libs libcryptsetup)
      '';

  # Exits 0 when the device is not open.
  userdataGuard = pkgs.writeShellScript "userdata-pin-required" ''
    [ "''${PAM_USER-}" = kiyurica ] && [ ! -e /dev/mapper/${userdataVolume} ]
  '';
in
{
  imports = [ ./fix-perms.nix ];

  # We use a C program to do the unlock instead of crypttab to allow us to
  # check that the attempted PIN/passphrase was the one that unlocked the volume
  # (instead of a race, say, with two seats).
  systemd.targets.userdata = {
    description = "userdata volume ready";
    requires = userdataMountUnits;
    after = userdataMountUnits;
  };

  # userdata-unlock.c returns iff the disk was not open previously and the
  # provided PIN/passphrase is correct. I *think* there is no issue with
  # races between userdata-unlock.c, as I think there is no race in cryptsetup
  # (hopefully, but idk since it isn't really designed to be used this way).
  #
  # While userdata is locked, a fingerprint, UNIX password, or any other method
  # won't be useful, as those will result in logging into a user with no home.
  # Therefore, we force userdata-unlock.c to be used if userdata is locked with
  # userdata-guard. While this is only for greetd, that is the only supported
  # method of initial login.
  #
  # The authentication flow is as follows:
  # rule               outcome        next step                         
  # ================== ============== ==================================
  # userdata-guard-pre   --(locked)-> go to userdata-unlock (ignore)
  #                    --(unlocked)-> go to fprintd and friends
  # userdata-unlock     --(success)-> done
  #                        --(fail)-> go to userdata-guard-post (ignore)
  #                                   ("already unlocked" becomes a fail)
  # userdata-guard-post  --(locked)-> die
  #                    --(unlocked)-> go to fprintd and friends (ignore)
  # fprintd and friends
  #
  # userdata-guard-post ensures that a lost race in userdata-unlock will result
  # in the normal fprintd and friends authentication rules applying.
  #
  # nixpkgs' own rules are auto-assigned multiples of 100.
  # 
  # Assume fprintd is the first rule.
  security.pam.services.greetd = {
    rules.auth.userdata-guard-pre = {
      enable = true;
      order = config.security.pam.services.greetd.rules.auth.fprintd.order - 3;
      control = "[success=ignore default=2]";
      modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
      args = [
        "quiet"
        "quiet_log"
        "${userdataGuard}"
      ];
    };

    rules.auth.userdata-unlock = {
      enable = true;
      order = config.security.pam.services.greetd.rules.auth.fprintd.order - 2;
      control = "[success=done default=ignore]";
      modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
      args = [
        # "quiet"
        # "quiet_log"
        "expose_authtok"
        "${userdataUnlock}/bin/userdata-unlock"
      ];
    };

    rules.auth.userdata-guard-post = {
      enable = true;
      order = config.security.pam.services.greetd.rules.auth.fprintd.order - 1;
      control = "[success=die default=ignore]";
      modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
      args = [
        "quiet"
        "quiet_log"
        "${userdataGuard}"
      ];
    };
  };

  systemd.services.syncthing.wantedBy = lib.mkForce [ "userdata.target" ];
  systemd.services.syncthing-init.wantedBy = lib.mkForce [ "userdata.target" ];

  systemd.services."dev-vm@".unitConfig.RequiresMountsFor = [ "/var/lib/dev-vm" ];
}
