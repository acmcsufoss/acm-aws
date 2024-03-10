{ buildPoetryPackage, git, runCommandLocal, sources }:

buildPoetryPackage {
	pname = "crying-counter";
	module = "crying_counter.main";
	src = sources.crying-counter;
}
