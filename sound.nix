{ pkgs, ... }: {
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # see https://ccrma.stanford.edu/docs/common/JackTrip.html#:~:text=JackTrip's%20default%20UDP%20port%20number%20is%204464.
  # also see https://help.jacktrip.org/hc/en-us/articles/360057149533-Troubleshooting-Firewall-Ports
  networking.firewall.allowedUDPPortRanges = [
    { from = 4464; to = 4504; }
    { from = 61002; to = 62000; }
  ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 4464; to = 4504; }
    { from = 61002; to = 62000; }
  ];

  environment.systemPackages = with pkgs; [ qjackctl jacktrip ];
}
