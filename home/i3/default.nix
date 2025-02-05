{ pkgs, config, ... }: {
	home.file.".config/i3/config".source = ./config;
	home.file.".config/i3/wallpaper.png".source = ../../wallpaper.png;

	services.picom = {
		enable = true;
		backend = "xrender";
	};
}
