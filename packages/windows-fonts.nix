{ lib, stdenv, fetchurl, unzip, p7zip }:

stdenv.mkDerivation rec {
  pname = "windows-fonts";
  version = "1";

  archive = fetchurl {
    url = "https://archive.org/download/windows-11-21h2-complete-font-collection/Windows11-21H2-Fonts.7z";
    sha256 = "sha256-UTiY6K4mhVuqYkWIp+t0tnHNmkGQf80tvUDZffZC+eg=";
  };

  nativeBuildInputs = [ p7zip ];

  sourceRoot = ".";

  dontUnpack = true;

  installPhase = ''
    7z x ${archive}
    cd Windows11-21H2-Fonts
    mkdir -p $out/usr/share/fonts/TTF
    mv *.ttf $out/usr/share/fonts/TTF
  '';

  meta = {
    description = "Windows 11 21H2 fonts";
    homepage = "https://learn.microsoft.com/en-us/typography/fonts/windows_11_font_list";
    license = lib.licenses.unfree;
  };
}
