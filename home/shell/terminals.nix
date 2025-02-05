{ config, pkgs, ... }: {
	#programs.wezterm = {
	#	enable = true;
	#};

	#home.file.".config/wezterm" = {
	#	source = ./wezterm;
	#};
	
	programs.alacritty = {
		enable = true;
	};

	home.file.".config/alacritty" = {
		source = ./alacritty;
	};
}
