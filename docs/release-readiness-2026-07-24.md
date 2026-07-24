# Release-readiness evidence — 2026-07-24

This is a local, pre-release evidence record for the fixed development snapshot
in [`../ecosystem.toml`](../ecosystem.toml). It is not a release approval and
does not create a supported compatibility row.

## Environment

- Odin compiler: `dev-2026-07:819fdc7a8`
- `odin-rdf`: `acb3a190371e8679a2a35a3d4668ec166ec24891`
- `odin-reasoner`: `a46a693f30b00360d6adcf761188cdef681959e1`
- `odin-sparql`: `00acabd46113676820a55955328b5532149fbf47`
- All three component worktrees were clean at the time of verification.

## Passing shared-path checks

| Command | Result |
| --- | --- |
| `sh ../odin-garden/scripts/verify-rdfs-sparql.sh` | 2 Garden integration tests passed |
| `odin test rdf/turtle` | 22 tests passed |
| `odin test rdf/ntriples` | 29 tests passed |
| `odin test rdf/dataset` | 5 tests passed |
| `odin test reasoner -collection:odin-rdf=../odin-rdf` | 1 package-root test passed |
| `odin test adapter/sparql -collection:odin-rdf=../odin-rdf -collection:odin-sparql=../odin-sparql` | 3 snapshot-adapter tests passed |
| `odin test sparql/engine -collection:odin-rdf=../odin-rdf` | 110 engine tests passed |

`odin test sparql/dataset` currently reports no direct tests; this is an
observation, not a successful coverage claim.

## Remaining release blockers

1. `odin-reasoner` has no published tag or release evidence.
2. `odin-rdf` is one commit after `v0.31.0`; `odin-sparql` is two commits after
   `v0.1.0`. The Garden baseline uses those untagged commits.
3. The component-specific full release checklists, sanitizer lanes, CI results,
   and retained verification output have not been completed for these exact
   revisions.
4. No release owner has selected semantic versions, created immutable tags, or
   published releases.

Release owners must complete their component checklists, publish immutable
revisions, and then update the Garden matrix and rerun its gate. Until then,
this record supports implementation decisions only.
