{ buildGo119Module, sources, pkgutil, fetchFromGitHub, lib }:

buildGo119Module rec {
	pname = "acmregister";
	version = pkgutil.version src;

	src = sources.acmregister;
	vendorHash = "sha256-QpAj9IGcLEJdPBghrK2nmbk/sZmtY6hB3w7dw2+l7zQ=";

	# GOWORK is incompatible with vendorSha256.
	GOWORK = "off";
	subPackages = [ "." ];
}
