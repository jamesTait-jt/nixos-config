{
  pkgs,
  nvf,
  zen-browser,
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
    ../../home/lazygit.nix
    ../../home/minecraft.nix

    nvf.homeManagerModules.default
    zen-browser.homeModules.twilight-official
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
    "text/html" = "zen-browser.desktop";
    "x-scheme-handler/http" = "zen-browser.desktop";
    "x-scheme-handler/https" = "zen-browser.desktop";
    "x-scheme-handler/about" = "zen-browser.desktop";
    "x-scheme-handler/unknown" = "zen-browser.desktop";
  };
}
