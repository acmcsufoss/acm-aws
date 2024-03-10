{ config, pkgs, lib, self, ... }:

{
	imports = [
		./caddy/caddy.nix
		./sysmet/sysmet.nix
		./dischord/service.nix
		./christmasd/service.nix
	];

	nixpkgs.overlays = [
		(self.overlays.buildTools)
		(self: super: import ./. { pkgs = super; })
	];
}
