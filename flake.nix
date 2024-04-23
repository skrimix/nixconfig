{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nixd.url = "github:nix-community/nixd";
  };

  outputs = { self, nixpkgs, nixd, ... }@inputs: {
    nixosConfigurations = {
      nyx = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit self system inputs; };
        modules = [
          {
            nixpkgs.overlays = [ nixd.overlays.default ];
          }
          ./packages
          ./modules/nix-alien.nix
          ./modules/kb-switch.nix
          ./modules/lact.nix
          ./modules/corefreq.nix
          ./modules/noisetorch.nix
          ./hosts/nyx/configuration.nix
        ];
      };
      chimera = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit self system inputs; };
        modules = [
          ./packages
          ./modules/nix-alien.nix
          #./modules/kb-switch.nix
          ./modules/corefreq.nix
          ./hosts/chimera/configuration.nix
        ];
      };
    };
  };
}
