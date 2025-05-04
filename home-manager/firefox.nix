{ pkgs, ... }: {
  programs.firefox = {
    enable = true;
    policies.CaptivePortal = false;
    policies.DefaultDownloadDirectory = "/home/kiyurica/dl";
    policies.DisableFirefoxStudies = true;
    policies.DisablePocket = true;
    policies.DisableSetDesktopBackground = true;
    policies.SkipTermsOfUse = true;
  };
}
