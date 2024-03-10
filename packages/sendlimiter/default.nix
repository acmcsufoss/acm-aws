{ buildGo119Module, sources, pkgutil, fetchFromGitHub, lib }:

buildGo119Module rec {
	pname = "sendlimiter";
	version = pkgutil.version;

	src = sources.sendlimiter;
	vendorSha256 = "sha256-jvpgUDN6ds0An8qDy7RsR3zF2tlU1nczP/TT5oNr098=";

	# GOWORK is incompatible with vendorSha256.
	GOWORK = "off";
	subPackages = [ "." ];
}
