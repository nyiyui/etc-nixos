{ hostname }:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./graphical-tektem.nix
    ./per.nix
    ./fonts.nix
    ./tmux.nix
    ./chromium.nix
    ./seekback.nix
  ];

  nixpkgs.config.allowUnfree = true;

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
  home.stateVersion = "22.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    shellInit = ''
      ${builtins.readFile ./profile.sh}
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
  };
  programs.bash = {
    historySize = 20000;
    initExtra = "source ~/inaba/dots/sh/sh.sh";
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
      set tabstop=2
      set shiftwidth=2
      set expandtab
    '';
    plugins = with pkgs.vimPlugins; [ vim-nix csv-vim ];
  };
  programs.foot = {
    enable = true;
    settings.colors.alpha = 0;
    settings.main.shell = "fish -c tmux";
    settings.main.font = if (hostname == "hinanawi") then
      "JetBrainsMono:size=8,NotoColorEmoji:size=8,hack:size=8"
    else
      "JetBrainsMono:size=7,NotoColorEmoji:size=7,hack:size=8";
  };
  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaywm background";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -c #000000 -mfill";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  home.packages = with pkgs;
    [
      ola
      easyeffects
      helvum
      pavucontrol
      swaylock
      pulseaudio
      playerctl
      tor
      tor-browser-bundle-bin
      clipman
      ark
      exa
      (dmenu.overrideAttrs (oldAttrs: rec {
        configFile =
          writeText "config.def.h" (builtins.readFile ./dmenu.config.def.h);
        postPatch = ''
          ${oldAttrs.postPatch}
           cp ${configFile} config.def.h'';
        patches = [
          ./dmenu-alpha-20210605-1a13d04.diff
          # below is workaround for alpha patch (add -lXrender to config.mk)
          ./dmenu-alpha-mk.patch
        ];
      }))
      networkmanagerapplet # provides nm-connection-editor
      obs-studio
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-pipewire-audio-capture
      urn-timer
      gimp
      imagemagick
      xournalpp
      rnote
      hunspell
      libreoffice-qt
      notify-desktop
      audacity
      pdftk
      qrencode
      wl-clipboard
      python310Packages.ipython
      poppler_utils
      meld
      age
    ] ++ (with pkgs.libsForQt5; [
      okular
      gwenview
      dolphin
      kate
      ctags
      systemsettings
    ]) ++ (with pkgs.hunspellDicts; [ en_CA en_US ]);

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
      mpv = super.mpv.override { scripts = [ self.mpvScripts.mpris ]; };
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

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  programs.yt-dlp.enable = true;
  programs.yt-dlp.settings = {
    write-subs = true;
    sub-langs = "all";
    cookies-from-browser = "firefox";
    no-embed-info-json = true;
    embed-metadata = true;
    embed-thumbnail = true;
    embed-subs = true;
  };
}

