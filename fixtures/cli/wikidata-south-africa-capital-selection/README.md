# Wikidata South Africa capital-selection fixture

This fixture is a real-data import-policy check, not an assertion that the
source contains an error. The fixed Wikidata revision for South Africa states
three direct capital values: Pretoria, Cape Town, and Bloemfontein. A
single-select application field requires exactly one capital IRI, so the
released local CLI returns a MaxCount violation.

The required downstream action is to preserve the source's three values and
make an explicit product decision: support a multi-value field, select a value
with an independently documented ranking policy, or reject the record from
the single-select workflow. The fixture deliberately does not choose a
“primary” capital.

`source.ttl` is the small semantically faithful fact excerpt from the content-addressed
Wikidata export recorded in `fixture.toml`. `data.ttl` is the
application-owned normalization: it adds one application class solely to
identify records admitted to a single-capital selector. No source `wdt:P31`
statement is reinterpreted as RDF type, and no inference is used.

The verifier parses `source.ttl` too. It has no application class and
therefore produces the separate conforming source-sanity report; the policy
violation is asserted only over `data.ttl`.
