{ ... }:
{
  # don't use accounts.email as it doesn't support OAuth2
  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.default = {
    isDefault = true;
  };
}
