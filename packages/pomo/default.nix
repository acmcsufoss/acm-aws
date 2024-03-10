{ lib, sources, buildDenoPackage }:

buildDenoPackage rec {
	pname = "pomo";
	src = sources.pomo;
	entrypoint = "server/main.ts";
	outputHash = "sha256-+nz8sQWrz7Rl6eMYdUbRPSP158qL0uFXA1JV5Iy0wx4";
}
