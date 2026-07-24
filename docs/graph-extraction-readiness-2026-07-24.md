# Graph extraction readiness plan — 2026-07-24

## Purpose

This is a time and dependency assessment for deciding whether to extract
`odin-graph`. It is not a date-based commitment to create that repository.
The authoritative decision criteria remain [ADR 0002](adr/0002-retain-local-storage-pending-shared-graph-contract.md).

## Verified starting point

Garden currently pins released `odin-rdf v0.31.1`, `odin-reasoner v0.3.0`,
`odin-sparql v0.2.0`, and experimental `odin-graph v0.1.0`. Its
release-qualified gate includes both the established closure path and the
public graph-backed SPARQL Dataset consumer path.

The direct reasoner-to-SPARQL path now has a Store-adopting immutable Snapshot
that retains reasoner-owned terms and indexes without a second Dataset copy.
`Memory_Dataset` has independently released identity and named-graph scan
coverage. These are compatible evidence points, not one shared representation.

## Remaining work and estimate

| Order | Deliverable | Dependency | Estimate | Completion evidence |
| --- | --- | --- | --- | --- |
| 1 | Name the first production named-graph consumer and define its `Named` / `Any_Named` semantics, including default-graph interaction. | Product or application requirement; this cannot be inferred from current code. | 0.5–1 working day after the requirement is supplied. | ADR, curated fixture, and explicit supported/rejected query cases. |
| 2 | Specify the smallest common mutation, freeze, ownership, resource-limit, and error contract from that consumer and the existing reasoner path. | Step 1. | 1–2 working days. | Public API sketch, atomicity/error matrix, migration notes, and contract tests. |
| 3 | Implement a narrow shared in-memory representation plus immutable snapshot, then adapt the existing reasoner and SPARQL paths without moving inference or query algebra. | Step 2. | 3–5 working days. | Ownership, blank-node, duplicate, graph-scan, limit, and snapshot tests; no adapter-specific Dataset copy in the shared path. |
| 4 | Run migration equivalence, pin releases, and update Garden fixtures/CI. | Step 3. | 1.5–2 working days. | Pinned cross-project result-equivalence gate, release notes, and an extraction-decision ADR update. |

**Total after a concrete named-graph requirement: 6–10 working days.** The
range excludes review latency and any durable-store requirement. `odin-store`
is not estimated because persistence, recovery, concurrency, and isolation
requirements have not been approved.

## Execution rule until Step 1 exists

Do not implement named-graph storage, an error-code wrapper, or an
`odin-graph` placeholder merely to reduce the estimate. Keep publishing and
pinning regression evidence for the existing default-graph paths. The explicit
`Invalid_View` response for unsupported named-graph scans remains the correct
contract until an actual consumer defines the semantics.

## Provisional consumer evidence

Garden now carries the synthetic `named-graph-source-isolation` fixture. It
models two source-owned named graphs plus default-graph publication metadata,
and exercises exact `GRAPH <name>`, variable `GRAPH ?name`, and default-graph
non-leakage through the released `Memory_Dataset` path. This is a deliberately
narrow test consumer that fixes candidate semantics and regression evidence;
it is **not** a substitute for the first production named-graph requirement.

The fixture does not change the rule above: the reasoner adapter continues to
return `Invalid_View` for named graph modes, and no shared graph extraction or
named-graph store implementation should begin until an application adopts (or
replaces) these semantics.

## Candidate contract

[`candidate-shared-graph-contract.md`](candidate-shared-graph-contract.md)
records the smallest proposed mutation, freeze, ownership, limit, error, and
migration contract. Garden's candidate contract test pins the currently shared
observable behavior: duplicate-at-capacity success, failed-admission
atomicity, freeze immutability, and graph-scoped scans. The document is a
design input for Step 3, not an extracted implementation or an ADR reversal.

## Candidate implementation evidence

Released `odin-graph v0.1.0` pins its own core tests and provides separate
optional SPARQL and Reasoner migration adapters. Garden ingests the synthetic
TriG fixture into that graph, freezes it, and executes the fixture's exact
named, variable named, and default-isolation queries through the SPARQL
adapter. Released `odin-sparql v0.2.0` also exposes that path as the opt-in
public `sparql/graph_dataset` package, which Garden consumes against the same
fixture. This proves the released graph-to-SPARQL consumer boundary without
changing the released reasoner adapter or claiming a shared reasoner
representation. A
separate copying Reasoner closure prototype now produces the same Garden
SELECT, ASK, and CONSTRUCT results as the existing reasoner Snapshot after the
source Store is destroyed. It is migration evidence only: it neither reuses
the Store's indexes nor broadens the reasoner's default-graph-only public
contract.

## Reassessment trigger

Re-run this plan when an application supplies a named-graph use case, a second
independently maintained graph consumer, or a durable/multi-writer requirement.
If none is supplied, the correct completed state is to retain the local
implementations described by ADR 0002.
