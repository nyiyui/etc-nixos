{ pkgs, ... }: {
  users.groups.restic-repo = { };
  users.users.restic-repo = {
    isNormalUser = true;
    description = "just holds the restic repo";
    group = "restic-repo";
    extraGroups = [ "nyiyui" ];
    packages = with pkgs; [ restic ];
  };
}
