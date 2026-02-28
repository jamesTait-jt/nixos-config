{
  pkgs,
  lib,
  ...
}: {
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LSPs
      lua-language-server
      vtsls
      harper
      gopls
      omnisharp-roslyn
      nodePackages.bash-language-server

      # Formatter (example)
      stylua
      alejandra

      # Telescope dependencies
      ripgrep
      fd
    ];

    plugins = with pkgs.vimPlugins; [lazy-nvim];
  };
}
