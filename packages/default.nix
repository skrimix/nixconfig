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

      # TODO: remove once KDE 6.0.5 is released
      kdePackages = (prev.kdePackages.overrideScope (self: super: {
        kwin = super.kwin.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [
            # scene/workspacescene: don't check direct scanout candidates
            (prev.fetchpatch {
              name = "kwin-direct-scanout-candidates.patch";
              url = "https://invent.kde.org/plasma/kwin/-/merge_requests/5626.patch";
              sha256 = "sha256-Z92vqem3T515Dis5ijmS9dYAIhGDhPa7Zg+gS9qAW9I=";
            })
          ];
        });
      }));
    })
  ];
}
