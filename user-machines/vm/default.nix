{ config, lib, pkgs, ... }:

with lib;
with builtins;

# NOTE: DO NOT CHANGE THE UUIDS IN THIS FILE!
# YOU WILL BREAK EVERYTHING!

let
	sources = import <acm-aws/nix/sources.nix> { inherit pkgs; };

	nixvirt = (import sources.flake-compat {
		src = sources.NixVirt;
	}).defaultNix;
	virtlib = nixvirt.lib;

	self = config.acm.user-vms;

	activeUsers = filter (user: !userIsDeleted user) self.users;
	deletedUsers = filter (user: userIsDeleted user) self.users;
	userIsDeleted = user: user ? "deleted" && user.deleted;

	inherit (import ./config.nix { inherit pkgs; })
		lib
		ips
		ubuntu
		volumeSize;

	mkRawImage = image: pkgs.runCommand
		"${image.name}-raw.img"
		{ nativeBuildInputs = with pkgs; [ qemu ]; }
		"qemu-img convert -O raw ${image} $out";

	# utility value that signifies that a case is _impossible_.
	_impossible_ = throw "This should be _impossible_";
in

{
	imports = [
		nixvirt.nixosModules.default
	];
	
	options.acm = {
		user-vms = {
			enable = mkEnableOption "Enable the service for managing VMs for ACM members";
	
			poolDirectory = mkOption {
				type = types.str;
				default = "/var/lib/acm-vm";
				description = "The directory to store VM disk images in.";
			};
	
			virtConnection = mkOption {
				type = types.str;
				default = "qemu:///system";
				description = "The libvirt connection URI to use.";
			};

			cpuPinning = mkOption {
				type = types.nullOr (types.listOf types.int);
				default = null;
				# default = [4 5 6 7];
				description = "The CPU cores to pin VMs to.";
			};
	
			users = mkOption {
				type = types.listOf (types.submodule {
					options = {
						id = mkOption {
							type = types.str;
							description = "The username of the user.";
						};
						name = mkOption {
							type = types.str;
							description = "The full name of the user.";
						};
						email = mkOption {
							type = types.listOf types.email;
							default = [];
							description = "The email addresses of the user.";
						};
						discord = mkOption {
							type = types.nullOr types.str;
							default = null;
							description = "The Discord username of the user.";
						};
						default_password = mkOption {
							type = types.str;
							description = "The default password for the user.";
						};
						ssh_public_key = mkOption {
							type = types.nullOr types.str;
							default = null;
							description = "The SSH public key for the user.";
						};
						uuid = mkOption {
							type = types.str;
							description = "The UUID of the user.";
						};
					};
				});
				description = ''
					List of users to create VMs for.
				'';
			};

			usersInfo = mkOption {
				readOnly = true;
				type = types.listOf (types.submodule {
					options = {
						id = mkOption {
							type = types.str;
							description = "The username of the user.";
						};
						ip = mkOption {
							type = types.str;
							description = "The IP address of the user's VM.";
						};
						sanitized_id = mkOption {
							type = types.str;
							description = "The username of the user, sanitized for use in the URL.";
						};
					};
				});
				description = ''
					Public information about the users.
				'';
			};
		};
	};

	# TODO: tainted: high-privileges

	config = mkIf self.enable ({
		acm.user-vms.usersInfo = imap0 (i: user: {
			id = user.id;
			ip = ips.ipFromOffset i;
			sanitized_id = toLower (replaceStrings ["."] ["_"] user.id);
		}) self.users;

		systemd.services.nixvirt-diskprep = {
			serviceConfig.Type = "oneshot";
			description = "Prepare VM disk images for NixVirt";
			wantedBy = [ "multi-user.target" ];
			requires = [ "libvirtd.service" ];
			after = [ "libvirtd.service" ];
			path = with pkgs; [
				qemu
				e2fsprogs
			];
			script = ''
				set -euo pipefail

				export POOL_NAME="acm-vm-pool"
				export POOL_DIRECTORY=${self.poolDirectory}
				export VOLUME_SIZE=${volumeSize}

				log() { echo "$@" >&2; }

				# Ensure the volume is created with the correct permissions.
				umask 077

				# Ensure the pool directory exists.
				mkdir -p "$POOL_DIRECTORY"

				for uuid in ${concatStringsSep " " (map (user: user.uuid) activeUsers)}; do
					volume="$uuid.img"
					volumePath="$POOL_DIRECTORY/$volume"
					echo "Creating $volumePath..."

					if [[ -f "$volumePath" ]]; then
						log "  volume already exists."
					else
						log "  cloning volume from image ${ubuntu.image}..."
						cp --no-preserve=mode,ownership ${mkRawImage ubuntu.image} "$volumePath"

						# Disable copy-on-write for performance.
						chattr +C "$volumePath" 2> /dev/null || {
							log "  couldn't disable copy-on-write, maybe the filesystem doesn't support it?"
						}

						log "  resizing volume to $VOLUME_SIZE..."
						qemu-img resize -f raw "$volumePath" "$VOLUME_SIZE"

						log "  done!"
					fi
				done

				for uuid in ${concatStringsSep " " (map (user: user.uuid) deletedUsers)}; do
					volume="$uuid.img"
					volumePath="$POOL_DIRECTORY/$volume"
					echo "Deleting $volumePath..."

					if [[ -f "$volumePath" ]]; then
						log "  volume exists, deleting..."
						rm "$volumePath"
					fi
				done
			'';
		};

		# Force NixVirt to run after the disk preparation service.
		systemd.services.nixvirt.unitConfig = rec {
			Requires = mkForce [ "libvirtd.service" "nixvirt-diskprep.service" ];
			After = mkForce Requires;
		};

		virtualisation.libvirt.enable = true;

		virtualisation.libvirt.connections.${self.virtConnection} = {
			networks = [
				{
					active = true;
					definition = virtlib.network.writeXML {
						uuid = "b3ce2af6-af93-4b4f-b0d6-576b975e84b6";
						name = "acm-lan";
						forward = {
							mode = "nat";
							nat = {
								ipv6 = false;
								# address = {
								# 	start = ips.start.ip;
								# 	end = ips.end.ip;
								# };
								# port = {};
							};
						};
						bridge = { name = "virbr0"; };
						ipv6 = false;
						ip = {
							# subnet: 192.168.170.0/21
							# this holds about 2045 addresses (https://www.colocationamerica.com/ip-calculator)
							address = "192.168.168.1";
							netmask = "255.255.248.0";
							# dhcp.range = {
							# 	start = ips.start.ip;
							# 	end = ips.end.ip;
							# };
						};
					};
				}
			];

			domains = imap0 (i: user: {
				active = true;
				definition = virtlib.domain.writeXML (let
					base = virtlib.domain.templates.linux {
						name = "acm-vm-${user.id}";
						uuid = user.uuid;
						storage_vol = {
							# Replaced by final.devices.disk[0].
						};
						virtio_drive = true;
						virtio_video = false;
					};

					final = base // {
						type = "kvm";

						os = {
							type = "hvm";
							arch = "x86_64";
							machine = "q35";
							smbios = {
								mode = "sysinfo";
							};
							# Set each devices.disk[]'s boot order instead.
							# boot = [];
						};

						# Allow 512BM total to the VM, but only allocate 128MB initially.
						# See https://pmhahn.github.io/virtio-balloon/.
						memory = { count = 512; unit = "MiB"; };
						currentMemory = { count = 256; unit = "MiB"; };

						sysinfo = {
							type = "smbios";
							system.serial = "ds=nocloud";
						};

						vcpu = {
							placement = "static";
							count = 1;
						};

						cputune = {
							vcpupin =
								if self.cpuPinning == null
								then [ ]
								else [
									# Limit the VM to the last 4 cores.This prevents the VM from
									# overloading the host.
									{
										vcpu = 0;
										cpuset = concatStringsSep "," (map (toString) self.cpuPinning);
									}
								];
						};

						devices = base.devices // {
							emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";
							disk = with lib; [
								{
									type = "file";
									device = "disk";
									driver = {
										name = "qemu";
										type = "raw";
										cache = "writeback";
										discard = "unmap";
									};
									source.file = "${self.poolDirectory}/${user.uuid}.img";
									target = {
										dev = "vda";
										bus = "virtio";
									};
								}
								{
									type = "file";
									device = "disk";
									driver = {
										name = "qemu";
										type = "raw";
									};
									source.file = "${lib.mkCloudInitImage {
										inherit user;
										network-config = {
											version = 2;
											ethernets.enp1s0 = {
												addresses = [ "${ips.ipFromOffset i}/21" ];
												gateway4 = "192.168.168.1";
												dhcp4 = false;
												dhcp6 = false;
												nameservers.addresses = [ "1.1.1.1" "8.8.8.8" ];
											};
										};
									}}";
									target = {
										dev = "vdb";
										bus = "virtio";
									};
									readonly = true;
								}
							];
							memballoon = {
								model = "virtio-non-transitional";
								autodeflate = true;
								freePageReporting = true;
							};
							interface = {
								type = "network";
								model.type = "virtio";
								source.network = "acm-lan";
								# source.bridge = "virbr0";
							};
							serial = {
								type = "pty";
								target = {
									port = 0;
								};
							};
							console = {
								type = "pty";
								target = {
									type = "serial";
									port = 0;
								};
							};
						};
					};
				in
					final);
			}) self.users;
		};
	});
}
