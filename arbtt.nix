{ ... }:
{
  services.arbtt = {
    enable = true;
    logFile = "%h/inaba/arbtt/capture.log";
  };
}
