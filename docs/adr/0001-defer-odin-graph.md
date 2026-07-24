# ADR 0001: defer shared graph and store extraction

- Status: accepted
- Date: 2026-07-24

## Context

The ecosystem currently contains three intentionally different data-holding
mechanisms:

- `odin-rdf:rdf/dataset.Collector` receives parser output and preserves input
  order and duplicates. It is an ingestion collector, not an RDF Dataset.
- `odin-sparql:sparql/dataset.Memory_Dataset` owns a bounded set of RDF quads
  and exposes a sealed, read-only view for query execution. Applications can
  instead expose an immutable external view through `custom_view`.
- `odin-reasoner:reasoner/store` owns indexed triples and supports bounded
  working copies for transactional closure materialization. It is internal,
  default-graph scoped, and not a graph-store API.

These mechanisms share some vocabulary but do not yet share public ownership,
graph-scope, mutation, snapshot, or error semantics. Extracting their current
implementations would freeze accidental differences as a common dependency.

## Decision

Do not create `odin-graph` or `odin-store` repositories now.

First establish cross-project evidence in Garden:

1. Pin released component and compiler revisions.
2. Add a provenance-backed fixture proving RDF input → RDFS closure →
   immutable SPARQL query snapshot through public APIs.
3. Record the ownership, blank-node identity, set/multiset, resource-limit,
   snapshot, and failure contracts exercised by that fixture.

When the graph extraction gate passes, create **`odin-graph` first** as a
small in-memory graph kernel. Its contents must be limited to validated shared
Dataset/graph behavior. It excludes parsing, query algebra, inference, durable
storage, network services, and speculative transaction features.

Treat **`odin-store` as a later, separate layer**. It may depend on
`odin-graph`, but requires a concrete need for persistence, recovery,
concurrency, or transaction isolation. It is not created simply because an
in-memory graph holds RDF facts.

## Consequences

### Positive

- Existing repositories retain clear ownership and can evolve independently.
- The first shared API is derived from public, tested consumer paths.
- Durable-storage decisions remain reversible until operational requirements
  exist.
- SPARQL can keep using its public external-view boundary while the graph
  contract is validated.

### Costs

- A small amount of storage/indexing logic remains local while behavior is
  still being proven.
- Garden integration work precedes a new core repository.
- A future extraction needs an explicit migration plan instead of a mechanical
  rename.

## Reconsideration criteria

Replace this deferral only when all of the following are true:

1. Reasoner and SPARQL share owned term identity, indexed scan, and immutable
   snapshot semantics in production-quality paths.
2. The pinned RDFS closure-to-SPARQL Garden gate passes.
3. The candidate graph API is completely supported by existing use cases and
   their tests.
4. The relevant ownership, blank-node, set/multiset, limit, snapshot, and
   migration choices have been recorded in ADRs.

Create `odin-store` only with an additional approved durability or multi-writer
requirement that states the required transaction and recovery semantics.
