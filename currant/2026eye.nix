{
  users.users."2026eye" = {
    isNormalUser = true;
    description = "2026eye sftp";
    createHome = true;
  
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUwsMg/p63AeCWPvphJ7SwW4tLYVwMS2AApAf1+LkOF kiyurica@2026eye"
    ];
  };
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  
    extraConfig = ''
      Match User 2026eye
        ForceCommand internal-sftp
      
        AllowTcpForwarding no
        X11Forwarding no
        AllowAgentForwarding no
    '';
  };
}
