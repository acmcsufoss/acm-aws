{ pkgutil, mkPoetryApplication, writeShellScriptBin, python3 }:

{
	name ? "${pname}-${version}",
	pname,
	module,
	version ? pkgutil.version src,
	src,
	meta ? {},
	python ? python3,
	overridePoetryAttrs ? (old: {}),
}:

let
	poetryApplication = (mkPoetryApplication {
		inherit src python;
		pyproject = "${src}/pyproject.toml";
		poetrylock = "${src}/poetry.lock";
		preferWheels = true;
	}).dependencyEnv.overrideAttrs overridePoetryAttrs;

	script = writeShellScriptBin pname ''
		exec ${poetryApplication}/bin/python3 -m ${module} "$@"
	'';
in

script.overrideAttrs (_: {
	meta = meta // {
		mainProgram = pname;
	};
})
