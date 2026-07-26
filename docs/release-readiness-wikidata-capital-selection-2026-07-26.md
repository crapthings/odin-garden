# Wikidata capital-selection application readiness — 2026-07-26

## Candidate

The `wikidata-south-africa-capital-selection` fixture is the first
real-data application candidate over the existing released CLI tuple:

| Component | Release | Commit |
| --- | --- | --- |
| Odin | `dev-2026-07-nightly:ab0131c` | official `dev-2026-07` release artifact |
| odin-rdf | `v0.33.0` | `eac24a8d3251d03cb3fe700e6ffbda0ad1a47ee4` |
| odin-shacl | `v0.1.0` | `4ee8249b84380e4ef1d888bd94f8cd24d6e7b985` |
| odin-cli | `v0.1.0` | `63c639e8cdc2a691377f36085631cb4bf4664b02` |

## Source and decision

The fixture records Wikidata entity Q258 revision 2522617312, its canonical
RDF export URL, CC0 license, retrieval date, and SHA-256 digest. It selects
the direct P31/P36 facts into a small local source excerpt, then adds only an
application-owned class to define single-capital import admission.

The source’s three capital values are preserved. The one-result MaxCount report
indicates a mismatch with a single-select consumer policy, not a defect in
Wikidata. [ADR 0003](adr/0003-wikidata-capital-selection.md) records the
required handling.

## Evidence required

The dedicated CLI verifier must check all three immutable release tags, compile
without network access, compare the full JSON response, require exit status 1,
and require no diagnostics on the completed validation path. The `cli-validate`
Garden job must succeed on the PR and again after merge on `main` before this
candidate is treated as release-qualified application evidence.
