# Cross-project release governance

## Compatibility table

Garden supports only combinations explicitly listed below. A row is supported
only after all listed revisions are published, every relevant Garden command
passes, and its component entries are `release_qualified = true` in
[`../ecosystem.toml`](../ecosystem.toml).

| Baseline | Odin | odin-rdf | odin-reasoner | odin-sparql | Garden gate | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `rdfs-sparql-first-closure` | `dev-2026-07:819fdc7a8` | `acb3a190` (after `v0.31.0`) | `a46a693` (unreleased) | `00acabd` (after `v0.1.0`) | `verify-rdfs-sparql.sh` | Development evidence; not supported |

There is currently no release-qualified compatibility row. A development row
may guide implementation work, but must not be presented as a public
compatibility guarantee or graph-extraction success.

The current local shared-path verification evidence is recorded in
[release readiness — 2026-07-24](release-readiness-2026-07-24.md).

## Release checklist

Before adding or changing a supported row:

- [ ] Each component revision is a published, immutable release and its source
  checkout is clean.
- [ ] `ecosystem.toml` records the exact compiler and component commit IDs,
  release labels, and `release_qualified = true` values.
- [ ] All declared Garden gates pass against those exact revisions, without
  following a branch head.
- [ ] The fixture review checklist is complete for any added or changed
  semantic fixture.
- [ ] Affected owners have reviewed any RDF term, blank-node, ownership,
  Dataset-view, snapshot, provenance, limit, or error change.
- [ ] An ADR exists for a cross-project semantic decision or an explicit note
  says why no decision changed.
- [ ] Release notes name the replaced compatibility row, migration behavior,
  and any known exclusions.

If any item fails, retain the prior row and record the candidate only as a
development baseline.
