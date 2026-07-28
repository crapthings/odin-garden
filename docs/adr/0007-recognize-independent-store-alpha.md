# ADR 0007: recognize the independent local Store alpha

- Status: accepted
- Date: 2026-07-28
- Owners: Garden maintainers and `odin-store` maintainers

## Context

ADR 0001 and the original architecture document deferred creating an
`odin-store` repository until a common graph kernel and a durable requirement
were demonstrated. That was the correct decision at the time, but it is no
longer an accurate description of the repositories: `odin-store v0.1.0-alpha.1`
now exists as an independently released, local durability library.

Its evidence comes from a concrete single-writer workflow: immutable RDF
Dataset generations, verified reopen, document/chunk/extraction provenance,
and explicit append-only review records. The workload is specified by the
[Store operational workload contract](../store-operational-workload-contract.md).

The alpha does not make `odin-store` the common graph representation, a
required runtime dependency, or a release-qualified ecosystem baseline. Its
public API is still allowed to change before beta, and it remains local,
Darwin-only, and single-writer.

## Decision

Recognize `odin-store` as an independent experimental durability layer with
the following boundary:

- Garden owns the cross-project workload contract and future compatibility
  evidence; it does not import or run Store at runtime.
- Store owns atomic durable generations, fail-closed reopen, RDF snapshot
  reads, and a schema-neutral operational provenance ledger.
- Applications own source bytes, chunking, model calls, domain vocabularies,
  identity policy, and the meaning of any review decision. They pass explicit
  records and RDF facts to Store.
- Store is not yet a shared replacement for `odin-graph`, the Reasoner Store,
  or SPARQL's `Memory_Dataset`; no existing component acquires a Store runtime
  dependency through this decision.

Garden will not call the alpha release-qualified until a pinned public API,
platform policy, and reproducible cross-project gate are recorded. The prior
graph-extraction gate remains in force for a shared in-memory representation;
it is not a precondition for this independent local durability experiment.

## Consequences

- Garden documentation must distinguish an existing independent alpha from a
  shared, release-qualified ecosystem storage layer.
- Workload phases and crash points use the Garden contract as their source of
  meaning, rather than an unversioned reference to “Garden W8”.
- A future stable Store release needs an explicit compatibility row and gate;
  it must not be silently substituted into an existing Garden baseline.
