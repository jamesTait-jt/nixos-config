{
  config,
  pkgs,
  ...
}: {
  imports = [
        ./alacritty/alacritty.nix
  ];
  #programs.wezterm = {
  #	enable = true;
  #};

  #home.file.".config/wezterm" = {
  #	source = ./wezterm;
  #};


  #home.file.".config/alacritty" = {
  #  source = ./alacritty;
  #};
}
