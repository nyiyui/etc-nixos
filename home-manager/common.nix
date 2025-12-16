{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./base.nix
    ./grc.nix
    ./pexec.nix
    ./neovim.nix
    ./fonts.nix
    ./kicad.nix
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "Ken Shibata";
      user.email = "ken.shibata@kiyuri.ca";
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
      ${builtins.readFile ./profile.fish}
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
      eza
      networkmanagerapplet # provides nm-connection-editor
      darktable
      imagemagick
      notify-desktop
      pdftk
      qrencode
      poppler-utils
      meld
      age

      libsixel # for img2sixel for images in terminal

      hunspell

      seahorse
      gcr # for gnome keyring prompt https://github.com/NixOS/nixpkgs/issues/174099#issuecomment-1135974195
      krita
      gimp

      calc

      freerdp

      nixfmt-rfc-style

      zathura
      lyx # goated TeX editor
      texliveFull # compile LyX files to PDF

      joplin
      joplin-desktop
    ]
    ++ (with pkgs.kdePackages; [
      gwenview
      kate
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

  programs.ssh.enableDefaultConfig = false;
}
