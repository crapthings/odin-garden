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

```mermaid
flowchart TB
    Garden["odin-garden<br/>cross-project contracts, fixtures, and verification"]

    RDF["odin-rdf<br/>RDF model, syntax, streaming ingestion,<br/>and canonicalization"]
    SPARQL["odin-sparql<br/>SPARQL 1.1 query parsing<br/>and bounded execution"]
    Reasoner["odin-reasoner<br/>profiled forward reasoning<br/>and closure snapshots"]

    SPARQL -->|runtime dependency| RDF
    Reasoner -->|runtime dependency| RDF
    Garden -.->|defines contracts and verifies integration| RDF
    Garden -.->|defines contracts and verifies integration| SPARQL
    Garden -.->|defines contracts and verifies integration| Reasoner
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

The first integration path is deliberately narrow:

```mermaid
flowchart LR
    Input["pinned RDF input"] --> Materialize["RDFS materialization"]
    Materialize --> Snapshot["immutable closure snapshot"]
    Snapshot --> Query["SPARQL query"]
    Query --> Expected["checked expected result"]
```

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

Garden has completed its foundation milestones: the architecture and deferral
ADRs are published, released component revisions are pinned, and the first
evidence-backed RDFS-to-SPARQL integration path is release-qualified. The
current decision is to retain local storage implementations until a second
production-quality consumer proves a genuinely shared graph contract; see
[ADR 0002](docs/adr/0002-retain-local-storage-pending-shared-graph-contract.md).

The initial fixture and its fixed release-qualified command live in
[`ecosystem.toml`](ecosystem.toml). It is reproducible compatibility evidence
for the documented RDFS Core default-graph path, not a general graph-extraction
claim.

The exercised ownership, graph-scope, blank-node, resource-limit, and error
boundaries are recorded in
[`docs/rdfs-sparql-first-closure-contract.md`](docs/rdfs-sparql-first-closure-contract.md).
The release-qualified interoperability commitments, including the explicit
deferral of validation reports and a universal Rule IR, are recorded in
[`docs/release-qualified-interop-contract.md`](docs/release-qualified-interop-contract.md).
The bounded SHACL report boundary, its pinned release pair, and its qualifying
fixture are recorded separately in
[`docs/shacl-core-validation-contract.md`](docs/shacl-core-validation-contract.md).
It remains distinct from the RDFS-to-SPARQL tuple and does not imply a shared
Graph/store or a universal report serialization.

The first local application workflow, `odin validate`, is qualified separately
by its [CLI contract](docs/cli-validate-contract.md). It fixes local
Turtle-only admission, deterministic JSON output, and exit behavior while
remaining independent from inference, query, persistence, service, and network
concerns.

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
