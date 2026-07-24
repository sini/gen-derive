{ prelude }:
let
  mkActions =
    groups:
    let
      tagToGroup = prelude.foldl' (
        acc: groupName: prelude.foldl' (acc': tag: acc' // { ${tag} = groupName; }) acc groups.${groupName}
      ) { } (builtins.attrNames groups);

      constructors = prelude.foldl' (
        acc: groupName:
        prelude.foldl' (
          acc': tag: acc' // { ${tag} = args: { __action = tag; } // args; }
        ) acc groups.${groupName}
      ) { } (builtins.attrNames groups);

      # Classify a bare KIND/tag to its group (no action value). This is the `classifyKind` a rule's
      # DECLARED produced-kind family is discharged against (`declared.nix`'s `deriveGroup`), the
      # static counterpart to `classify` (which reads `action.__action` off a fired action).
      groupOfKind =
        tag:
        if tagToGroup ? ${tag} then
          tagToGroup.${tag}
        else
          throw "gen-dispatch: unknown action tag '${tag}'";

      classify = action: groupOfKind action.__action;
    in
    constructors // { inherit classify groupOfKind; };
in
{
  inherit mkActions;
}
