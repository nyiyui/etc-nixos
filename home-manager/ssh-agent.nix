{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ssh-agent is provided by gnome-keyring with the ssh component enabled
  # This service automatically adds SSH keys at startup
  systemd.user.services.ssh-add-keys = {
    Unit = {
      Description = "Add SSH keys to agent";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ssh-add-keys.sh" ''
        # Wait for SSH_AUTH_SOCK to be available
        for i in {1..10}; do
          if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
            break
          fi
          sleep 1
        done

        # Add key if it exists and is not already added
        if [ -e ~/.ssh/id_inaba ]; then
          ${pkgs.openssh}/bin/ssh-add -l | grep -q 'WBykfqqS1+mkkNe0XEtCzvoV3oms/Mli+bz0FhOPWzg' || ${pkgs.openssh}/bin/ssh-add ~/.ssh/id_inaba
        elif [ -e ~/inaba/geofront/id_inaba ]; then
          ${pkgs.openssh}/bin/ssh-add -l | grep -q 'WBykfqqS1+mkkNe0XEtCzvoV3oms/Mli+bz0FhOPWzg' || ${pkgs.openssh}/bin/ssh-add ~/inaba/geofront/id_inaba
        fi
      '';
    };
    Install.WantedBy = [ "default.target" ];
  };
}
