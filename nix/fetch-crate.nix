fetchurl: attrs:
let
  crate = builtins.match "https://crates[.]io/api/v1/crates/([^/]+)/([^/]+)/download" (
    attrs.url or ""
  );
in
fetchurl (
  attrs
  // (
    if crate == null then
      { }
    else
      {
        url = "https://static.crates.io/crates/${builtins.elemAt crate 0}/${builtins.elemAt crate 0}-${builtins.elemAt crate 1}.crate";
      }
  )
)
