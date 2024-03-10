{ runCommand, pkgutil, deno, makeWrapper, writeShellScript, jq, tree }:

{
	name ? "${pname}-${version}",
	pname,
	version ? pkgutil.version src,
	src,
	lockfile ? "",
	entrypoint,
	outputHash,
	buildInputs ? [],
	...
}@args:

let # https://deno.land/manual@v1.32.4/basics/modules/integrity_checking
	denoDir = runCommand "${name}-deno-cache" {
		inherit src entrypoint lockfile outputHash;
		outputHashMode = "recursive";
		nativeBuildInputs = [ deno jq ];
	} ''
		mkdir .deno
		export DENO_DIR=.deno

		mkdir $out

		{
			if [[ "$lockfile" ]]; then
				deno cache --reload --lock=$src/$lockfile "$src/$entrypoint"
				cp $src/$lockfile $out/deno.lock
			else
				deno cache --reload --lock=deno.lock --lock-write "$src/$entrypoint" 
				mv deno.lock $out/deno.lock
			fi
		} |& cat # deno is dumb

		cp -r .deno/deps $out
		for metadata in $(find $out/deps -name "*.metadata.json"); do
			# deno is dumb part 2
			jq '{ url, headers: {} }' "$metadata" > "$metadata.tmp"
			mv "$metadata.tmp" "$metadata"
		done
	'';
in

runCommand name {
	inherit pname src entrypoint lockfile buildInputs;
	nativeBuildInputs = [ makeWrapper deno denoDir ];
	passthru = {
		inherit outputHash;
		outputHashMode = "recursive";
	};
} ''
	mkdir .deno
	cp -r ${denoDir}/deps .deno
	export DENO_DIR=.deno

	deno compile \
		--lock=${denoDir}/deno.lock \
		--output main.out -A "$src/$entrypoint"

	install -Dm755 main.out $out/bin/${pname}
	wrapProgram $out/bin/${pname} \
		--set-default DENO_DIR '/tmp/.deno'
''
