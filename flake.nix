{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-alien.url = "github:thiagokokada/nix-alien";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nyx = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = { inherit self system inputs; };
      modules = [
        ./packages
        ./modules/nix-alien.nix
        ./modules/sunshine.nix
        ./modules/kb-switch.nix
        ./modules/lact.nix
        ./modules/corefreq.nix
        ./modules/noisetorch.nix
        ./hosts/nyx/configuration.nix
      ];
    };
  };
}
