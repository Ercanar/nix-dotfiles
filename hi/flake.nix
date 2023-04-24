{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # lanzaboote.url = "github:myaats/lanzaboote";
    # lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # nixos-hardware.inputs.nixpkgs.follows = "nixpkgs"; # input does not exist?
  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, nixos-hardware, ... }@attrs: {
    nixosConfigurations."kyoku-chan" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = attrs;
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
        home-manager.nixosModules.home-manager
        nix-index-database.nixosModules.nix-index
        # lanzaboote.nixosModules.lanzaboote
        nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
  };
}
