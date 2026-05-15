{
  config.assertions = [
    {
      assertion = config.boot.initrd.systemd.repart.device != null;
      message = "boot.initrd.systemd.repart.device must be set for systemd-repart to create the root partition itself";
    }
  ];
}
