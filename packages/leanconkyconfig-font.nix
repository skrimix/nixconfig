{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "leanconkyconfig-font";
  version = "1";

  fontFile = fetchurl {
    url = "https://github.com/jxai/lean-conky-config/raw/v0.8.0/font/lean-conky-config.otf";
    sha256 = "sha256-+z/LV/13LTLj+Fh485SMEeLNkxm4FA7eJMWlNk2QL6A=";
  };

  sourceRoot = ".";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/usr/share/fonts/OTF
    cp ${fontFile} $out/usr/share/fonts/OTF/lean-conky-config.otf
  '';

  meta = {
    description = "LeanConkyConfig font";
    homepage = "https://github.com/jxai/lean-conky-config/";
    license = lib.licenses.ofl;
  };
}
