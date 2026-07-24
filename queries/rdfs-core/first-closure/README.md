# Query expectations

All three queries run against one immutable closure snapshot after the reasoner
store and RDFS profile have been destroyed.

| Query | Expected result |
| --- | --- |
| `select-agent.rq` | Two rows: `person = https://example.org/garden/ada`, then `https://example.org/garden/bea` |
| `ask-bea-person.rq` | `true` |
| `construct-related.rq` | One triple: `ada relatedTo bea` |
