# Cross-project semantic change policy

The following changes require coordinated review; no component may silently
ship one as an internal refactor when a public or Garden boundary can observe
it:

| Change area | Required evidence before acceptance |
| --- | --- |
| RDF term structure, equality, hashing, or lexical normalization | Affected component tests, a Garden fixture covering the observable behavior, migration notes, and an ADR if equality or identity changes. |
| Blank-node scope or ingestion identity | Cross-parser and cross-snapshot fixtures that state whether labels co-refer, plus a dedicated ADR. |
| Ownership or lifetime | A test that destroys the producer at the documented boundary and verifies consumers do not retain invalid values. |
| Dataset graph scope, scans, or snapshot behavior | SELECT/ASK/CONSTRUCT integration coverage, named-graph behavior, early-stop behavior, and an update to adapter documentation. |
| Resource limits or error codes | Boundary tests for success, rejection, and partial-state behavior; callers must have a stable migration path. |
| Provenance or assertion/inference meaning | Fixture metadata and expected derivations updated together, with an ADR for a semantic reinterpretation. |

## Required process

1. Identify every component and Garden fixture affected by the proposed change.
2. Write or update the corresponding ADR before merging a semantic change.
3. Update the fixed baseline only after relevant component and Garden gates
   pass.
4. Record migration behavior and compatibility impact in release notes.

Changes that broaden the semantic profile, introduce named graphs, equate
entities, or alter blank-node scope are never assumed backward-compatible.
