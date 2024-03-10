{ fetchFromGitHub, pkgutil, sources, makeWrapper, lib, stdenv,
  buildGoModule, ffmpeg, yt-dlp }:

let
	PATH = [ ffmpeg yt-dlp ];
in

buildGoModule rec {
	pname = "dischord";
	version = pkgutil.version src;

	src = sources.dischord;
	vendorSha256 = "sha256:12y3gqvprfzqdhfvqhz4pw45bv7wl0lbwa8ijfshdij28ly6l6x3";

	subPackages = [ "cmd/dischord" ];

	postPatch = ''
		ytExtractor='extractor.AddExtractor("youtube", &Extractor{})'
		sed -i "s|$ytExtractor|// &|" $(find . -name '*.go')
	'';

	nativeBuildInputs = [ makeWrapper ];
	postInstall = ''
		wrapProgram $out/bin/dischord --prefix PATH : ${lib.makeBinPath PATH}
	'';
}
