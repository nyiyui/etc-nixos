{ pkgs, ... }: {
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-hangul fcitx5-gtk ];
  };
}
