# Curated semantic fixture policy

Garden fixtures are executable evidence, not a collection of unreviewed RDF.
Each fixture bundle must be small enough to audit and must include the fields
below before it can be used by an integration gate.

## Required record

Every `fixture.toml` records:

- a stable fixture ID and version;
- the source document path, its kind, version or retrieval date, author or
  asserting party, provenance, and license;
- the chosen semantic profile and explicit exclusions;
- the normalized asserted RDF and expected inferred RDF paths;
- the expected query results and the command that verifies them;
- entity-identity assumptions, contradiction status, and any validity period.

An authored fixture must say so; it must not imply that it is a quotation from
an external authority. External sources require a stable citation, retrieval
date, applicable license, and a local source copy or content-addressed digest.

## Interpretation rules

Source documents and normalized RDF are different artifacts. A source document
is evidence; normalized asserted RDF is the interpretation selected for a
specific profile. Inferred output must identify the profile and rule surface
that licenses it. No fixture may silently add axiomatic triples, a broader
reasoning profile, a named graph, a data source, or an identity equivalence.

Expected output is a contract, not an observation. It must be reviewed when a
component upgrade changes term equality, blank-node scope, ownership,
resource-limit, Dataset-view, provenance, or error behavior.

## Admission and changes

1. Add the source and metadata before adding expected conclusions.
2. Normalize claims into asserted RDF with each interpretation decision made
   reviewable.
3. State the exact semantic profile, exclusions, limits, and expected results.
4. Add a deterministic test command that uses only the declared public
   component boundaries.
5. Complete the fixture review checklist and link any relevant ADR.

Changing source interpretation, profile, expected inference, entity identity,
or validity is a fixture-version change. Do not overwrite a previously
accepted meaning in place.
