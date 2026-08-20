{
  lib,
  genDispatch,
  mkIntensional,
  ...
}:
let
  inherit (genDispatch) mkRule fromFunction fromFunctionMatch;
  mkI = mkIntensional;
in
{
  flake.tests.rule = {
    test-mkrule-defaults = {
      expr =
        let
          r = mkRule {
            condition = "test";
            produce = _id: _ctx: [ ];
          };
        in
        {
          inherit (r)
            condition
            nac
            priority
            overrides
            ;
          hasIdentity = r.identity == null;
          hasProduce = builtins.isFunction r.produce;
        };
      expected = {
        condition = "test";
        nac = null;
        priority = 0;
        overrides = [ ];
        hasIdentity = true;
        hasProduce = true;
      };
    };

    test-mkrule-explicit-fields = {
      expr =
        let
          r = mkRule {
            condition = "test";
            produce = _id: _ctx: [ ];
            nac = "nac-cond";
            priority = 10;
            overrides = [ "other" ];
            identity = "my-rule";
          };
        in
        {
          inherit (r)
            nac
            priority
            overrides
            identity
            ;
        };
      expected = {
        nac = "nac-cond";
        priority = 10;
        overrides = [ "other" ];
        identity = "my-rule";
      };
    };

    test-from-function-plain = {
      expr =
        let
          r = fromFunction (
            {
              host,
              user ? null,
              ...
            }:
            [ ]
          );
        in
        {
          condition = r.condition;
          hasIdentity = r.identity == null;
        };
      expected = {
        condition = {
          host = false;
          user = true;
        };
        hasIdentity = true;
      };
    };

    # The UNMIGRATED arm: this fixture carries no `__mint`, so the program-point name
    # is still all the reader has — carried under that arm's REGIME TAG, because the
    # derived handle's arms must occupy disjoint spaces.
    test-from-function-intensional = {
      expr =
        let
          fn = mkI "host-guards" { } ({ host, ... }: [ ]);
          r = fromFunction fn;
        in
        r.identity;
      expected = "u:host-guards";
    };

    # THE FORGERY THE TAG FORECLOSES. `identity` is the override handle, so an untagged
    # space lets a value merely NAMED string-equal to another's minted digest yield that
    # digest's handle — and `override` would then retarget the wrong rule while looking
    # entirely well-formed. Tagged, the two handles differ, so a rule keyed on the
    # minted handle no longer matches the forger.
    test-name-cannot-forge-a-minted-handle = {
      expr =
        let
          digest = "its:aaaa";
          minted = (mkI "counter" { } ({ host, ... }: [ ])) // {
            __mint.minted = digest;
          };
          forger = mkI digest { } ({ host, ... }: [ ]);
        in
        {
          mintedHandle = (fromFunction minted).identity;
          forgedHandle = (fromFunction forger).identity;
          collide = (fromFunction minted).identity == (fromFunction forger).identity;
          # The consumer-visible outcome: an override recorded against the minted
          # handle does not name the forger's.
          overrideMissesTheForger =
            let
              replacement = mkRule {
                condition = { };
                produce = _id: _ctx: [ ];
                identity = "replacement";
              };
              overridden = genDispatch.override (fromFunction minted) replacement;
            in
            !(builtins.elem (fromFunction forger).identity overridden.overrides);
        };
      expected = {
        mintedHandle = "m:its:aaaa";
        forgedHandle = "u:its:aaaa";
        collide = false;
        overrideMissesTheForger = true;
      };
    };

    # `identity` is the OVERRIDE HANDLE, so it mints, and it is derived by regime.
    # Only `.identity` is forced here: `fromFunction` binds `condition =
    # functionArgs fn`, and an intensional record is not a lambda, so forcing the
    # condition aborts uncatchably (see the `fromFunction` trap in AGENTS.md).
    test-from-function-identity-by-regime = {
      expr =
        let
          base = mkI "host-guards" { } ({ host, ... }: [ ]);
          minted = base // {
            __mint.minted = "its:aaaa";
          };
          unmintable = base // {
            __mint.unmintable = {
              reason = "distinguishing content is a caller-supplied lambda";
              ctor = "host-guards";
            };
          };
        in
        {
          minted = (fromFunction minted).identity;
          # The REFUSAL. A handle must be exact, and a program point is constant
          # across a constructor's instances — so a value with no mintable identity
          # gets none rather than a name standing in for one.
          unmintable = (fromFunction unmintable).identity;
          unmigrated = (fromFunction base).identity;
          nonIntensional = (fromFunction ({ host, ... }: [ ])).identity;
        };
      expected = {
        minted = "m:its:aaaa";
        unmintable = null;
        unmigrated = "u:host-guards";
        nonIntensional = null;
      };
    };

    test-from-function-match-satisfied = {
      expr = fromFunctionMatch {
        host = false;
        user = true;
      } "id" { host = { }; };
      expected = true;
    };

    test-from-function-match-unsatisfied = {
      expr = fromFunctionMatch {
        host = false;
        user = true;
      } "id" { user = { }; };
      expected = false;
    };

    test-from-function-match-all-optional = {
      expr = fromFunctionMatch {
        host = true;
        user = true;
      } "id" { };
      expected = true;
    };

    test-from-function-match-restricted = {
      expr =
        fromFunctionMatch
          {
            __restricted = true;
            original = {
              host = false;
            };
            extra = {
              env = false;
            };
          }
          "id"
          {
            host = { };
            env = "prod";
          };
      expected = true;
    };

    test-from-function-match-restricted-fails = {
      expr = fromFunctionMatch {
        __restricted = true;
        original = {
          host = false;
        };
        extra = {
          env = false;
        };
      } "id" { host = { }; };
      expected = false;
    };

    test-mkRule-group = {
      expr =
        (mkRule {
          condition = { };
          produce = _: _: [ ];
          group = "structural";
        }).group;
      expected = "structural";
    };

    test-mkRule-group-default-null = {
      expr =
        (mkRule {
          condition = { };
          produce = _: _: [ ];
        }).group;
      expected = null;
    };

    test-mkRule-produces = {
      expr =
        (mkRule {
          condition = { };
          produce = _: _: [ ];
          produces = [
            "edge"
            "drop"
          ];
        }).produces;
      expected = [
        "edge"
        "drop"
      ];
    };

    test-mkRule-produces-default-null = {
      expr =
        (mkRule {
          condition = { };
          produce = _: _: [ ];
        }).produces;
      expected = null;
    };
  };
}
