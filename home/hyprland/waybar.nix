{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [
          "HDMI-A-1"
          "DVI-D-1"
        ];

        modules-left = ["hyprland/workspaces" "hyprland/mode"];
        #modules-center = ["clock"];
        #modules-right = ["mpd"];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          persistent-workspaces = [1 2 3 4 5 6 7 8 9];
        };
      };
    };
  };
}
