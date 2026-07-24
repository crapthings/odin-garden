# Semantic fixture review checklist

Reviewers must answer each item before a fixture enters a Garden gate.

- [ ] Is the asserting party or authored-fixture status explicit?
- [ ] Is the source version or retrieval date recorded, with a compatible
  license and local evidence path or digest?
- [ ] Are source evidence and normalized asserted RDF clearly separated?
- [ ] Are every IRI, blank-node scope assumption, alias, and entity merge
  justified? Are unproven identity claims absent?
- [ ] Does the fixture state its semantic profile, rule surface, and explicit
  exclusions?
- [ ] Are contradiction status and validity period stated, including why either
  is not applicable?
- [ ] Does each inferred conclusion have an expected derivation or rule-based
  explanation?
- [ ] Do expected SELECT, ASK, CONSTRUCT, and failure results use one declared
  immutable snapshot where applicable?
- [ ] Are ownership, resource-limit, graph-scope, and error expectations
  explicit?
- [ ] Does the verification command use immutable component revisions rather
  than a moving branch?

Any unanswered item blocks fixture admission. An exception must be captured in
an ADR and linked from the fixture metadata.
