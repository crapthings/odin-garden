# ADR 0003: Preserve multi-valued capitals at a single-select import boundary

- Status: Accepted
- Date: 2026-07-26

## Context

The first real-data application fixture uses the Wikidata RDF export for South
Africa (Q258), pinned to entity revision 2522617312. Its direct truthy
properties contain three `wdt:P36` capital values: Q3926, Q37701, and Q5465.
The source is CC0 and its full export is identified by the immutable URL and
SHA-256 in the fixture metadata.

One proposed consumer has a single-select capital field. It needs an explicit
admission policy, but the three source values are not evidence that the source
is logically inconsistent or malformed.

## Decision

Garden normalizes the selected source facts into an application-owned record
class only for the single-select workflow. A bounded SHACL property shape
requires exactly one IRI-valued `wdt:P36` value. The resulting MaxCount
violation means “not admitted to this single-value workflow”, not “Wikidata
has bad data”.

The consumer must preserve all three source values and choose one of these
explicit product actions:

1. support multiple capital values;
2. use an independently documented ranking/selection policy; or
3. reject the record from a single-select path.

Garden and `odin-cli` do not select, delete, merge, infer, or rank a capital.

## Consequences

- The real-data fixture produces a deterministic one-result JSON report with
  exit status 1 through the released local CLI.
- `wdt:P31` remains a source property in `source.ttl`; it is not silently
  converted to RDF type. The application class in `data.ttl` is explicitly
  authored admission metadata.
- Upgrading the Wikidata source requires a new fixture version with a new
  entity revision, content digest, review, and expected result. CI never
  refetches Wikidata.
- This decision neither broadens the SHACL profile nor creates a general
  country/capital ontology, query service, shared store, or network feature.
