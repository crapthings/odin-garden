# Candidate shared in-memory graph contract

Status: proposal for the extraction decision; no public package or existing
implementation changes its behavior by this document.

## Evidence and scope

The [`named-graph-source-isolation`](../fixtures/rdfs-core/named-graph-source-isolation/)
fixture supplies the smallest candidate consumer: default-graph catalog
metadata plus two source-owned named graphs. Its tests require exact `Named`,
variable `Any_Named`, and default-graph-only selection.

The proposed kernel owns an RDF Dataset set. It is not a reasoner: asserted
versus inferred origin, rule derivations, provenance, transactions, durability,
networking, and SPARQL algebra remain outside this contract.

## Candidate API

```odin
Options :: struct {
    Max_Quads:         int, // zero disables the bound
    Max_Lexical_Bytes: int, // zero disables the bound
    Max_Terms:         int, // zero disables the bound
}

Error :: enum {
    None, Invalid_Options, Invalid_Quad, Sealed,
    Quad_Limit, Lexical_Limit, Term_Limit, Out_Of_Memory,
}

Graph    :: struct { /* owned mutable Dataset set */ }
View     :: struct { /* borrowed frozen Graph handle */ }
Graph_Mode   :: enum { Default, Named, Any_Named }
Quad_Pattern :: struct { /* graph, subject, predicate, object selectors */ }
Scan_Sink    :: #type proc(rdf.Quad, rawptr) -> bool

init    :: proc(graph: ^Graph, options: Options = {}) -> Error
add     :: proc(graph: ^Graph, quad: rdf.Quad) -> Error
freeze  :: proc(graph: ^Graph) -> Error
view    :: proc(graph: ^Graph) -> (View, Error)
scan    :: proc(view: View, pattern: Quad_Pattern, sink: Scan_Sink, data: rawptr = nil) -> Error
destroy :: proc(graph: ^Graph)
```

`Graph` changes state only through `add` before `freeze`. `freeze` is
idempotent, does not copy the Dataset, and makes `view` available. A View
borrows terms from its owner and remains valid only until `destroy`; owners
must not mutate a Graph during a scan. The kernel deliberately does not import
`odin-sparql`; the next-stage SPARQL adapter maps this View and scan callback
onto `dataset.custom_view`.

The view observes RDF Dataset set semantics: exact duplicates are successful
no-ops, including when a capacity bound has been reached. `Default` selects
only quads without a graph term, `Named` selects exactly its graph term, and
`Any_Named` selects only named quads. A scan sink returning `false` is a
successful early stop.

## Admission, atomicity, and errors

`add` validates the entire quad and all applicable limits before committing it.
On every non-`None` result, the quad set, owned lexical values, term table, and
resource counters remain unchanged. A caller needing all-or-nothing document
ingestion builds a fresh Graph, discards it after the first error, and only
then publishes its frozen view; batch ingestion is intentionally outside the
first public API.

| Condition | Candidate result | Required state afterward | Existing correspondence |
| --- | --- | --- | --- |
| Negative option | `Invalid_Options` | Safe to destroy; no graph exists | Dataset and Store already reject invalid limits. |
| Structurally invalid quad | `Invalid_Quad` | No added quad, term, or byte charge | Dataset validates the quad; Store validates triples. |
| New distinct quad exceeds `Max_Quads` | `Quad_Limit` | No partial admission | Dataset `Quad_Limit`; Store `Fact_Limit` maps here. |
| New lexical payload exceeds `Max_Lexical_Bytes` | `Lexical_Limit` | No partial admission | Dataset `Lexical_Limit`; Store `Lexical_Bytes_Limit` maps here. |
| New term exceeds `Max_Terms` | `Term_Limit` | No partial admission | Required by the Store; not yet exposed by Memory_Dataset. |
| Allocation failure | `Out_Of_Memory` | No partial admission | Required guarantee for the shared implementation. |
| Add after `freeze` | `Sealed` | Frozen contents unchanged | Dataset already has this behavior. |
| Duplicate at any capacity | `None` | Contents and resource counters unchanged | Dataset and Store already deduplicate. |

`Invalid_View` and `Invalid_Sink` are scan-wrapper errors, not graph-admission
errors. A full shared Graph view supports all three graph modes. The SPARQL
adapter maps those failures to its public Dataset errors. The existing reasoner
adapter continues to return `dataset.Invalid_View` for named modes until the
reasoner itself adopts named-graph ingestion and closure semantics.

## Migration notes

1. `Memory_Dataset` becomes an adapter or compatible alias over `Graph`; its
   `seal`/`view` behavior remains source-compatible. Adding `Max_Terms` is a
   minor API extension with zero meaning “unbounded”.
2. The reasoner retains its rule indexes, fact origin, and materialization
   transaction logic. Its asserted/default-graph facts are admitted through
   Graph semantics; per-fact origin and inference indexes remain reasoner
   metadata rather than graph-kernel state.
3. A completed reasoner closure freezes once and yields a borrowed shared
   view. This replaces both copied Snapshot admission and Store-adopting
   handoff only after result-equivalence and resource-error tests pass.
4. The reasoner’s public adapter must keep rejecting `Named` and `Any_Named`
   until an application approves named-graph reasoning semantics. The kernel's
   ability to store such quads does not silently broaden that adapter.

## Contract-test entry criteria

Before implementation, Garden must prove the synthetic named-graph fixture;
duplicate-at-capacity behavior; invalid, lexical-limit, and quad-limit
atomicity; frozen-view immutability; and early-stop scanning. Before release,
the same cases must pass through the shared kernel, `Memory_Dataset`
compatibility surface, and reasoner default-graph adapter, with the latter
preserving its explicit named-graph rejection.
