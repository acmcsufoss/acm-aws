{ stdenv, pkgutil, jre, makeWrapper, gradle_7, writeShellScript }:

{
	pname,
	src,
	version ? pkgutil.version src,
	nativeBuildInputs ? [],
	outputHash,
	jre ? jre,
	gradle ? gradle_7,
	...
}@args:

let run = writeShellScript "build-${pname}" ''
		# Hack to self-reference the derivation.
		src="''${BASH_SOURCE[0]}"
		dir="''${src%/*}"
		exec ${jre}/bin/java -jar "$dir/../share/java/"*.jar
	'';
in

stdenv.mkDerivation (args // {
	inherit pname src version outputHash;
	outputHashMode = "recursive";

	nativeBuildInputs = nativeBuildInputs ++ [
		makeWrapper
		gradle
	];

	buildPhase = ''
		export GRADLE_USER_HOME=$(mktemp -d)
		gradle --no-daemon build
	'';

	installPhase = ''
		mkdir -p $out/share/java
		cp *.jar $out/share/java/

		mkdir -p $out/bin
		cp ${run} $out/bin/${pname}
	'';
})
