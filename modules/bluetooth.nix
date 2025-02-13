{pkgs, ...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # GUI for managing bluetooth devices
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    # Core bluetooth utils
    bluez
    # CLI bluetooth tools
    bluez-tools
  ];
}
