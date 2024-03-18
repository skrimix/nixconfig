{
  nixpkgs.overlays = [
    (final: prev: {
      nekoray = prev.libsForQt5.callPackage ./nekoray.nix { };
      apple-fonts = prev.callPackage ./apple-fonts.nix { };
      windows-fonts = prev.callPackage ./windows-fonts.nix { };
      leanconkyconfig-font = prev.callPackage ./leanconkyconfig-font.nix { };
    })
  ];
}
