{ pkgs ? import ./nix/nixpkgs.nix }:

pkgs.mkShell {
	name = "acm-aws-shell";
	buildInputs = with pkgs; [
		terraform
		awscli2
		nix-update
		niv
		git
		git-crypt
		yamllint
		gomod2nix
		expect
		shellcheck
	];

	shellHook = ''
		export NIX_PATH=$NIX_PATH:acm-aws=$PWD
	'';
}
