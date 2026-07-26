# Odin semantic ecosystem architecture

## Purpose

This document records the current runtime boundaries of the Odin semantic
ecosystem and the evidence required before extracting a shared graph or storage
layer. It is an integration contract, not an API specification for a future
package.

## Current runtime shape

```text
                         +----------------+
                         |   odin-rdf     |
                         | terms, syntax, |
                         | streaming I/O  |
                         +----------------+
                            ^          ^
                            |          |
               +------------+          +------------+
               |                                    |
+---------------------------+       +---------------------------+
|      odin-reasoner        |       |        odin-sparql         |
| profiles, fact closure,   |       | query algebra and bounded  |
| closure snapshots         |       | execution over read-only   |
|                           |       | Dataset views              |
+-------------+-------------+       +---------------------------+
              |
              | optional immutable closure view
              v
       odin-sparql Dataset adapter

odin-garden: contracts, pinned compatibility, fixtures, and verification only
```

The permitted runtime dependencies are:

```text
odin-sparql   -> odin-rdf
odin-reasoner -> odin-rdf
reasoner SPARQL adapter -> odin-sparql   (optional; outside reasoner core)
odin-garden   -> no runtime dependency
```

## Ownership today

| Concern | Owner | Explicit boundary |
| --- | --- | --- |
| RDF terms, syntax, canonicalization, streaming input/output | `odin-rdf` | Not a dataset database or query engine. |
| Forward rule evaluation, asserted/inferred triple facts, closure provenance | `odin-reasoner` | Its fact store is internal, triple-only, and currently default-graph scoped. |
| Query parsing, algebra, result semantics, graph-scoped read scans | `odin-sparql` | Its Dataset boundary is read-only and storage-agnostic. |
| Cross-project revisions, fixtures, compatibility, architectural decisions | `odin-garden` | Has no runtime dependency. |

`odin-sparql` already permits an application-owned immutable snapshot through
`dataset.custom_view`. This is an adapter boundary, not an endorsement of a
particular storage implementation. `odin-reasoner` already makes a bounded,
transactional working copy while calculating a closure. That is an inference
correctness mechanism, not a public transaction API. Released
`odin-reasoner v0.6.0` supplies both an indexed *live borrowed* view and a
Store-adopting immutable Snapshot: the latter retains the reasoner-owned terms
and scan path without a second Dataset copy. It remains a reasoner-specific,
default-graph boundary rather than the common graph snapshot proposed here.

## Candidate shared layers

The following names describe distinct responsibilities. They must not be
combined merely because both may hold RDF facts.

```text
odin-rdf  ->  odin-graph  ->  odin-store
                  |              |
                  |              +-- durable storage, recovery, concurrency,
                  |                  transaction isolation and backend policy
                  |
                  +-- validated in-memory graph kernel: RDF Dataset set
                      semantics, graph scope, owned values, indexed scans,
                      resource limits, and immutable snapshots
```

### `odin-graph` — possible first extraction

If the extraction gate passes, `odin-graph` may contain only the common,
validated in-memory graph kernel:

- RDF Dataset set semantics over default and named graphs;
- explicit value ownership and blank-node identity boundaries;
- bounded graph-scoped scans and indexes where consumers demonstrate need;
- immutable snapshots that can back the public SPARQL Dataset adapter; and
- resource-limit and migration behavior proven by shared tests.

It must not absorb RDF parsing, SPARQL algebra, inference rules, network
behavior, persistence, or a general-purpose transaction API. A write-batch or
snapshot primitive belongs here only after the reasoner and another consumer
need the same public semantics.

### `odin-store` — explicitly future work

`odin-store` is a durable storage layer, not a synonym for an in-memory graph
collection. It would own concrete requirements such as persistence across
restart, recovery, concurrency, transaction isolation, backend failures,
backup, and operational limits. It may depend on a validated `odin-graph`, but
it is neither required nor implied by it.

No `odin-store` repository or implementation is created until those
requirements are concrete and tested by more than one consumer path.

## Extraction gate

Do not create a placeholder `odin-graph` or `odin-store` repository. Revisit
the graph extraction only when every condition below has evidence:

1. `odin-reasoner` and `odin-sparql` use the same owned term identity,
   indexed scan, and immutable snapshot semantics in production-quality paths.
2. A pinned-version RDFS closure-to-SPARQL integration gate passes using only
   public APIs and curated fixtures.
3. The proposed public API is a smallest common denominator written from those
   concrete paths, rather than a forecast of a future database.
4. Ownership, blank-node identity, set/multiset semantics, resource limits,
   snapshot behavior, and migration rules have ADRs and tests.

Create `odin-store` only after the graph gate has passed *and* a durable or
multi-writer requirement makes its transaction semantics concrete.

## Current assessment — 2026-07-26

The in-memory Graph kernel is implemented as an experimental repository, but
it is no longer the representation or runtime prerequisite of the released
`odin-sparql` core. `Memory_Dataset` owns its bounded RDF Dataset directly over
`odin-rdf`; Graph remains an optional adapter. The remaining question is
whether a second production-quality consumer needs Graph's particular no-copy
ownership and index contract. No durable runtime layer is proposed:

| Gate | Status | Evidence / gap |
| --- | --- | --- |
| Common owned terms and snapshot semantics | Partial | The released `Memory_Dataset` owns an RDF-only bounded set; the Reasoner owns a distinct indexed transactional Store. Graph's optional Reasoner and SPARQL adapters remain migration evidence, not a shared runtime representation. See ADR 0002 and ADR 0006. |
| Pinned closure-to-query integration | Met, deliberately split | Garden retains the historical fixed `odin-rdf v0.32.1` / Reasoner `v0.6.0` / SPARQL `v0.2.0` / experimental Graph `v0.1.0` closure tuple. Separately, `sparql-core-v0.7` pins RDF `v0.33.0` and SPARQL `v0.7.0` with no Graph checkout, and verifies owned and custom Dataset views. Neither row claims a common no-copy snapshot. |
| Minimal API from existing use cases | Partial | Garden now has a provisional multi-source named-graph fixture and a [candidate shared graph contract](candidate-shared-graph-contract.md) for mutation, freeze, limits, and errors. Reasoner still has only indexed default-graph closure; the proposal is not an extracted implementation or a production requirement. |
| Durable-store requirement | Not met | There is no approved persistence, restart, multi-writer, or isolation requirement. |

The completed Garden fixture is evidence for the current in-memory Graph
boundary, not approval for a shared Reasoner Store or durable storage. The
remaining work is to establish common owned-term, index, and immutable snapshot
semantics across more than one production-quality consumer path. The current
dependency-ordered estimate is in [graph extraction readiness plan —
2026-07-24](graph-extraction-readiness-2026-07-24.md).
