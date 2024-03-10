{ stdenv, pkgutil, jre, writeTextFile }:

{
	pname,
	version ? pkgutil.version jar,
	jar,
	jre ? jre,
	meta ? {},
	...
}@args:

writeTextFile {
	name = "${pname}-${version}";
	text = "#!/bin/sh\nexec ${jre}/bin/java -jar ${jar} \"\$@\"";	
	executable = true;
	destination = "/bin/${pname}";
	meta = meta // {
		noNixUpdate = true;
		mainProgram = pname;
	};
}
