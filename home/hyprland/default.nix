{
  pkgs,
  lib,
  monitors,
  colours,
  username,
  ...
}: let
  centre = monitors.wayland.centre;
  right = monitors.wayland.right;
in {
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
      "$browser" = "zen";
      "$menu" = "wofi --show drun";
      "$screenshot" = "hyprshot -o /home/${username}/Photos/Screenshots";

      input = {
        kb_layout = "us";
        kb_options = "ctrl:swapcaps";
      };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod SHIFT, Return, exec, $browser"
        "$mod, space, exec, $menu"

        # Screenshots
        # ", PRINT, exec, $screenshot -m output"
        # "$mod, PRINT, exec, $screenshot -m window"
        # "$mod SHIFT, PRINT, exec, $screenshot -m region"
        "$mod, s, exec, $screenshot -m region"

        # Volume controls
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"

        # Window navigation
        "$mod SHIFT, Q, killactive"
        "$mod, f, fullscreen, 0"
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

      general = {
        gaps_in = 3;
        gaps_out = 7;
        border_size = 1;
        "col.active_border" = "rgba(${lib.strings.removePrefix "#" colours.green}ee)";
      };

      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
        };
      };
    };

    extraConfig = ''
      monitor = ${centre.name}, ${centre.resolution}@${centre.rate}, 0x0, ${centre.scale}
      monitor = ${right.name}, ${right.resolution}@${right.rate}, 3840x0, ${right.scale}

      # Centre monitor
      workspace = 1, monitor:${centre.name}
      workspace = 2, monitor:${centre.name}
      workspace = 3, monitor:${centre.name}
      workspace = 4, monitor:${centre.name}
      workspace = 5, monitor:${centre.name}

      # Right hand monitor
      workspace = 6, monitor:${right.name}
      workspace = 7, monitor:${right.name}
      workspace = 8, monitor:${right.name}
      workspace = 9, monitor:${right.name}
      workspace = 0, monitor:${right.name}

      animation = workspaces, 0
      animation = windows, 1, 1, default
      animation = fade, 1, 1, default
    '';
  };
}
