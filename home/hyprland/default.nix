{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hyprpaper.nix
    ./waybar.nix
  ];

  services.cliphist.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "ALT";
      "$terminal" = "alacritty";

      input = {
        kb_layout = "gb";
      };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, Return, exec, brave"

        # Window navigation
        "$mod SHIFT, Q, killactive"
        "$mod, f, fullscreen, 1"
        "$mod, h, movefocus, l"
        "$mod, j, movefocus, d"
        "$mod, k, movefocus, u"
        "$mod, l, movefocus, r"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, j, movewindow, d"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, l, movewindow, r"
      ];
    };

    extraConfig = ''
      monitor = HDMI-A-1, 1920x1080@144, 0x0, 1
      monitor = DVI-D-1, 1920x1080, 1920x0, 1
    '';
  };
}
