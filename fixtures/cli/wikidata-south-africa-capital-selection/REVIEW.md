# Fixture review — Wikidata South Africa capital selection

- [x] The source asserting party and Garden’s separate application-policy role
  are explicit in `fixture.toml`.
- [x] The immutable Wikidata entity revision, retrieval date, CC0 license,
  canonical URL, and SHA-256 digest are recorded.
- [x] `source.ttl` is a semantically faithful selected source-fact excerpt; `data.ttl`
  is explicitly identified as application-owned normalization.
- [x] Wikidata entity IRIs remain distinct; the app class creates no merge,
  alias, or equivalence claim.
- [x] The bounded SHACL profile and all relevant exclusions are explicit.
- [x] The source has no asserted logical contradiction; its revision bounds
  the facts and the single-select policy bounds the application meaning.
- [x] The sole expected result follows from `sh:maxCount 1` and the three
  distinct `wdt:P36` values.
- [x] The JSON result is committed as a deterministic contract over the
  declared data and shapes graphs.
- [x] Local-file, triple, statement, result, ownership, and error boundaries
  are fixed by the CLI contract and verifier.
- [x] The verifier checks immutable releases rather than a moving branch.

The relevant application-boundary decision is
[ADR 0003](../../../docs/adr/0003-wikidata-capital-selection.md).
