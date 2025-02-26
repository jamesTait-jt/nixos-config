{pkgs, ...}: {
  # Enable hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # Enable clipboard sharing with neovim
    wl-clipboard

    # Enable monitor orientation in sddm
    # xorg.xrandr

    # screenshots
    hyprshot

    # Theme for sddm
    (catppuccin-sddm.override
      {
        flavor = "mocha";
        font = "Noto Sans";
        fontSize = "9";
        background = "${../wallpapers/forest-stairs.png}";
        loginBackground = true;
      })
  ];

  # Enable sddm as the login manager
  services.displayManager.sddm = {
    wayland.enable = true;
    enable = true;
    theme = "catppuccin-mocha";
    package = pkgs.kdePackages.sddm;
  };
}
