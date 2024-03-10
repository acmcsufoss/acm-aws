{ lib, sources, buildJavaPackage, fetchFromGitHub }:

let
	pkgs = import (fetchFromGitHub {
		owner = "NixOS";
		repo = "nixpkgs";
		rev = "63e45105d84fe731ec720fb9dabd96e4b47de653";
		sha256 = "sha256-Xn6by6uU3FDhKR9hU1TGvLGW4ES/IGOcpGZlO3MXSMc=";
	}) {};

	jre = pkgs.callPackage ../jre-small {};
in

assert lib.versionAtLeast jre.version "19.0.0";

buildJavaPackage {
	pname = "triggers";
	jar = sources.triggers;
	inherit jre;
}
