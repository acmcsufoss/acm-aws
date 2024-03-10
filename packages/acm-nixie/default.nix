{ buildGo119Module, pkgutil, sources, lib }:

buildGo119Module rec {
	pname = "acm-nixie";
	version = pkgutil.version src;

	src = sources.acm-nixie;
	vendorSha256 = "sha256-fkDpovDJTn0Moj6eIZU+3e4Kp/DGv/KEUPE3+ahmBR4=";

	subPackages = [ "." ];
}
