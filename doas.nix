{ ... }: {
  # Priviledge Escalation
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [{
    users = [ "nyiyui" ];
    keepEnv = true;
  }];
}
