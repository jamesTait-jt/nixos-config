{ config, ... }: let
	d = config.xdg.dataHome;
	c = config.xdg.configHome;
	cache = config.xdg.cacheHome;
in {
	imports = [
		./terminals.nix
		./zsh/default.nix
	];

	home.sessionVariables = {
		# Clean up ~
		LESSHISTFILE = cache + "/less/history";
		LESSKEY = c + "/less/lesskey";
		WINEPREFIX = d + "/wine";

		# Set default apps
		EDITOR = "vim";
		TERMINAL = "alacritty";
	};
}
