{ config, lib, ... }: {
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # UBlock Origin
      { id = "mclkkofklkfljcocdinagocijmpgbhab"; } # japanese input
    ];
  };
  programs.firefox = { enable = true; };
}
