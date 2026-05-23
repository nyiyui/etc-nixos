{ pkgs, ... }:
{
  # Watch /var/lib/dev-vm/<hash>/notify files written by the Claude Code Stop
  # hook inside any dev-vm instance, then forward them as desktop notifications.
  systemd.user.services.dev-vm-notify = {
    description = "Forward dev-VM Claude Code notifications to desktop";
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      inotify-tools
      notify-desktop
    ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "2s";
      ExecStart = pkgs.writeShellScript "dev-vm-notify-watch" ''
        inotifywait -m -r -e close_write,moved_to /var/lib/dev-vm \
          --format '%w%f' \
          --include '.*/notify$' 2>/dev/null |
        while IFS= read -r path; do
          dir=$(dirname "$path")
          name=$(cat "$dir/hostname" 2>/dev/null | tr -d '[:space:]')
          rm -f "$path"
          notify-desktop --urgency=normal "Claude ($name)" "Waiting for input"
        done
      '';
    };
  };
}
