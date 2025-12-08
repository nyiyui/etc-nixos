{
  config,
  lib,
  pkgs,
  declarative-flatpak,
  ...
}:

{
  imports = [
    ./base.nix
    ./grc.nix
    ./pexec.nix
    ./neovim.nix
    ./fonts.nix
    ./firefox.nix
    ./sayonara.nix
    ./kicad.nix
    declarative-flatpak.homeModules.default
  ];

  programs.git = {
    enable = true;
    userName = "Ken Shibata";
    userEmail = "ken.shibata+git@kiyuri.ca";
    lfs.enable = true;
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
      rerere.enabled = true;
      fetch.writeCommitGraph = true; # make commit-graph on fetch - speedup git log etc
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
      set fish_greeting
      ${builtins.readFile ./profile.sh}
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
  programs.foot = {
    enable = true;
    server.enable = true;
    settings.colors.alpha = 0.5;
    settings.colors.background = "000000";
    settings.main.shell = "fish";
    settings.main.font = "JetBrainsMono:size=12,NotoColorEmoji:size=12,hack:size=12";
  };
  home.packages =
    with pkgs;
    [
      nmap
      sshfs
      git-filter-repo

      pulseaudio
      playerctl
      clipman
      libsForQt5.ark
      eza
      networkmanagerapplet # provides nm-connection-editor
      darktable
      imagemagick
      libreoffice-qt
      notify-desktop
      pdftk
      pdfchain # GUI for pdftk
      qrencode
      # python310Packages.ipython # temporarily disabled due to sphinx/python3.10 bug in nixos-25.05
      poppler_utils
      meld
      age
      rnote

      libsixel # for img2sixel for images in terminal

      hunspell

      seahorse
      gcr # for gnome keyring prompt https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1135974195
      krita
      gimp

      calc

      freerdp3 # RDP
      thunderbird

      nixfmt-rfc-style

      zathura
      lyx # goated TeX editor
      texliveFull # compile LyX files to PDF

      joplin
      joplin-desktop
    ]
    ++ (with pkgs.libsForQt5; [
      gwenview
      kate
      ctags
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
    (self: super: {
      mpv = super.mpv.override { scripts = [ self.mpvScripts.mpris ]; };
    })
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

  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "elementary" = "https://flatpak.elementary.io/repo.flatpakrepo";
    };
    packages = [
      "elementary:app/io.elementary.capnet-assist//stable"
      "flathub:app/io.github.dzheremi2.lrcmake-gtk//stable"
    ];
  };
}
