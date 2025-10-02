{ ... }:
{
  # Sayonara music player configuration
  # Disables the notification for new version updates
  xdg.configFile."sayonara/Sayonara.conf".text = ''
    [Player]
    NotifyNewVersion=false
  '';
}
