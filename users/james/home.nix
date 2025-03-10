{
  pkgs,
  nvf,
  ...
}: {
  imports = [
    ../../home/core.nix

    ../../home/nvim
    #../../home/i3
    ../../home/hyprland
    ../../home/shell
    ../../home/browser
    ../../home/feh.nix
    ../../home/spotify.nix
    ../../home/cursor.nix

    nvf.homeManagerModules.default
  ];

  programs.git = {
    enable = true;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = "true";
      user = {
        name = "James Tait";
        email = "jamesatait12@gmail.com";
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };
}
