{
  inputs = {
    gen.url = "github:sini/gen";
    gen-algebra.url = "github:sini/gen-algebra";
    gen-select.url = "github:sini/gen-select";
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    flake-parts.follows = "gen/flake-parts";
    flake-root.follows = "gen/flake-root";
    nix-unit.follows = "gen/nix-unit";
    treefmt-nix.follows = "gen/treefmt-nix";
    devshell.follows = "gen/devshell";
    import-tree.follows = "gen/import-tree";
  };

  outputs =
    inputs@{ gen, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      genAlgebra = inputs.gen-algebra.pure;
      deriveLib = import ../lib { inherit lib genAlgebra; };
      selectLib = import "${inputs.gen-select}/lib" { inherit lib genAlgebra; };
    in
    gen.lib.mkCi {
      inherit inputs;
      name = "gen-derive";
      testModules = ./tests;
      specialArgs = { inherit deriveLib selectLib genAlgebra; };
    };
}
