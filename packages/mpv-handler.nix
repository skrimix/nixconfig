{ stdenv, lib, fetchFromGitHub, rustPlatform, mpv, yt-dlp ? null }:

rustPlatform.buildRustPackage rec {
  pname = "mpv-handler";
  version = "0.3.5";

  src = fetchFromGitHub {
    owner = "akiirui";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-HXfFjuWEE9qmOQEi2NtGb2YOpj9BzMep8QHbgeVm5cQ=";
  };

  buildInputs = [ mpv yt-dlp ];

  cargoHash = "sha256-EPWlLsCdvIpll4jCVmj61RxO/diZEd/2k2o0wrYO2Pk=";

  installPhase = ''
    runHook preInstall
    install -Dm644 share/linux/mpv-handler.desktop $out/share/applications/mpv-handler.desktop
    runHook postInstall
  '';

  meta = {
    description = "A protocol handler for mpv. Use mpv and yt-dlp to play video and music from the websites.";
    homepage = "https://github.com/akiirui/mpv-handler/";
    license = lib.licenses.mit;
    maintainers = []; 
    platforms = lib.platforms.linux;
  };
}
