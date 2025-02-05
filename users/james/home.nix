{ pkgs, ... }: {
	imports = [
		../../home/core.nix

		../../home/i3
		../../home/shell
	];
	
	programs.git = {
		enable = true;
		
		extraConfig = {
			init.defaultBranch = "trunk";
			user = {
				name = "James Tait";
				email = "jamesatait12@gmail.com";
			};
		};
	};
}
