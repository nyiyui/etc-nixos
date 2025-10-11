{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    policies.CaptivePortal = false;
    policies.DefaultDownloadDirectory = "/home/kiyurica/dl";
    policies.DisableFirefoxStudies = true;
    policies.DisablePocket = true;
    policies.DisableSetDesktopBackground = true;
    policies.SkipTermsOfUse = true;
    policies.Preferences = {
      # Open external links (e.g., from xdg-open) in new windows instead of tabs
      # This is useful when using tiling window managers like niri
      "browser.link.open_newwindow.override.external" = -1;
    };
  };
}
