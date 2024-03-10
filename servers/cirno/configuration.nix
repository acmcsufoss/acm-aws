{ config, lib, pkgs, modulesPath, ... }:

{
	imports = [
		(modulesPath + "/virtualisation/amazon-image.nix")
		./services.nix
		./telemetry.nix
	];

	networking.hostName = "cirno";

	services.tailscale.enable = true;

	# Use Terraform's AWS rules for this.
	networking.firewall.enable = false;

	environment.systemPackages = with pkgs; [
		ncdu
	];
}
