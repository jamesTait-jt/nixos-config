let
  left = "forest-stairs";
  right = "forest-stairs";
in {
  home.file.".config/hypr/wallpapers/forest-stairs.png".source = ../../wallpapers/forest-stairs.png;
  home.file.".config/hypr/wallpapers/sea-rock.png".source = ../../wallpapers/sea-rock.png;
  home.file.".config/hypr/wallpapers/nixos.png".source = ../../wallpapers/nixos.png;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "~/.config/hypr/wallpapers/${left}.png"
        "~/.config/hypr/wallpapers/${right}.png"
      ];
      wallpaper = [
        "HDMI-A-1,~/.config/hypr/wallpapers/${left}.png"
        "DVI-D-1,~/.config/hypr/wallpapers/${right}.png"
      ];
    };
  };
}
