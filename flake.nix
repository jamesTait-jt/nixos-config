{
	description = "NixOS configuration";

	inputs = {
		# nixpkgs
		nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

		# home-manager
		home-manager.url = "github:nix-community/home-manager/release-24.11";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";

		# wezterm
		#wezterm.url = "github:wez/wezterm?dir=nix";
	};

	outputs = inputs @ { 
		self,
		nixpkgs,
		home-manager,
		#hyprland,
		...
	}: {
		nixosConfigurations = {
			home-desktop = let
				username = "james";
				specialArgs = {inherit username;};
			in
				nixpkgs.lib.nixosSystem {
					inherit specialArgs;
					system = "x86_64-linux";

					modules = [
						./hosts/home-desktop
						./users/${username}/nixos.nix

						home-manager.nixosModules.home-manager {
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
			
							home-manager.extraSpecialArgs = inputs // specialArgs;
							home-manager.users.${username} = import ./users/${username}/home.nix;
						}
					];
				};
		};
	};
}
