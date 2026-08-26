{
  lib,
  genDispatch,
  ...
}:
let
  inherit (genDispatch) mkRule fromFunction fromFunctionMatch;

  # A record of the INTENSIONAL SHAPE — the four fields `fromFunction`'s guard reads
  # (`isAttrs` + `name`/`__functor`/`closure`). It is deliberately NOT gen-algebra's
  # constructor, which is an ENCODER — `mkIntensional : hashIdentity -> registry -> ctor
  # -> args` — and whose values are therefore always MINTED, under a digest DERIVED from
  # the registry coordinate.
  #
  # ★ THE CELLS BELOW CHOOSE THE REGIME AND THE DIGEST, AND AN ENCODER-BUILT VALUE CANNOT
  # LET THEM. The unmigrated arm is defined by the ABSENCE of `__mint`, which no
  # constructor call can produce; the unmintable arm is a refusal a producer stamps; and
  # `test-name-cannot-forge-a-minted-handle` hand-picks `its:aaaa` so that a second
  # value's NAME can be string-equal to it, which a derived digest forecloses by
  # construction. Building these by constructing a value and overriding its `__mint`
  # would assert about a value the constructor cannot emit while reading as though it
  # could — so the shape is built directly instead.
  #
  # What would RETIRE these records is the migration that turns a rule's distinguishing
  # content from a caller-supplied lambda into a first-order term the substrate interprets:
  # once that lands the encoder can build them, and the regime stops being a cell's choice.
  intensionalLike = name: closure: fn: {
    inherit name closure fn;
    __functor = self: self.fn;
  };
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
    #
    # Every projection but `.condition` is forced here, via the same attrset-comparison
    # idiom `test-mkrule-defaults` uses (nix-unit's equality check forces each listed
    # field). `.condition` stays unforced BY DESIGN: on an intensional record it aborts
    # uncatchably — not even `builtins.tryEval` observes it, see the `fromFunction` trap
    # in AGENTS.md — so forcing it here would crash this cell rather than pin a value.
    # That gap is a distinct, disjoint defect (README claims the capability; forcing it
    # implements nothing this cell's forcing set can widen into).
    test-from-function-intensional = {
      expr =
        let
          fn = intensionalLike "host-guards" { } ({ host, ... }: [ ]);
          r = fromFunction fn;
        in
        {
          identity = r.identity;
          nac = r.nac;
          priority = r.priority;
          overrides = r.overrides;
          group = r.group;
          produces = r.produces;
          hasProduce = builtins.isFunction r.produce;
        };
      expected = {
        identity = "u:host-guards";
        nac = null;
        priority = 0;
        overrides = [ ];
        group = null;
        produces = null;
        hasProduce = true;
      };
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
          minted = (intensionalLike "counter" { } ({ host, ... }: [ ])) // {
            __mint.minted = digest;
          };
          forger = intensionalLike digest { } ({ host, ... }: [ ]);
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
          base = intensionalLike "host-guards" { } ({ host, ... }: [ ]);
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
