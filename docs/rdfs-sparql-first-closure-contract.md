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

The release-qualified `odin-reasoner v0.2.0` baseline adds a distinct live
path: `sparql_adapter.indexed_view` borrows the source Store's owned terms and
reuses its indexed matching operation without materializing a second dataset.
The Garden equivalence test executes SELECT, ASK, and CONSTRUCT through that
View and the immutable `Snapshot` over the same RDFS closure. The live View is
valid only while its source Store stays alive and unmodified; it is not an
alternative immutable snapshot.

## Identity and graph scope

The first closure fixture uses only IRIs. The separate
[`blank-node-boundary` fixture](../fixtures/rdfs-core/blank-node-boundary/)
now proves that one Turtle document's repeated blank-node spelling remains one
non-zero-scoped blank node through reasoner ownership and a destroyed-source
snapshot. The separate
[`cross-ingestion-blank-node` fixture](../fixtures/rdfs-core/cross-ingestion-blank-node/)
proves the complementary rule: equal labels from two parser calls have distinct
non-zero scopes and do not co-refer through the snapshot.

The adapter exposes only a default graph. `Named` and `Any_Named` scans return
`dataset.Invalid_View`; they are not reinterpreted as default-graph queries.

## Limits and errors exercised

The closure fixture creates 14 facts. The separate
[`default-graph-boundary` fixture](../fixtures/rdfs-core/default-graph-boundary/)
proves that `max_quads = 1` rejects a two-quad snapshot with
`sparql_adapter.Quad_Limit` and leaves the attempted snapshot empty. It also
proves that a scan sink returning `false` stops successfully and that `Named`
and `Any_Named` scans return `dataset.Invalid_View` rather than becoming
default-graph scans.

The successful path records parser, store, materializer, snapshot, and query
errors as their respective `None` values. It does not exercise parser failure,
reasoner materialization limits, allocation failure, or non-default graph
ingestion; those require additional, separately scoped fixtures.
