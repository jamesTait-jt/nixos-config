{
	imports = [
		./terminals.nix
		./zsh/default.nix
	];

	home.sessionVariables = {
		# Set default apps
		EDITOR = "vim";
		TERMINAL = "alacritty";
	};
}
