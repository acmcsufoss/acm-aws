{ pkgs }:

{
	version = src:
		if (src ? version && src.version != "")
			then src.version
			else builtins.substring 0 7 src.rev;
}
