{
  pkgs,
  lib,
  ...
}: {
  home.file.".config/nvim".source = ./nvim;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LazyVim
      lua-language-server
      stylua
      # Telescope
      ripgrep
    ];

    plugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];
  };
}
