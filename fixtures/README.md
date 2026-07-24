# Garden fixture taxonomy

Fixtures are organized by semantic profile and scenario:

```text
fixtures/<profile>/<scenario>/
  source.ttl       source document or authored source evidence
  fixture.toml     provenance, interpretation, identity, validity, and profile
  asserted.nt      normalized asserted RDF
  inferred.nt      expected profile-derived RDF
```

This bundle separates five roles even when a small authored fixture stores them
together:

| Role | Canonical artifact |
| --- | --- |
| Source document | `source.*` |
| Normalized claims | `asserted.nt` |
| Asserted RDF | `asserted.nt` and its `fixture.toml` interpretation record |
| Inferred output | `inferred.nt` |
| Test expectations | fixture expectation fields plus `queries/<profile>/<scenario>/` |

The source file is never treated as inferred truth merely because it parses.
Queries are separate so their expected result form can remain stable across
source syntaxes. Follow the [fixture policy](../docs/fixture-policy.md) and
complete the [review checklist](../docs/fixture-review-checklist.md) for every
new or materially changed fixture.
