{
  home.file.".config/i3/config".source = ./config;
  home.file.".config/i3/wallpaper.png".source = ../../wallpapers/forest-stairs.png;

  services.picom = {
    enable = true;
    backend = "xrender";
    shadow = false;
    inactiveOpacity = 0.9;

    settings = {
      corner-radius = 10;
    };
  };

  services.polybar = {
    enable = true;
    config = ./polybar-config.ini;
    script = ''
      for m in $(polybar --list-monitors | cut -d":" -f1); do
        MONITOR=$m polybar --reload mottom &
      done
    '';
  };
}
