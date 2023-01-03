{ hostname }:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./graphical.nix
    ./graphical-per.nix
  ];

  home.file.hostname.text = hostname;

  home.username = "nyiyui";
  home.homeDirectory = "/home/nyiyui";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "nyiyui";
    userEmail = "+@nyiyui.ca";
    extraConfig = {
      init.defaultBranch = "main";
      url."ssh://git@github.com".insteadOf = "https://github.com";
      pull.rebase = true;
      safe.directory = [ "/etc/nixos" ];
    };
  };
  programs.fish = {
    enable = true;
    shellInit = ''
      ${builtins.readFile ./profile.sh}
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
    plugins = [
      {
        name = "ssh_agent";
        src = pkgs.fetchFromGitHub {
          owner = "ivakyb";
          repo = "fish_ssh_agent";
          rev = "c7aa080d5210f5f525d078df6fdeedfba8db7f9b";
          sha256 = "bfd5596390c2a3e89665ac11295805bec8b7dd42b0b6b892a54ceb3212f44b5e";
        };
      }
    ];
  };
  programs.bash = {
    historySize = 20000;
    initExtra = ''source ~/inaba/dots/sh/sh.sh'';
    bashrcExtra = ''
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
  };
  programs.neovim = {
    enable = true;
    extraConfig = ''
      set rnu nu
      set directory=~/.cache/nvim
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-go
      csv-vim
    ];
  };
  programs.foot = {
    enable = true;
    settings.colors.alpha = 0;
    settings.main.shell = "fish";
    settings.main.font = if (hostname == "miyo") then "hack:size=14" else "hack:size=8";
  };
  services.wlsunset = {
    enable = true;
    latitude = "43.7159566";
    longitude = "-79.3702805";
    temperature = {
      day = 5000;
      night = 1500;
    };
  };
  systemd.user.services.safeeyes = {
    Unit = {
      Description = "Safe eyes: simple and beautiful, yet extensible break reminder";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.safeeyes}/bin/safeeyes";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaywm background";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i /home/nyiyui/inaba/kabegami/redial_52.png";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  home.packages = with pkgs; [
    go-tools
    gotools
    godef
    gopls

    pavucontrol
    swaybg
    swaylock
    pulseaudio
    playerctl
    wlsunset
    keepassxc
    tor
    tor-browser-bundle-bin
    clipman
    ark
    go_1_19
    # for screenshots
    slurp
    grim
    wl-clipboard
    jq
    exa
    (dmenu.overrideAttrs (oldAttrs: rec {
      configFile = writeText "config.def.h" (builtins.readFile ./dmenu.config.def.h);
      postPatch = "${oldAttrs.postPatch}\n cp ${configFile} config.def.h";
      patches = [
        ./dmenu-alpha-20210605-1a13d04.diff
        # below is workaround for alpha patch (add -lXrender to config.mk)
        ./dmenu-alpha-mk.patch
      ];
    }))
    networkmanagerapplet # provides nm-connection-editor
    lxqt.pcmanfm-qt
    obs-studio
    obs-studio-plugins.wlrobs
    obs-studio-plugins.obs-pipewire-audio-capture
    urn-timer
    safeeyes
    gimp
    xournalpp
    hunspell
    libreoffice-qt
    anki
    super-slicer
    notify-desktop
    audacity
  ] ++ (with pkgs.libsForQt5; [
    okular
    breeze-qt5
    breeze-icons
    kate
    ctags
    systemsettings
    kdenlive
    akregator
  ]) ++ (with pkgs.hunspellDicts; [
    en_CA
    en_US
  ]);

  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";
      vo = "gpu";
      profile = "gpu-hg";
      gpu-context = "wayland";
    };
  };
  nixpkgs.overlays = [
    (self: super: {
      mpv = super.mpv.override {
        scripts = [ self.mpvScripts.mpris ];
      };
    })
  ];
  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "network.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
  programs.ssh = {
    extraConfig = ''
      Host mcpt.ca
        SetEnv TERM=xterm-256color
    '';
  };
}
