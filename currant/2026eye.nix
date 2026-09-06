{
  users.users."2026eye" = {
    isNormalUser = true;
    description = "2026eye sftp";
    createHome = true;
  
    openssh.authorizedKeys.keys = [
      ''from="192.168.2.118",command="internal-sftp",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUwsMg/p63AeCWPvphJ7SwW4tLYVwMS2AApAf1+LkOF kiyurica@2026eye''
    ];
  };
}
