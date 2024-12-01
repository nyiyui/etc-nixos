{ pkgs, ... }: {
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.enabled = true;
  i18n.type = "fcitx5";
  i18n.inputMethod = {
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-hangul fcitx5-gtk ];
  };
}
