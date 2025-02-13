{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Enable hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    wl-clipboard
  ];
}
