{ config, lib, pkgs, ... }:

let
	sources = import <acm-aws/nix/sources.nix>;
in

{
	imports = [
		./caddy
	];
	
	systemd.services.quizler = {
		enable = true;
		description = "https://github.com/jacobtread/Quizler";
		after = [ "network-online.target" ];
		wantedBy = [ "multi-user.target" ];
		environment = {
			QUIZLER_PORT = "37867"; # see Caddyfile
		};
		serviceConfig = {
			Type = "simple";
			ExecStart = "${pkgs.quizler}/bin/quizler";
			DynamicUser = true;
			Restart = "on-failure";
			RestartSec = "1s";
			# Use strict resource controls since this is an exposed and untrusted
			# service.
			ProtectSystem = "strict";
			ProtectHome = true;
			PrivateDevices = true;
			MemoryMax = "256M";
			TasksMax = 128;
			CPUQuota = "50%";
			RestrictNetworkInterfaces = "lo"; # enough for localhost
		};
	};

	systemd.services.triggers = {
		enable = true;
		description = "Triggers (Crying Counter) Discord bot";
		after = [ "network-online.target" ];
		wantedBy = [ "multi-user.target" ];
		environment = import <acm-aws/secrets/triggers-env.nix>;
		serviceConfig = {
			Type = "simple";
			ExecStart = "${pkgs.triggers}/bin/triggers";
			DynamicUser = true;
			Restart = "on-failure";
			RestartSec = "1s";
		};
	};

	systemd.services.pomo = {
		enable = true;
		description = "Pomodoro timer server/Discord bot";
		after = [ "network-online.target" ];
		wantedBy = [ "multi-user.target" ];
		environment = import <acm-aws/secrets/pomo.nix>;
		serviceConfig = {
			Type = "simple";
			ExecStart = "${pkgs.pomo}/bin/pomo";
			DynamicUser = true;
			Restart = "on-failure";
			RestartSec = "1s";
		};
	};
	
	systemd.services.acm-nixie = {
		enable = true;
		description = "acmCSUF's version of the nixie bot.";
		after = [ "network-online.target" ];
		wantedBy = [ "multi-user.target" ];
		environment = import <acm-aws/secrets/acm-nixie-env.nix>;
		serviceConfig = {
			Type = "simple";
			ExecStart = "${pkgs.acm-nixie}/bin/acm-nixie";
			DynamicUser = true;
			StateDirectory = "acm-nixie";
			ReadWritePaths = [ "/var/lib/acm-nixie" ];
		};
	};

	services.dischord = {
		enable = true;
		config = builtins.readFile <acm-aws/secrets/dischord-config.toml>;
	};

	systemd.services."goworkshop.acmcsuf.com" =
		let
			shell = import "${sources.go-workshop}/shell.nix" { inherit pkgs; };
			present = shell.present;
		in
			{
				enable = true;
				description = "Go x/tools/present server for goworkshop.acmcsuf.com";
				after = [ "network.target" ];
				wantedBy = [ "multi-user.target" ];
				serviceConfig = {
					ExecStart = "${present}/bin/present --play=true --use_playground --http=127.0.0.1:38572";
					DynamicUser = true;
					WorkingDirectory = "${sources.go-workshop}";
				};
			};
}