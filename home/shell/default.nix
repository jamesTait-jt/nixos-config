{
  imports = [
    ./terminals.nix
    ./starship.nix
    ./zsh/default.nix
  ];

  home.sessionVariables = {
    # Set default apps
    EDITOR = "vim";
    TERMINAL = "alacritty";
  };
}
