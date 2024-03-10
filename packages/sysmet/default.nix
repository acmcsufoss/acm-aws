{ buildGoModule, pkgutil, sources, fetchFromGitHub, lib, stdenv }:

buildGoModule rec {
	pname = "sysmet";
	version = pkgutil.version src;
	src = sources.sysmet;
	vendorSha256 = "sha256:11xqr301fjjx9685svap6ymz61q4li426jn69h9mfrzg16qzr0yv";
}
