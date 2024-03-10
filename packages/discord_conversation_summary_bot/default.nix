{ pkgs, sources, pkgutil, fetchFromGitHub, buildGo121Module, lib }:
 
buildGo121Module rec {
  pname = "discord_conversation_summary_bot";
  version = pkgutil.version src;
  src = sources.discord_conversation_summary_bot;
  vendorHash = "sha256-c+VaWf9AQW/gtgAdaw0UtYm+k+zAklfDcz20zFMmalI=";
}
