{ prelude }:
let
  isIntensional = v: builtins.isAttrs v && v ? name && v ? __functor && v ? closure;

  # The ONE access discipline over the three identity regimes, and it is TOTAL OVER
  # THOSE THREE REGIMES — not over the two populations of the migration window, which
  # is the narrower claim it replaced and which omits the sealed regime entirely.
  # `__mint` is a TAGGED SUM, so no reader may branch on FIELD PRESENCE and then read
  # `.minted` raw: on a value that has no mintable identity `v ? __mint` holds and
  # `.minted` is absent, and that read aborts uncatchably rather than refusing.
  #
  #   minted     — an identity over a preimage total in the value's distinguishing
  #                content; consumable as a key, an endpoint or an override handle.
  #   unmintable — no identity AND no substitute. A consumer demanding one is refused.
  #   unmigrated — the migration window: no producer has stamped this value, so the
  #                shipped program-point name is still all a reader has.
  identityOf =
    v:
    if v ? __mint && v.__mint ? minted then
      { inherit (v.__mint) minted; }
    else if v ? __mint then
      { inherit (v.__mint) unmintable; }
    else
      { unmigrated = v.name; };

  # The one-character REGIME TAG a derived handle carries, and the sibling of
  # `identityOf` rather than a second reader of the tagged sum. `identity` is the
  # OVERRIDE HANDLE, so the arms must occupy DISJOINT spaces: untagged, a value merely
  # NAMED string-equal to another's minted digest yields the same handle, and `override`
  # would then retarget the wrong rule while looking entirely well-formed. Tagging the
  # arm before the payload makes that forgery inexpressible rather than unlikely — the
  # same discipline the encoder applies to every node of a preimage. The alphabet is
  # shared with the other readers of this discipline: m = minted, u = unmigrated;
  # a sealed value is refused outright and emits no handle at all.
  #
  # KNOWN RESIDUAL, and it is outside what a derived handle can close: an identity
  # passed EXPLICITLY to `mkRule` is a caller-supplied string in the same space, so a
  # caller may still write "m:…" or "chain:…" by hand. Tagging bounds what the SUBSTRATE
  # derives; it does not partition a namespace callers also write into.
  taggedHandle =
    i:
    if i ? minted then
      "m:${i.minted}"
    else if i ? unmigrated then
      "u:${i.unmigrated}"
    else
      null;

  # ★ WHY THIS LIBRARY CARRIES NO `comparisonSubject`, unlike the other readers of this
  # discipline. Those exclude `__id` from the value they compare, because `__id` is the
  # accessor a consumer reads when it DEMANDS an identity, and in the sealed regime that
  # accessor IS the named refusal — so comparing a record whole would force the refusal
  # inside the decision it exists to permit. gen-dispatch DERIVES a handle and compares
  # no reified value at all: `identity` is read as `acc.overridden ? ${r.identity}`, a
  # string key. There is nothing here to exclude the accessor from, and adding the
  # helper would assert a protection this library has no site for.

  mkRule =
    {
      condition,
      produce,
      nac ? null,
      identity ? null,
      priority ? 0,
      overrides ? [ ],
      group ? null,
      produces ? null,
    }:
    {
      inherit
        condition
        produce
        nac
        identity
        priority
        overrides
        group
        produces
        ;
    };

  fromFunction =
    fn:
    let
      args = builtins.functionArgs fn;
    in
    mkRule {
      condition = args;
      produce = _id: ctx: fn ctx;
      # `identity` is the OVERRIDE HANDLE — `dispatch` reads it as `acc.overridden ?
      # ${r.identity}` — so it MINTS, and a name-only handle is rejected wherever it
      # mints. `name` is the program point and is constant across a constructor's
      # instances, so handing it out as a handle gives every value of one constructor
      # ONE handle and overriding any of them silently replaces the wrong rule.
      #
      # An override handle must be EXACT, so the unmintable regime gets `null` — the
      # refusal — and `override` then throws "cannot override anonymous rule" by name.
      # A named refusal replacing a silent wrong-rule override is the design working,
      # and it is why this arm differs from the two decision sites: they may compare a
      # reified value, and a handle has nothing to compare against.
      #
      # Each surviving arm carries its REGIME TAG, so the digest and name arms cannot
      # collide — see `taggedHandle`.
      identity = if isIntensional fn then taggedHandle (identityOf fn) else null;
    };

  # LIMITATION: `id` is BOUND here and NEVER READ — every arm below decides purely
  # from `condition` and `ctx`. A rule dispatched through this matcher therefore
  # cannot condition on the candidate id at all: id-conditional dispatch over
  # `fromFunctionMatch` silently matches EVERY id, because there is no id-shaped
  # comparison here to fail.
  #
  # The id-AWARE matcher is `adapters.select.mkMatch`, but it is not a drop-in swap:
  # it forwards its `ctx` argument straight to `genSelect.matches`, which expects
  # gen-select's five-field accessor record — a different object from this library's
  # flat dispatch-context attrset. A consumer that needs id-aware matching builds
  # that accessor context itself (see the gen-select bridge in the adapter tier);
  # handing `mkMatch` a `fromFunction` rule's plain context is not the same shape.
  fromFunctionMatch =
    condition: id: ctx:
    if condition ? __restricted then
      fromFunctionMatch condition.original id ctx && fromFunctionMatch condition.extra id ctx
    else
      let
        required = prelude.filter (k: !condition.${k}) (builtins.attrNames condition);
      in
      prelude.all (k: ctx ? ${k}) required;
in
{
  inherit mkRule fromFunction fromFunctionMatch;
}
