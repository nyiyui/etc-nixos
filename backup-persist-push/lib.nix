{ lib }:
let
  backupPersistHostKeyPath = host: "${toString ../.}/${host}/ssh_host_ed25519_key.pub";
  backupPersistClientKeyPath = host: "${toString ../.}/${host}/backup-persist-push_id_ed25519.pub";
  getBackupPersistHostKey =
    host:
    let
      backupPersistHostKeyFilePath = backupPersistHostKeyPath host;
    in
    if builtins.pathExists backupPersistHostKeyFilePath then
      lib.removeSuffix "\n" (builtins.readFile backupPersistHostKeyFilePath)
    else
      throw "assr.services.backup-persist-push: unknown host `${host}`";
  getBackupPersistClientKey =
    host:
    let
      backupPersistClientKeyFilePath = backupPersistClientKeyPath host;
    in
    lib.removeSuffix "\n" (builtins.readFile backupPersistClientKeyFilePath);
in
{
  inherit
    backupPersistHostKeyPath
    backupPersistClientKeyPath
    getBackupPersistHostKey
    getBackupPersistClientKey
    ;
}
