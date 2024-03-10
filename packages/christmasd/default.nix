{ lib, buildGoModule, sources, pkgutil }:

buildGoModule rec {
	pname = "christmasd";

	src = sources.christmasd;
	version = pkgutil.version src;

	vendorHash = "sha256-oCqA4dPfdo5tOehZzdQzlOgcfBJWzW3QppI68nBPi7w=";

	subPackages = [
		"cmd/christmasd"
		"cmd/christmasd-test"
	];
}
