# Release-readiness evidence — 2026-07-24

This began as a local, pre-release evidence record for the fixed development
snapshot in [`../ecosystem.toml`](../ecosystem.toml). The recorded components
were subsequently released and the same Garden gate was rerun against their
release commits; see the resolution below.

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

## Resolution

The release blockers above were resolved on 2026-07-24:

- `odin-rdf v0.31.1` at `daa350521a8ad9f79012bb1fefa96cf00938f3f1`;
- `odin-reasoner v0.1.0` at `3ac9267f8651eb9add25b13ac8e12b952e63a959`; and
- `odin-sparql v0.1.1` at `fcba9b6ffd542f246bf026d69dbd045624315c8d`.

The Garden matrix now records those releases and its local integration gate
passes. This resolution does not satisfy the independent graph-extraction
conditions for shared mutable semantics or a durable-store requirement.
