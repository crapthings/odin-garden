# ADR 0004: Keep Ism Library graph-navigation relationships curator-owned

- Status: Accepted
- Date: 2026-07-26

## Context

A local evaluation of the user-owned public `crapthings/ism-library` content
modules at commit `57b0a8fc242c13e57e886a8edc68a9a509270048` projected 113
entries and 628 sections to an application-owned RDF view. Structural
requirements conformed. Under the proposed graph-navigation policy, 25 entries
had no outgoing curated `related` IRI, producing 25 deterministic bounded
SHACL `minCount` results.

The source repository has an unresolved public-license declaration discrepancy:
its README names MIT, package metadata declares ISC, and no `LICENSE` file or
repository license metadata was present at review. Raw source and generated
artifacts therefore remain local and are not Garden fixtures.

## Decision

Treat an outgoing curated related link as an admission condition only for a
graph-navigation product path. It is not an intrinsic validity condition of an
idea or content entry.

The current bounded SHACL profile is sufficient. Relationships remain a
curator-owned assertion: Garden and Odin will neither infer nor generate them.
For every entry without one, the content owner must either add a curated link,
mark the entry standalone/exempt under an explicit product rule, or provide a
non-graph UI fallback.

## Consequences

- This evidence does not justify a SHACL extension, query command, custom-rule
  front end, graph/store extraction, server, or network feature.
- A future local aggregate rerun can prove that the selected content policy is
  implemented without publishing raw content.
- Adding the source or derived data to Garden requires an unambiguous owner
  license decision and the normal fixture review; a public repository alone is
  not sufficient authorization.
- The validation result is actionable product feedback, not a directive to
  fabricate links or rewrite source content.
