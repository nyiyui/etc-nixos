{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./base.nix
    ./kde.nix
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
    ./wlsunset.nix
    ./neovim.nix
    ./activitywatch.nix
    ./emacs.nix
  ];

  programs.git = {
    enable = true;
    userName = "nyiyui";
    userEmail = "+@nyiyui.ca";
    extraConfig = {
      init.defaultBranch = "main";
      url."ssh://git@github.com".insteadOf = "https://github.com";
      pull.rebase = true;
      safe.directory = [
        "/etc/nixos"
        "/etc/nixos/.git"
      ];
      user.signingkey = "711A0A03A5C5D824";
      #commit.gpgsign = true;
      merge.tool.path = "${pkgs.meld}/bin/meld";
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
    initExtra = "source ~/inaba/dots/sh/sh.sh";
    bashrcExtra = ''
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    '';
  };
  programs.foot = {
    enable = true;
    settings.colors.alpha = 0.5;
    settings.colors.background = "000000";
    settings.main.shell = "fish -c tmux";
    settings.main.font = "JetBrainsMono:size=12,NotoColorEmoji:size=12,hack:size=12";
  };
  home.packages =
    with pkgs;
    [
      nmap
      git-filter-repo

      freecad

      easyeffects
      helvum

      swaylock
      pulseaudio
      playerctl
      keepassxc
      tor
      tor-browser-bundle-bin
      clipman
      ark
      eza
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
      pdfchain # GUI for pdftk
      qrencode
      wl-clipboard
      jetbrains.idea-community
      python310Packages.ipython
      poppler_utils
      meld
      age

      seahorse
      gcr # for gnome keyring prompt https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1135974195
      krita

      quickemu

      octave # for MATH1554
      calc # for CS2050

      remmina # for RDP from hinanawi to minato
      thunderbird

      links2
      (agda.withPackages [ agdaPackages.standard-library ])
    ]
    ++ (with pkgs.libsForQt5; [
      okular
      gwenview
      dolphin
      kate
      ctags
      systemsettings
      akregator
      kmplot
      sayonara
    ])
    ++ (with pkgs.hunspellDicts; [
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
    (self: super: { mpv = super.mpv.override { scripts = [ self.mpvScripts.mpris ]; }; })
  ];
  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [
      "network.target"
      "sound.target"
    ];
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
    components = [
      "pkcs11"
      "secrets"
      "ssh"
    ];
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
