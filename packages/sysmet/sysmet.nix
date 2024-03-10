{ config, lib, pkgs, ... }:

with lib;

let
	cfg = config.services.diamondburned.sysmet;
	enable = cfg.http.enable or cfg.update.enable or cfg.gc.enable;
in
{
	options.services.diamondburned.sysmet = {
		http = {
			enable = mkEnableOption "sysmet HTTP server";
			address = mkOption {
				type = types.str;
				description = "HTTP address to listen on";
			};
		};

		update = {
			enable = mkEnableOption "sysmet update service";
			onCalendar = mkOption {
				type = types.str;
				description = "Update interval, see systemd.time(7)";
			};
		};

		delete = {
			enable = mkEnableOption "sysmet garbage collection service";
			maxDays = mkOption {
				type = types.int;
				description = "Maximum number of days to keep data";
			};
			onCalendar = mkOption {
				type = types.str;
				description = "Garbage collection interval, see systemd.time(7)";
			};
		};

		package = mkOption {
			default = pkgs.callPackage ./default.nix {};
			type = types.package;
			description = "sysmet package to use.";
		};
	};

	config = mkIf enable {
		environment.systemPackages = [ cfg.package ];

		systemd.services.sysmet-http = mkIf cfg.http.enable {
			description = "sysmet HTTP server";
			# after + wants adds an optional dependency on these two services.
			# We want sysmet-http to start after sysmet-update to ensure that
			# sysmet-update's user owns the database file.
			after = [ "network.target" "sysmet-update.service" ];
			wants = [ "network.target" "sysmet-update.service" ];
			requires = [ "network.target" ];
			wantedBy = [ "multi-user.target" ];
			serviceConfig = {
				Type = "simple";
				ExecStart = "${cfg.package}/bin/sysmet-http -db /var/lib/sysmet/db ${cfg.http.address}";
				Restart = "on-failure";
				StateDirectory = "sysmet";
				User = "sysmet";
				Group = "sysmet";
				UMask = "0007";
				ProtectSystem = "strict";
				ProtectHome = "yes";
				PrivateTmp = "yes";
				RemoveIPC = "yes";
			};
		};

		systemd.services.sysmet-update = mkIf cfg.update.enable {
			description = "sysmet update service";
			wantedBy = [ "default.target" ];
			serviceConfig = {
				Type = "oneshot";
				ExecStart = "${cfg.package}/bin/sysmet-update -db /var/lib/sysmet/db";
				StateDirectory = "sysmet";
				User = "sysmet";
				Group = "sysmet";
				UMask = "0007";
				ProtectSystem = "strict";
				ProtectHome = "yes";
				PrivateTmp = "yes";
				RemoveIPC = "yes";
			};
		};

		systemd.timers.sysmet-update = mkIf cfg.update.enable {
			description = "sysmet update timer";
			wantedBy = [ "timers.target" ];
			requires = [ "sysmet-update.service" ];
			wants = [ "sysmet-update.service" ];
			timerConfig = {
				OnCalendar = cfg.update.onCalendar;
				Unit = "sysmet-update.service";
			};
		};

		systemd.services.sysmet-delete = mkIf cfg.delete.enable {
			description = "sysmet garbage collection service";
			wantedBy = [ "default.target" ];
			after = [ "sysmet-update.service" ];
			wants = [ "sysmet-update.service" ];
			serviceConfig = {
				Type = "oneshot";
				ExecStart = ''${cfg.package}/bin/sysmet-update \
						-db /var/lib/sysmet/db \
						-gc ${toString cfg.delete.maxDays}'';
				StateDirectory = "sysmet";
				User = "sysmet";
				Group = "sysmet";
				UMask = "0007";
				ProtectSystem = "strict";
				ProtectHome = "yes";
				PrivateTmp = "yes";
				RemoveIPC = "yes";
			};
		};

		systemd.timers.sysmet-delete = mkIf cfg.delete.enable {
			description = "sysmet garbage collection timer";
			wantedBy = [ "timers.target" ];
			requires = [ "sysmet-delete.service" ];
			wants = [ "sysmet-delete.service" ];
			timerConfig = {
				OnCalendar = cfg.delete.onCalendar;
				Unit = "sysmet-delete.service";
			};
		};

		users.users.sysmet = {
			description = "sysmet services user";
			isSystemUser = true;
			group = "sysmet";
		};

		users.groups.sysmet = {};
	};
}
