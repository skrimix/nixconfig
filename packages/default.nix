{
  nixpkgs.overlays = [
    (final: prev: {
      nekoray = prev.libsForQt5.callPackage ./nekoray.nix { };
      apple-fonts = prev.callPackage ./apple-fonts.nix { };
      windows-fonts = prev.callPackage ./windows-fonts.nix { };
      leanconkyconfig-font = prev.callPackage ./leanconkyconfig-font.nix { };
      mpv-handler = prev.callPackage ./mpv-handler.nix { };
      discover-wrapped = prev.callPackage ./discover-wrapped.nix { };

      linuxPackagesOverride = linuxPackages:
        linuxPackages.extend (lfinal: lprev: {
          corefreq = lfinal.callPackage ./corefreq.nix { };
        });
    })
  ];
}
