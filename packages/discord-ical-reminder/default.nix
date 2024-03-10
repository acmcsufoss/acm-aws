{ pkgs, fetchFromGitHub, sources, lib }:

let
	newerPkgs = fetchFromGitHub {
		owner = "NixOS";
		repo = "nixpkgs";
		rev = "4dfe713f0802a4e3d4b1ff2318c642dec13012b3";
		sha256 = "sha256-OoQs9YfbgrlFMPNB6hUH65FqlcPs/MAWPyaDs96Qt0U=";
	};

	go = pkgs.callPackage "${newerPkgs}/pkgs/development/compilers/go/1.21.nix" {
		inherit (pkgs.darwin.apple_sdk_11_0.frameworks) Foundation Security;
		buildGo121Module = null;
	};

	buildGo121Module =
		if pkgs ? "buildGo121Module" then
			pkgs.buildGo121Module
		else
			pkgs.callPackage "${newerPkgs}/pkgs/build-support/go/module.nix" {
				inherit go;
			};
in
 
buildGo121Module rec {
  pname = "discord-ical-reminder";
  version = builtins.substring 0 7 src.rev;
 
  src = sources.discord-ical-reminder;
  subPackages = [ "." ];
  vendorSha256 = "sha256-nYBaqD4atFpTgxW2UqxhLNGJ5rAtJrZ13wdAgW0908w=";
}
