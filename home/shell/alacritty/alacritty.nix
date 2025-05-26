{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal.family = "JetBrains Mono Nerd Font";
        bold.family = "JetBrains Mono Nerd Font";
        italic.family = "JetBrains Mono Nerd Font";
        bold_italic.family = "JetBrains Mono Nerd Font";
        size = 13.0;
      };

      window = {
        opacity = 1;
        decorations = "none";
        padding.x = 10;
        padding.y = 10;
      };

      colors = {
        primary.background = colours.bg0;
        primary.foreground = colours.fg;

        normal = {
          black = colours.bg3;
          red = colours.red;
          green = colours.green;
          yellow = colours.yellow;
          blue = colours.blue;
          magenta = colours.purple;
          cyan = colours.aqua;
          white = colours.statusline1;
        };
        bright = {
          black = colours.bg4;
          red = colours.red;
          green = colours.green;
          yellow = colours.yellow;
          blue = colours.blue;
          magenta = colours.purple;
          cyan = colours.aqua;
          white = colours.statusline1;
        };
      };
    };
  };
}
