{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hyprpaper.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./waybar.nix
    ./swaync.nix
    ./wofi.nix
  ];

  services.cliphist.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "ALT";
      "$terminal" = "alacritty";
      "$browser" = "brave";
      "$menu" = "wofi --show drun";

      input = {
        kb_layout = "gb";
      };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, Return, exec, $browser"
        "$mod, space, exec, $menu"

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

        # Workspace navigation
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 0"

        "$mod SHIFT, 1, movetoworkspacesilent, 1"
        "$mod SHIFT, 2, movetoworkspacesilent, 2"
        "$mod SHIFT, 3, movetoworkspacesilent, 3"
        "$mod SHIFT, 4, movetoworkspacesilent, 4"
        "$mod SHIFT, 5, movetoworkspacesilent, 5"
        "$mod SHIFT, 6, movetoworkspacesilent, 6"
        "$mod SHIFT, 7, movetoworkspacesilent, 7"
        "$mod SHIFT, 8, movetoworkspacesilent, 8"
        "$mod SHIFT, 9, movetoworkspacesilent, 9"
        "$mod SHIFT, 0, movetoworkspacesilent, 0"
      ];
    };

    extraConfig = ''
      monitor = HDMI-A-1, 1920x1080@144, 0x0, 1
      monitor = DVI-D-1, 1920x1080, 1920x0, 1

      # Centre monitor
      workspace = 1, monitor:HDMI-A-1
      workspace = 2, monitor:HDMI-A-1
      workspace = 3, monitor:HDMI-A-1
      workspace = 4, monitor:HDMI-A-1
      workspace = 5, monitor:HDMI-A-1

      # Right hand monitor
      workspace = 6, monitor:DVI-D-1
      workspace = 7, monitor:DVI-D-1
      workspace = 8, monitor:DVI-D-1
      workspace = 9, monitor:DVI-D-1
      workspace = 0, monitor:DVI-D-1
    '';
  };
}
