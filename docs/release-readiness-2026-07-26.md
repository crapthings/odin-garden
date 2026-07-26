# Release readiness — 2026-07-26

## Candidate

The `rdfs-sparql-first-closure` baseline advances to the immutable published
component tuple recorded in [`../ecosystem.toml`](../ecosystem.toml):

| Component | Release | Commit |
| --- | --- | --- |
| Odin | `dev-2026-07-nightly:ab0131c` | official `dev-2026-07` release artifact |
| odin-rdf | `v0.32.1` | `d07162c20355f40cd05f031798b808a54c06fb25` |
| odin-reasoner | `v0.6.0` | `476fe5917181776368b21f26622e0f79d7f22a4f` |
| odin-sparql | `v0.2.0` | `d8503a652539497f2f6622cee04c899ef3bfeb0f` |
| odin-graph | `v0.1.0` | `8c349129a75551335bb10685ead4709951155406` |

## Evidence

- The official macOS ARM `dev-2026-07` artifact reports
  `dev-2026-07-nightly:ab0131c`.
- The Garden RDFS-to-SPARQL integration package passed all 13 tests against
  the exact candidate checkouts and compiler.
- The `odin-rdf v0.32.1`, `odin-reasoner v0.6.0`, and
  `odin-sparql v0.2.0` release commits each have a successful GitHub Actions
  CI run. `odin-graph v0.1.0` passed its own three-test kernel package under
  the same exact compiler.

The `Release-qualified integration` workflow remains the authoritative
remote gate for accepting this tuple. It verifies each tag resolves to the
declared commit before executing the integration fixture.
