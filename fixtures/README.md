# Garden fixture taxonomy

Fixtures are organized by semantic profile and scenario. A closure fixture and
a validation fixture have different output roles, so the bundle names make the
role explicit rather than pretending every fixture has inferred triples:

```text
fixtures/<profile>/<scenario>/
  fixture.toml                 provenance, interpretation, identity, validity, and profile
  source.ttl / data.ttl        source document or authored input evidence
  asserted.nt                  normalized asserted RDF where applicable
  inferred.nt                  expected profile-derived RDF for closure fixtures
  shapes.ttl                   authored validation shape graph for validation fixtures
  expected-report.toml         stable validation-report expectations where applicable
```

This bundle separates five roles even when a small authored fixture stores them
together:

| Role | Canonical artifact |
| --- | --- |
| Source or data input | `source.*` / `data.*` |
| Normalized claims | `asserted.nt` where the profile interprets a source document |
| Asserted RDF | `asserted.nt` or the declared data graph and its `fixture.toml` interpretation record |
| Profile output | `inferred.nt`, a query result, or `expected-report.toml` |
| Test expectations | fixture expectation fields plus `queries/<profile>/<scenario>/` when querying is in scope |

The source file is never treated as inferred truth merely because it parses.
Queries are separate so their expected result form can remain stable across
source syntaxes. Follow the [fixture policy](../docs/fixture-policy.md) and
complete the [review checklist](../docs/fixture-review-checklist.md) for every
new or materially changed fixture.
