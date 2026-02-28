{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    claude-code
    nodejs # needed for claude hooks
  ];

  # Symlink entire ~/.claude to our managed config directory
  # Must use a string (not path) to avoid Nix copying to store first
  home.file.".claude".source =
    config.lib.file.mkOutOfStoreSymlink "/home/james/nixos-config/home/claude/claude";
}
