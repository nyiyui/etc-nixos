{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:

let
  unstable = import nixpkgs-unstable { system = pkgs.stdenv.hostPlatform.system; };
in
{
  imports = [
    ./ssh-agent.nix
    ./base.nix
    ./grc.nix
    ./pexec.nix
    ./fonts.nix
  ];

  xdg.config.files."git/config".text = ''
    [user]
    	name = Ken Shibata
    	email = ken.shibata@kiyuri.ca
    	signingkey = 711A0A03A5C5D824
    [init]
    	defaultBranch = main
    [url "ssh://git@github.com"]
    	insteadOf = https://github.com
    [pull]
    	rebase = true
    [safe]
    	directory = /etc/nixos
    	directory = /etc/nixos/.git
    [merge]
    	tool = meld
    [mergetool "meld"]
    	path = ${pkgs.meld}/bin/meld
    [rerere]
    	enabled = true
    [fetch]
    	writeCommitGraph = true
  '';

  # Fish shell configuration
  xdg.config.files."fish/config.fish".text = ''
    set fish_greeting
    ${builtins.readFile ./profile.fish}
  '';

  # Foot terminal configuration
  xdg.config.files."foot/foot.ini".text = ''
    [main]
    shell=fish
    font=JetBrainsMono:size=12,NotoColorEmoji:size=12,hack:size=12

    [colors]
    alpha=0.5
    background=000000
  '';

  # mpv configuration
  xdg.config.files."mpv/mpv.conf".text = ''
    hwdec=auto-safe
    vo=gpu
    profile=gpu-hg
    gpu-context=wayland
  '';

  # yt-dlp configuration
  xdg.config.files."yt-dlp/config".text = ''
    --write-subs
    --sub-langs all
    --cookies-from-browser firefox
    --no-embed-info-json
    --embed-metadata
    --embed-thumbnail
    --embed-subs
  '';

  packages =
    with pkgs;
    [
      git
      git-lfs
      gnupg
      fish
      foot
      (mpv.override { scripts = [ mpvScripts.mpris ]; })
      unstable.yt-dlp

      nmap
      sshfs
      git-filter-repo

      pulseaudio
      playerctl
      clipman
      eza
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
      gimp

      calc

      freerdp

      nixfmt-rfc-style

      lyx # goated TeX editor
    ]
    ++ (with pkgs.kdePackages; [
      gwenview
      kate
    ])
    ++ (with pkgs.hunspellDicts; [
      en_CA
      en_US
    ]);

  systemd.services.mpris-proxy = {
    description = "Mpris proxy";
    unitConfig.After = [
      "network.target"
      "sound.target"
    ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    wantedBy = [ "default.target" ];
  };

  # Hjem doesn't support nixpkgs.overlays inside the user module.
  # These should be moved to the NixOS level if needed, or we can just use the packages directly.
  # For mpv with mpris, we can override it in the packages list above if we want.
}