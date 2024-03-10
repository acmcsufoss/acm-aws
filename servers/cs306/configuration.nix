# Edit this configuration file to define what should be installed on
# your system.	Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, self, ... }:

{
	imports = [
		./hardware-configuration.nix
		./services.nix
		./recovery.nix
		./telemetry.nix
		./caddy
	];

	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "cs306"; # Define your hostname.
	networking.networkmanager.enable = true;

	networking.firewall.enable = true; # Enable the firewall.
	networking.firewall.allowedTCPPorts = [ ];
	networking.firewall.allowedUDPPorts = [ ];

	# Set your time zone.
	time.timeZone = "America/Los_Angeles";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	i18n.extraLocaleSettings = {
		LC_ADDRESS = "en_US.UTF-8";
		LC_IDENTIFICATION = "en_US.UTF-8";
		LC_MEASUREMENT = "en_US.UTF-8";
		LC_MONETARY = "en_US.UTF-8";
		LC_NAME = "en_US.UTF-8";
		LC_NUMERIC = "en_US.UTF-8";
		LC_PAPER = "en_US.UTF-8";
		LC_TELEPHONE = "en_US.UTF-8";
		LC_TIME = "en_US.UTF-8";
	};

	nixpkgs.config.allowUnfree = true;

	environment.systemPackages = with pkgs; [
		vim
		wget
	];

	services.openssh.enable = true;

	services.tailscale = {
		enable = true;
		openFirewall = true;
		useRoutingFeatures = "both";
	};

	networking.firewall.interfaces.tailscale0 = {
		allowedTCPPortRanges = [ { from = 0; to = 65535; } ];
		allowedUDPPortRanges = [ { from = 0; to = 65535; } ];
	};

	system.stateVersion = "23.05"; # Did you read the comment?
}
