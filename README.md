# odin-garden

> **Work in progress.** The Odin Garden is not ready for general integration
> use yet. Its contracts, compatibility policy, fixtures, and verification
> gates are being established in the open.

![Abstract semantic graph nodes linked through a calm green garden](assets/odin-garden-banner.jpg)

`odin-garden` is the integration, contract, and verification home for the
Odin semantic infrastructure ecosystem. It is where independently released
projects agree on their boundaries and prove that they work together.

Garden is deliberately **not** a monorepo, shared-runtime package, graph
database, or general knowledge dump.

## Ecosystem

```text
odin-rdf       RDF model, syntax, streaming ingestion, and canonicalization
  ├─ odin-sparql     SPARQL 1.1 query parsing and bounded execution
  └─ odin-reasoner   Profiled forward reasoning and closure snapshots

odin-garden    Cross-project contracts, fixtures, and verification
```

The permitted runtime dependencies are:

```text
odin-sparql   -> odin-rdf
odin-reasoner -> odin-rdf
SPARQL adapter -> odin-sparql   (optional; outside the reasoner core)
odin-garden   -> no runtime dependency
```

Candidate layers such as `odin-graph`, `odin-store`, and a service layer are
intentionally deferred. They will be considered only when current consumers
show stable, shared requirements.

## What belongs here

- Ecosystem architecture, dependency directions, and cross-project ADRs.
- Pinned compatibility and compiler-version policy.
- Small, curated semantic fixtures with provenance and explicit expectations.
- Reproducible integration gates, beginning with:

  ```text
  RDF input -> RDFS materialization -> immutable closure snapshot -> SPARQL query
  ```

- Shared terminology for asserted and inferred facts, evidence, provenance,
  validity, and versioning.

## What does not belong here

- Runtime implementations copied from `odin-rdf`, `odin-sparql`, or
  `odin-reasoner`.
- A graph database, persistent store, query engine, or rule engine.
- Network services, authentication, tenancy, or protocol code.
- Unreviewed scraped data, generated summaries, or unbounded document
  collections.
- Claims that the ecosystem already includes a graph or storage layer.

## Status

Garden is in its foundation phase. The immediate work is to publish the
architecture and deferral ADR, pin compatible component revisions, and add the
first evidence-backed RDFS-to-SPARQL integration fixture.

The initial fixture and its fixed release-qualified command now live in
[`ecosystem.toml`](ecosystem.toml). It is reproducible compatibility evidence
for the documented RDFS Core default-graph path, not a general graph-extraction
claim.

The exercised ownership, graph-scope, blank-node, resource-limit, and error
boundaries are recorded in
[`docs/rdfs-sparql-first-closure-contract.md`](docs/rdfs-sparql-first-closure-contract.md).

New semantic evidence follows the
[fixture policy](docs/fixture-policy.md), [fixture taxonomy](fixtures/README.md),
and [review checklist](docs/fixture-review-checklist.md).

Supported cross-project combinations and the release/change process are defined
in [release governance](docs/release-governance.md) and the
[semantic change policy](docs/change-policy.md).

The component projects remain independently released and versioned. Do not
point integration checks at moving `main` branches.

## Principles

1. **Focused projects, explicit integration.** Each project owns its runtime
   code and release cadence; Garden owns cross-project agreements.
2. **Evidence before claims.** Every fixture identifies its source,
   interpretation, semantic profile, expected result, and exclusions.
3. **No hidden policy.** Storage, inference, transport, authorization, and
   source trust remain explicit choices at their owning layer.
4. **Stable knowledge is versioned.** Provenance, semantic profile, and
   validity are part of a reusable fact's meaning.
5. **Extract only after use.** Shared infrastructure follows demonstrated
   common contracts, never a speculative abstraction.

## Roadmap

The staged execution plan is in [DEVELOPMENT-PLAN.md](DEVELOPMENT-PLAN.md).
It includes the explicit decision gate for any future `odin-graph` or
`odin-store` extraction.

The current ecosystem boundary is documented in
[docs/architecture.md](docs/architecture.md). The decision to defer both
runtime extractions, then create `odin-graph` before any future `odin-store`,
is recorded in
[ADR 0001](docs/adr/0001-defer-odin-graph.md).

## License

License information will be added before the first public release.
