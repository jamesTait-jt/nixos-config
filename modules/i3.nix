{ pkgs, ... }: {
	services.xserver = {
		enable = true;

		# Use GDM as the login manager
		displayManager.gdm.enable = true;

		windowManager.i3 = {
			enable = true;
			package = pkgs.i3-gaps;
			extraPackages = with pkgs; [
				# Application launcher
				dmenu
				# Status bar
				i3status
				# Screen locker
				i3lock
				# Compositor for transparent background
				picom
				#Sets wallpaper
				feh
			];
		};

		xkb.layout = "gb";
	};
}
