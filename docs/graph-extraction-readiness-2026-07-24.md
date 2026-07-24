# Graph extraction readiness plan — 2026-07-24

## Purpose

This is a time and dependency assessment for deciding whether to extract
`odin-graph`. It is not a date-based commitment to create that repository.
The authoritative decision criteria remain [ADR 0002](adr/0002-retain-local-storage-pending-shared-graph-contract.md).

## Verified starting point

The historical release-qualified combination remains recorded in
[CI run 30083966449](https://github.com/crapthings/odin-garden/actions/runs/30083966449),
but it is not the active development baseline. The current development gate
pins exact RDF, Reasoner, SPARQL, and Graph source commits and runs both the
RDFS-to-SPARQL integration fixture and Graph closure-origin/derivation fixture.

The direct reasoner-to-SPARQL path now has a Store-adopting immutable Snapshot
that retains reasoner-owned terms and indexes without a second Dataset copy.
`Memory_Dataset` now owns the shared Graph kernel directly, including its
freeze-time scan indexes. The Reasoner Store remains a distinct indexed,
transactional inference representation; its Graph adapter copies a completed
closure and preserves asserted/inferred origin plus first derivation supports.

## Remaining work and estimate

| Order | Deliverable | Dependency | Estimate | Completion evidence |
| --- | --- | --- | --- | --- |
| 1 | Name the first production named-graph consumer and define its `Named` / `Any_Named` semantics, including default-graph interaction. | Product or application requirement; this cannot be inferred from current code. | 0.5–1 working day after the requirement is supplied. | ADR, curated fixture, and explicit supported/rejected query cases. |
| 2 | Specify the smallest common mutation, freeze, ownership, resource-limit, and error contract from that consumer and the existing reasoner path. | Step 1. | 1–2 working days. | Public API sketch, atomicity/error matrix, migration notes, and contract tests. |
| 3 | Decide whether the Reasoner requires live term/index identity rather than the verified frozen Graph closure copy. | Step 2. | 1–3 working days. | Explicit requirement, ownership/transaction analysis, and a revised ADR. |
| 4 | Keep exact-source migration equivalence running across RDF, Reasoner, SPARQL, and Graph. | Step 3. | 0.5–1 working day per material contract change. | Current-source Garden gate and updated conformance evidence. |

The remaining effort depends on whether an application requires Reasoner live
identity or durable storage. Persistence, recovery, concurrency, and isolation
requirements have not been approved and are intentionally not estimated.

## Execution rule until Step 1 exists

Do not add persistence, multi-writer behavior, or Reasoner named-graph
semantics merely to reduce an estimate. Keep publishing exact-source regression
evidence for the existing default-graph inference paths. The explicit
`Invalid_View` response for unsupported Reasoner named-graph scans remains the
correct contract until an actual consumer defines the semantics.

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

The current development Graph source also builds immutable scan candidate
indexes at freeze time and retains each copied closure fact's asserted/inferred
first origin plus its opaque first rule and supporting Graph facts.
[Development convergence CI run 30085650816](https://github.com/crapthings/odin-garden/actions/runs/30085650816)
checks every fact and every RDFS derivation record in the fourteen-fact fixture
against the source Store and Materializer. This is deliberately a separate
exact-source development gate, not a release-qualified baseline and not
evidence of no-copy ownership or Reasoner provenance-derivation reuse.

## Reassessment trigger

Re-run this plan when an application supplies a named-graph use case, a second
independently maintained graph consumer, or a durable/multi-writer requirement.
If none is supplied, the correct completed state is to retain the local
implementations described by ADR 0002.
