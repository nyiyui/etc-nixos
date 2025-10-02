{ pkgs, ... }:
{
  # Sayonara music player configuration
  # Disables the notification for new version updates
  # Sayonara stores config in a SQLite database at ~/.config/sayonara/player.db
  home.activation.configureSayonara = pkgs.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DB_PATH="''${XDG_CONFIG_HOME:-$HOME/.config}/sayonara/player.db"
    if [ -f "$DB_PATH" ]; then
      ${pkgs.sqlite}/bin/sqlite3 "$DB_PATH" \
        "INSERT OR REPLACE INTO settings (key, value) VALUES ('notify_new_version', 'false');"
    fi
  '';
}
