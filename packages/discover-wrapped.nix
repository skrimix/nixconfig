{ stdenv, lib, fetchFromGitHub, makeWrapper, pkgs }:
pkgs.symlinkJoin
{
  name = "discover-flatpak-backend";
  paths = [ pkgs.kdePackages.discover ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/plasma-discover --add-flags "--backends flatpak"
  '';
}
