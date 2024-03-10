{ pkgs, sources, pkgutil, fetchFromGitHub, buildGo119Module, lib }:
 
buildGo119Module rec {
  pname = "discord-ical-srv";
  version = pkgutil.version src;
 
  src = sources.discord-ical-srv;
  subPackages = [ "." ];
  vendorSha256 = "sha256-/xXU24sk5IRWfM/Bh9YYGB3mTDdhdATVlPzNxTKe2K0=";
}
