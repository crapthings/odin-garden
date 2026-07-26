# SHACL release readiness — 2026-07-26

## Candidate

The `shacl-core-person-record` baseline advances to the immutable published
component pair recorded in [`../ecosystem.toml`](../ecosystem.toml):

| Component | Release | Commit |
| --- | --- | --- |
| Odin | `dev-2026-07-nightly:ab0131c` | official `dev-2026-07` release artifact |
| odin-rdf | `v0.33.0` | `eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4` |
| odin-shacl | `v0.1.0` | `4ee8249b84380e4ef1d888bd94f8cd24d6e7b985` |

## Evidence

- The official macOS ARM `dev-2026-07` artifact reports
  `dev-2026-07-nightly:ab0131c`.
- The exact Garden command parsed the fixture's data and shapes graphs, ran
  the pinned validator, destroyed both parser-derived input graphs, and passed
  all report-field, ordering, ownership, and unsupported-shape assertions.
- `odin-shacl v0.1.0` has successful quality/AddressSanitizer and
  Linux/macOS/Windows CI for its tagged release commit.

The `shacl-core` job in `Release-qualified integration` is the authoritative
remote gate. It checks both annotated tags resolve to the declared commits and
runs the same command without following a component branch.
