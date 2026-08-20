{
  inputs = {
    gen-harness.url = "github:sini/gen-harness";
    gen-prelude.url = "github:sini/gen-prelude";
    gen-select.url = "github:sini/gen-select";
    # nixpkgs is the CI runner's dependency (test harness, treefmt). gen-dispatch itself
    # (../lib) takes only gen-prelude — see the purity remediation.
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
  };

  outputs =
    inputs@{
      gen-harness,
      gen-prelude,
      gen-select,
      ...
    }:
    let
      prelude = import "${gen-prelude}/lib";
      genDispatch = import ../lib { inherit prelude; };
      genSelect = import "${gen-select}/lib";
    in
    gen-harness.lib.mkCi {
      inherit inputs;
      name = "gen-dispatch";
      testModules = ./tests;
      specialArgs = { inherit genDispatch genSelect; };
    };
}
