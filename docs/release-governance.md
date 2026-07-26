# Cross-project release governance

## Compatibility table

Garden supports only combinations explicitly listed below. A row is supported
only after all listed revisions are published, every relevant Garden command
passes, and its component entries are `release_qualified = true` in
[`../ecosystem.toml`](../ecosystem.toml).

`verify-rdfs-sparql.sh` verifies both each pinned commit and its declared
release tag, so a matching SHA without the corresponding published tag cannot
qualify the baseline.

`verify-shacl.sh` applies the same commit-and-annotated-tag check to the
validation pair. It is a separate row because it uses RDF v0.33.0 and has no
Reasoner, SPARQL, or Graph runtime dependency.

`verify-sparql-core-v0-7.sh` applies the same check to the RDF v0.33.0 and
SPARQL v0.7.0 pair. It proves the public Memory_Dataset and custom View
boundary without a Graph checkout; it neither changes nor replaces the older
Reasoner/SPARQL/Graph closure row.

`verify-cli-validate.sh` applies the same check to RDF, SHACL, and the thin
CLI layer, then verifies an exact JSON response and a violation exit status.
It establishes an application workflow only; it is not a server, query, or
storage compatibility claim.

| Baseline | Odin | odin-rdf | Components | Garden gate | Status |
| --- | --- | --- | --- | --- | --- |
| `rdfs-sparql-first-closure` | `dev-2026-07-nightly:ab0131c` | `d07162c` (`v0.32.1`) | `476fe59` Reasoner (`v0.6.0`); `d8503a6` SPARQL (`v0.2.0`); `8c34912` Graph (`v0.1.0`, experimental) | `verify-rdfs-sparql.sh` | Release-qualified local integration path |
| `sparql-core-v0.7` | `dev-2026-07:819fdc7a8` | `eac24a8` (`v0.33.0`) | `4150774` SPARQL (`v0.7.0`); no Graph input | `verify-sparql-core-v0-7.sh` | Release-qualified core query boundary |
| `shacl-core-person-record` | `dev-2026-07-nightly:ab0131c` | `eac24a8` (`v0.33.0`) | `4ee8249` SHACL (`v0.1.0`) | `verify-shacl.sh` | Release-qualified validation path |
| `odin-cli-validate-person-record` | `dev-2026-07-nightly:ab0131c` | `eac24a8` (`v0.33.0`) | `4ee8249` SHACL (`v0.1.0`); `63c639e` CLI (`v0.1.0`) | `verify-cli-validate.sh` | Release-qualified local application path |
| `odin-cli-wikidata-south-africa-capital-selection` | `dev-2026-07-nightly:ab0131c` | `eac24a8` (`v0.33.0`) | `4ee8249` SHACL (`v0.1.0`); `63c639e` CLI (`v0.1.0`) | `verify-cli-wikidata-capital-selection.sh` | Release-qualified public-source application path |

This row is limited to the documented default-graph RDFS closure path. It
checks the copied immutable snapshot, the released borrowed indexed live View,
and the released Store-adopting immutable Snapshot. It is a compatibility
guarantee for that integration command, not graph-extraction success or a
general shared-store API guarantee.

The exact cross-project commitments for this row are in the
[release-qualified interoperability contracts](release-qualified-interop-contract.md).
They are deliberately limited to exercised behavior; a SHACL validation report
and universal rule-exchange format are not part of the RDFS-to-SPARQL row.
The separate SHACL row is defined by the
[bounded validation contract](shacl-core-validation-contract.md) and its
person-record fixture; it does not promote a shared Graph, Reasoner rule API,
or universal report serialization.
The separate CLI row is defined by the
[local CLI validation contract](cli-validate-contract.md) and its exact-output
fixture; it only composes the released parser and validator for local files.
The public-source CLI row is defined by the
[Wikidata capital-selection readiness record](release-readiness-wikidata-capital-selection-2026-07-26.md).
It validates a consumer admission policy and preserves the source’s multi-value
facts; it does not label the source data invalid or choose a primary capital.

The current release-qualified shared-path verification is
[Garden CI run 30180602169](https://github.com/crapthings/odin-garden/actions/runs/30180602169).
The current evidence record is
[release readiness — 2026-07-26](release-readiness-2026-07-26.md), and its RDF
component is backed by the published release commit's successful
[CI run 30180307959](https://github.com/crapthings/odin-rdf/actions/runs/30180307959).
The SHACL candidate evidence is recorded in
[SHACL release readiness — 2026-07-26](release-readiness-shacl-2026-07-26.md),
with `odin-shacl` source CI at
[run 30181642051](https://github.com/crapthings/odin-shacl/actions/runs/30181642051).
The CLI application evidence is recorded in
[CLI release readiness — 2026-07-26](release-readiness-cli-2026-07-26.md), with
the post-merge authoritative Garden gate at
[run 30182571701](https://github.com/crapthings/odin-garden/actions/runs/30182571701).
The public-source application evidence is recorded in
[Wikidata capital-selection readiness — 2026-07-26](release-readiness-wikidata-capital-selection-2026-07-26.md),
with the post-merge authoritative Garden gate at
[run 30183114722](https://github.com/crapthings/odin-garden/actions/runs/30183114722).

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
