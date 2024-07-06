{
  # TODO
  services.octoprint = {
    enable = true;
    plugins = plugins: with plugins; [ ];
  };
  services.nginx = { };
}
