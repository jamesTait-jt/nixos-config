{colours, ...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };

      background = [
        {
          path = "${../../wallpapers/forest-stairs.png}";
          blur_passes = 2;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -35";
          outline_thickness = 4;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = colours.rgb.green;
          inner_color = colours.rgb.bg0;
          font_color = colours.rgb.fg;
          check_color = colours.rgb.green;
          fail_color = colours.rgb.red;
          capslock_color = colours.rgb.purple;
          fade_on_empty = false;
          placeholder_text = ''
            <span foreground="#${colours.fg}">Password...</span>
          '';
          hide_input = false;
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
