{ stdenv, fetchFromGitHub, kernel, util-linux }:

stdenv.mkDerivation rec {
  pname = "corefreq";
  version = "1.97.1";

  passthru.moduleName = "corefreqk";

  src = fetchFromGitHub {
    repo = "CoreFreq";
    owner = "cyring";
    rev = "${version}";
    sha256 = "sha256-MwDbes8edNpFlEXCbhCSIqMh2GLIfyOSTFAGSeWNp+M=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" "format" ];
  buildPhase = ''
    export KERNELRELEASE="${kernel.modDirVersion}"
    export KERNELDIR="${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    make -j
  '';
  installPhase = ''
    export INSTALL_MOD_PATH="$out"
    export PREFIX="$out"
    mkdir -p "$out/bin"
    make install
    substituteInPlace corefreqd.service --replace "/bin/kill" "${util-linux}/bin/kill"
    substituteInPlace corefreqd.service --replace "corefreqd" "$out/bin/corefreqd"
    install -Dm644 corefreqd.service "$out/lib/systemd/system/corefreqd.service"
  '';
}