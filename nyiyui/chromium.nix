{ config, lib, ... }: {
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; }
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      { id = "mclkkofklkfljcocdinagocijmpgbhab"; }
    ];
  };
  programs.firefox = { enable = true; };
}
