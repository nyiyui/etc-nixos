{ hostname }:
{ config, lib, pkgs, ... }:

{
  imports = [
    ./kde.nix
    ./graphical.nix
    ./per.nix
    ./fonts.nix
    ./tmux.nix
    ./chromium.nix
    ./seekback.nix
    ./grc.nix
    ./virtual-ti83
    ./rclone.nix
    ./pexec.nix
    ./kicad.nix
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

  programs.git = {
    enable = true;
    userName = "nyiyui";
    userEmail = "+@nyiyui.ca";
    extraConfig = {
      init.defaultBranch = "main";
      url."ssh://git@github.com".insteadOf = "https://github.com";
      pull.rebase = true;
      safe.directory = [ "/etc/nixos" ];
      user.signingkey = "711A0A03A5C5D824";
      #commit.gpgsign = true;
    };
  };
  services.gpg-agent = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.gpg = {
    enable = true;
    mutableTrust = false;
  };
  programs.fish = {
    enable = true;
    shellInit = ''
      ${builtins.readFile ./profile.sh}
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
    plugins = [{
      name = "ssh_agent";
      src = pkgs.fetchFromGitHub {
        owner = "ivakyb";
        repo = "fish_ssh_agent";
        rev = "c7aa080d5210f5f525d078df6fdeedfba8db7f9b";
        sha256 =
          "bfd5596390c2a3e89665ac11295805bec8b7dd42b0b6b892a54ceb3212f44b5e";
      };
    }];
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
    # TODO: keep git-blame disabled on start
    enable = true;
    extraConfig = ''
      set rnu nu
      set directory=~/.cache/nvim
      set tabstop=2
      set shiftwidth=2
      set expandtab
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      vim-go
      csv-vim
      coc-clangd
      vim-clang-format
      git-blame-nvim
    ];
  };
  programs.foot = {
    enable = true;
    settings.colors.alpha = 0;
    settings.main.shell = "fish -c tmux";
    settings.main.font = if (hostname == "miyo") then
      "hack:size=14"
    else if (hostname == "hinanawi") then
      "JetBrainsMono:size=10,NotoColorEmoji:size=10,hack:size=10"
    else
      "JetBrainsMono:size=7,NotoColorEmoji:size=7,hack:size=8";
  };
  services.wlsunset = {
    enable = true;
    latitude = lib.mkDefault "43.7159566";
    longitude = lib.mkDefault "-79.3702805";
    temperature = {
      day = lib.mkDefault 5000;
      night = lib.mkDefault 1500;
    };
  };
  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaywm background";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart =
        "${pkgs.swaybg}/bin/swaybg -mfill -i ${../images/keikyu-signal.jpg}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  home.packages = with pkgs;
    [
      go-tools
      gotools
      godef
      gopls

      freecad

      easyeffects
      helvum
      pavucontrol
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
      exa
      (dmenu.overrideAttrs (oldAttrs: rec {
        configFile = writeText "config.def.h"
          ((if config.home.file.hostname.text == "miyo" then
            "#define FONT_SIZE 13"
          else
            "#define FONT_SIZE 10") + "\n"
            + (builtins.readFile ./dmenu.config.def.h));
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
      safeeyes
      gimp
      darktable
      imagemagick
      xournalpp
      rnote
      hunspell
      libreoffice-qt
      anki
      notify-desktop
      audacity
      prusa-slicer
      capitaine-cursors
      pdftk
      qrencode
      wl-clipboard
      jetbrains.idea-community
      python310Packages.ipython
      docker-credential-helpers
      poppler_utils
      meld
      age

      gnome.seahorse
      gcr # for gnome keyring prompt https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1135974195
    ] ++ (with pkgs.libsForQt5; [
      okular
      gwenview
      dolphin
      kate
      ctags
      systemsettings
      akregator
      kmplot
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
  programs.ssh = {
    extraConfig = ''
      Host mcpt.ca
        SetEnv TERM=xterm-256color
    '';
  };

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  home.file.".docker/config.json".text = builtins.toJSON {
    auths = {
      "ghcr.io" = { };
      "https://index.docker.io/v1/" = { };
    };
    credsStore = "secretservice";
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
