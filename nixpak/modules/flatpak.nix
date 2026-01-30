{ appId }: {
  config.flatpak.appId = appId;
  config.bubblewrap.env.FLATPAK_APP_ID = appId;
}
