{ ... }: {
  imports = [ ./home-manager.nix ];

  home-manager.users.nyiyui = {
    imports = [ ./home-manager/touchscreen.nix ];
  };
  users.users.nyiyui.extraGroups = [ "input" ]; # required for fusuma (see home-manager/touchscreen.nix)
}
