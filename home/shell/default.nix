{
  imports = [
    ./terminals.nix
    ./starship.nix
    ./zsh/default.nix
  ];

  home.sessionVariables = {
    # Set default apps
    EDITOR = "nvim";
    TERMINAL = "alacritty";
  };
}
