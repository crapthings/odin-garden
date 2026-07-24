# First RDFS-to-SPARQL integration boundary record

This record applies only to the `rdfs-sparql-first-closure` development
snapshot declared in [`../ecosystem.toml`](../ecosystem.toml). It is evidence
for a later graph-contract decision, not a published cross-project API.

## Data and ownership boundary

1. `odin-rdf:rdf/turtle.parse` supplies transient triples to
   `reasoner/import.triple_sink`.
2. The reasoner store owns and interns those values during insertion.
3. RDFS Core materialization creates a bounded closure in that owned store and
   records first-support provenance for each newly inferred fact.
4. `sparql_adapter.init` copies the completed closure into an owned immutable
   default-graph snapshot.
5. The Garden test destroys both the RDFS profile and source store before
   SELECT, ASK, and CONSTRUCT execute. Terms supplied by its Dataset view remain
   borrowed from the snapshot and are valid only until `Snapshot.destroy`.

## Identity and graph scope

The first closure fixture uses only IRIs. The separate
[`blank-node-boundary` fixture](../fixtures/rdfs-core/blank-node-boundary/)
now proves that one Turtle document's repeated blank-node spelling remains one
non-zero-scoped blank node through reasoner ownership and a destroyed-source
snapshot. It still makes **no** claim about blank-node identity across parser
calls or source documents.

The adapter exposes only a default graph. `Named` and `Any_Named` scans return
`dataset.Invalid_View`; they are not reinterpreted as default-graph queries.

## Limits and errors exercised

The fixture creates 14 closure facts. It proves that `max_quads = 13` returns
`sparql_adapter.Quad_Limit` and leaves no partial snapshot, while
`max_quads = 14` succeeds. A scan sink that returns `false` stops successfully
and does not become an adapter error.

The successful path records parser, store, materializer, snapshot, and query
errors as their respective `None` values. It does not exercise parser failure,
reasoner materialization limits, allocation failure, or non-default graph
ingestion; those require additional, separately scoped fixtures.
