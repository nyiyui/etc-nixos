{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Ensure gnome-keyring ssh component is enabled to provide ssh-agent
  assertions = [
    {
      assertion = config.services.gnome-keyring.enable && (builtins.elem "ssh" config.services.gnome-keyring.components);
      message = "ssh-add-keys service requires gnome-keyring with ssh component enabled. Please enable services.gnome-keyring with 'ssh' in components.";
    }
  ];

  # This service automatically adds SSH keys at startup
  # ssh-agent is provided by gnome-keyring with the ssh component enabled
  systemd.user.services.ssh-add-keys = {
    Unit = {
      Description = "Add SSH keys to agent";
      After = [
        "graphical-session.target"
        "gnome-keyring-daemon.service"
      ];
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
