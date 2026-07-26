# CLI release readiness — 2026-07-26

## Candidate

The `odin-cli-validate-person-record` application baseline records the
following immutable published inputs:

| Component | Release | Commit |
| --- | --- | --- |
| Odin | `dev-2026-07-nightly:ab0131c` | official `dev-2026-07` release artifact |
| odin-rdf | `v0.33.0` | `eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4` |
| odin-shacl | `v0.1.0` | `4ee8249b84380e4ef1d888bd94f8cd24d6e7b985` |
| odin-cli | `v0.1.0` | `63c639e8cdc2a691377f36085631cb4bf4664b02` |

## Evidence required

- The fixed Garden command uses only the two authored local Turtle graphs and
  four explicit resource limits.
- The command must produce the complete deterministic JSON response committed
  in the CLI fixture, exit with status 1, and produce no diagnostics for the
  completed non-conforming validation.
- The verifier confirms both each exact commit and the corresponding
  annotated release tag before compiling.
- `odin-cli v0.1.0` has successful quality/AddressSanitizer and
  Linux/macOS/Windows source CI for its tagged release commit:
  [run 30182111169](https://github.com/crapthings/odin-cli/actions/runs/30182111169).

The `cli-validate` job in `Release-qualified integration` is the
authoritative remote application gate. It must run successfully on the Garden
candidate and again after merge on `main` before this baseline is treated as
release-qualified evidence.
