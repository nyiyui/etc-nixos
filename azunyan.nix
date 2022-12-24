{ config, lib, pkgs, ... }:

{
  home.username = "azunyan";
  home.homeDirectory = "/home/azunyan";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  wayland.windowManager.sway = {
    enable = true;
    extraConfig = ''
      default_border none
      default_floating_border none
    '';
    config = rec {
      modifier = "Mod4";
      terminal = "foot"; 
      startup = [
        {command = "${pkgs.chromium}/bin/chromium";}
      ];
      keybindings = let modifier = config.wayland.windowManager.sway.config.modifier; in lib.mkOptionDefault {
        # use wev to find pressed keys
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%";
        "XF86AudioPlay" = "exec playerctl play-pause";
	# Screenshots 
	"Print" = "exec grim - | tee ~/.cache/screenshot.png | wl-copy";
	"Shift+Print" = ''exec grim -g "$(slurp)" - | tee ~/.cache/screenshot.png | wl-copy'';
	"${modifier}+Print" = ''exec grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee ~/.cache/screenshot.png | wl-copy'';
	"XF86MonBrightnessUp" = "exec light -A 1";
	"XF86MonBrightnessDown" = "exec light -U 1";
      };
      menu = "${pkgs.dmenu}/bin/dmenu_run";
      input = {
        "*" = {
	  tap = "enabled";
	  xkb_options = "compose:caps";
	};
      };
      bars = [{
        mode = "dock";
        hiddenState = "hide";
        position = "bottom";
        workspaceButtons = true;
        workspaceNumbers = true;
        statusCommand = "${pkgs.i3status}/bin/i3status";
        fonts = {
          names = [ "Hack" ];
          size = 10.0;
        };
        trayOutput = "primary";
        colors = {
          background = "#002d38";
          statusline = "#98a8a8";
          separator = "#5b7279";
          focusedWorkspace = {
            border = "#093946";
            background = "#093946";
            text = "#259d94";
          };
          activeWorkspace = {
            border = "#093946";
            background = "#093946";
            text = "#ffffff";
          };
          inactiveWorkspace = {
            border = "#093946";
            background = "#093946";
            text = "#657377";
          };
          urgentWorkspace = {
            border = "#093946";
            background = "#093946";
            text = "#d56500";
          };
          bindingMode = {
            border = "#093946";
            background = "#093946";
            text = "#ffffff";
          };
        };
      }];
    };
  };

  programs.neovim = {
    enable = true;
    extraConfig = ''
      set rnu nu
      set directory=~/.cache/nvim
    '';
  };
  programs.foot = {
    enable = true;
  };
  home.packages = with pkgs; [
    pavucontrol
    swaylock
    pulseaudio
    playerctl
    # for screenshots
    slurp
    grim
    wl-clipboard
    jq
    exa
    (dmenu.overrideAttrs (oldAttrs: rec {
      configFile = writeText "config.def.h" (builtins.readFile /etc/nixos/nyiyui/dmenu.config.def.h);
      postPatch = "${oldAttrs.postPatch}\n cp ${configFile} config.def.h";
      patches = [
        (fetchpatch {
	  url = "https://tools.suckless.org/dmenu/patches/alpha/dmenu-alpha-20210605-1a13d04.diff";
          sha256 = "0dvywy7gv3s900xxvcgnlg1vaypkrvydkab5837jid22m8m4cjhy";
	})
        # below is workaround for alpha patch (add -lXrender to config.mk)
	/etc/nixos/nyiyui/dmenu-alpha-mk.patch
      ];
    }))
    libsForQt5.okular
    libsForQt5.breeze-qt5
    libsForQt5.breeze-icons
  ];
}
