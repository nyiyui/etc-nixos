{ ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Noto Sans:size=12";
      };
      colors = rec {
        background = "bec8d1cc";
        text = "137a7fff";
        match = "86cecbff";
        selection = "bec8d1ff";
        selection-text = "e12885ff";
        selection-match = match;
      };
      border.width = 0;
      border.radius = 0;
    };
  };
}
