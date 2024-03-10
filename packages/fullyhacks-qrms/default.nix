{ sources, system }:

let
	flake = import sources.fullyhacks-qrms;
in

flake.packages.${system}.default
