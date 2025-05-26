{
  monitors,
  colours,
  ...
}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [
          monitors.wayland.centre.name
        ];

        modules-left = ["hyprland/workspaces" "hyprland/mode"];
        modules-center = ["custom/spotify"];
        modules-right = [
          "network"
          "memory"
          "cpu"
          "temperature"
          "battery"
          "tray"
          "clock#date"
          "clock#time"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          persistent-workspaces = {
            "${monitors.wayland.centre.name}" = [1 2 3 4 5 6 7 8 9];
          };
          format = "{icon} {name}";
          format-icons = {
            active = "";
            default = "";
          };
        };

        "custom/spotify" = {
          interval = 2;
          exec = ''
            spotify_player get key playback | jq -r 'if .item then " \(.item.artists[0].name) - \(.item.name)" else empty end'
          '';
          on-click = "spotify_player playback play-pause";
        };

        "clock#time" = {
          interval = 1;
          format = "{:%H:%M:%S}";
          tooltip = false;
        };

        "clock#date" = {
          interval = 10;
          format = "  {:%e %b %Y}";
          tooltip-format = "{:%e %B %Y}";
        };

        "cpu" = {
          interval = 5;
          format = " {usage}% ({load})";
          states = {
            warning = 70;
            critical = 9;
          };
        };

        "memory" = {
          interval = 5;
          format = " {}%";
          states = {
            warning = 70;
            critical = 90;
          };
        };

        "network" = {
          interval = 5;
          format-wifi = " {essid} ({signalStrength}%)";
          format-ethernet = " {ifname}: {ipaddr}/{cidr}";
          format-disconnected = "⚠ Disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        "temperature" = {
          critical-threshold = 80;
          interval = 5;
          format = "{icon}  {temperatureC}°C";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          tooltip = true;
        };
      };
    };

    style = ''
      #waybar {
        background: ${colours.bg0};
        color: ${colours.fg};
        font-family: "JetBrainsMono NF", "JetBrainsMono", "JetBrainsMono Nerd Font";
        font-size: 16px;
      }

      /* Each module */
      #battery,
      #clock,
      #cpu,
      #custom-keyboard-layout,
      #memory,
      #mode,
      #network,
      #pulseaudio,
      #temperature,
      #tray {
        padding-left: 10px;
        padding-right: 10px;
      }

      #workspaces button {
        padding-right: 5px;
        color: ${colours.fg};
      }

      #workspaces button.active{
          border-color: ${colours.bg0};
          color: ${colours.green};
          background-color: ${colours.bg0};
      }

      #workspaces button.urgent {
          border-color: #c9545d;
          color: #c9545d;
      }

      #custom-spotify {
        font-size: 14;
        font-weight: bold;
        color: ${colours.green};
      }

      #clock {
        font-weight: bold;
      }

      #cpu {
        /* No styles */
      }

      #cpu.warning {
          color: orange;
      }

      #cpu.critical {
          color: red;
      }

      #memory {
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #memory.warning {
        color: orange;
      }

      #memory.critical {
        color: red;
        animation-name: blink-critical;
        animation-duration: 2s;
      }

      #network {
          /* No styles */
      }

      #network.disconnected {
          color: orange;
      }

      #temperature {
        /* No styles */
      }

      #temperature.critical {
          color: red;
      }
    '';
  };
}
