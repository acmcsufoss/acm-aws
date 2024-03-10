{ config, lib, pkgs, self, ... }:

let
	environment = import (self + "/secrets/caddy-env.nix") {
		inherit lib self;
	};

	preprocessedCaddyfile = pkgs.runCommandLocal "Caddyfile-preprocessed" {} ''
		cp ${./Caddyfile} $out

		# Ensure that all acmcsuf.com domains are prefixed with "http://".
		# Otherwise, Caddy will refuse to listen on port 80 at all, which
		# we want for our reverse proxy in cirno.
		sed -i 's/\(^\|, \)\([a-zA-Z0-9\-_.]*\.acmcsuf.com\)/\1http:\/\/\2/g' $out

		# ip_sources.static doesn't do expansion, so we have to do it manually.
		sed -i 's/{env.CADDY_PUBLIC_IP}/${environment.CADDY_PUBLIC_IP}/g' $out
	'';
in

{
	services.diamondburned.caddy = {
		enable = true;
		configFile = preprocessedCaddyfile;
		inherit environment;
	};
}
