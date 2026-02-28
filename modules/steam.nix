{pkgs, ...}: {
  programs.steam = {
    enable = true;

    # Allow Steam Remote Play
    remotePlay.openFirewall = true;

    # Allow Steam servers
    dedicatedServer.openFirewall = true;
  };

  hardware.graphics.enable = true;
}
