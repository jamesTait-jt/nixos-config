{pkgs, ...}: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  environment.systemPackages = with pkgs; [
    # GUI for managing sound settings
    pavucontrol
  ];
}
