{
  pkgs,
  lib,
  username,
  ...
}: {
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = ["wheel" "networkmanager"];
  };

  nix.settings = {
    # Enable flakes globally
    experimental-features = ["nix-command" "flakes"];
  };

  # Run garbage collection weekly
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set timezone
  time.timeZone = "Europe/London";

  # Configure keymap in X11
  services.xserver.xkb.layout = "gb";

  fonts = {
    packages = with pkgs; [
      # Icon fonts
      material-design-icons

      # Normal fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      roboto

      # Nerdfonts
      (nerdfonts.override {fonts = ["FiraCode" "JetBrainsMono"];})
    ];

    # Use user-specified fonts rather than default
    enableDefaultPackages = false;

    fontconfig.defaultFonts = {
      serif = ["Noto Serif" "Noto Color Emoji"];
      sansSerif = ["Noto Sans" "Noto Color Enoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  # Set up packages and environment
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    gcc
    xclip
  ];
  environment.variables.EDITOR = "vim";

  # Set ZSH as default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
}
