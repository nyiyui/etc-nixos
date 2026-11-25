# The userdata mounts' directories above them (and the subvolume roots
# themselves on a fresh disk) end up owned by root. Fix that once the mounts
# are up.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDir = "/home/kiyurica";

  userdataMountpoints = map (subvol: subvol.mountpoint) (
    lib.attrValues
      config.disko.devices.disk.main.content.partitions.userdata.content.content.subvolumes
  );

  # All ancestors of `path` down to, but excluding, `base`.
  # Example:
  # ancestorsUnder "/home/kiyurica" "/home/kiyurica/.local/share/fish" ==
  #   [ "/home/kiyurica/.local" "/home/kiyurica/.local/share" "/home/kiyurica/.local/share/fish" ]
  ancestorsUnder =
    base: path:
    let
      parts = lib.path.subpath.components (lib.removePrefix (base + "/") path);
    in
    map (n: lib.concatStringsSep "/" ([ base ] ++ lib.take n parts)) (lib.range 1 (lib.length parts));

  homeMountpoints = lib.filter (lib.hasPrefix (homeDir + "/")) userdataMountpoints;

  homeOwnedPaths = lib.unique (lib.concatMap (ancestorsUnder homeDir) homeMountpoints);

  paths = lib.concatStringsSep " " homeOwnedPaths;
in
{
  # Ordered before userdata.target is reached, so the PIN attempt that unlocks userdata only
  # succeeds once this has run - the login it grants happens after the home is usable.
  systemd.services.ce-ka-fix-userdata-perms = {
    description = "Fix ownership and mode of userdata-backed paths under the home directory";
    unitConfig.RequiresMountsFor = homeMountpoints;
    # `before` is the ordering: userdata.target is not reached until both ExecStarts have
    # exited 0. `requiredBy` is what propagates failure, so a failed chown/chmod fails the
    # target, which fails the `systemctl start userdata.target` in the PAM helper, which
    # denies the login rather than granting one into a root-owned home.
    before = [ "userdata.target" ];
    requiredBy = [ "userdata.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.coreutils}/bin/chown kiyurica:kiyurica ${paths}"
        "${pkgs.coreutils}/bin/chmod ${config.users.users.kiyurica.homeMode} ${paths}"
      ];
    };
  };
}
