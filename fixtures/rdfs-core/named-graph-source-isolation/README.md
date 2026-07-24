# Named source-graph isolation fixture

This synthetic fixture models a common multi-source knowledge workflow:
the default graph records which source graphs are published, while each source
contributes its own named-graph facts. The resource `ada` deliberately occurs
in both source graphs with different values, so an implementation cannot pass
by flattening the graphs together.

It is a provisional test consumer, not a claim that a production application
has selected this data model. It defines the narrow semantics required for the
accompanying tests:

- `GRAPH <source-a>` selects only source A facts;
- `GRAPH ?source` visits source A and source B, never default-graph metadata;
- a normal default-graph pattern cannot see either source graph's facts.
