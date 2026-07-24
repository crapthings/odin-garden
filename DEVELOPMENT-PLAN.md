# odin-garden execution plan

## Mission

Build the minimum coordination layer needed for the Odin semantic ecosystem to
evolve as interoperable, evidence-backed components. Garden does not replace
the implementation repositories; it makes their boundaries, versions, and
end-to-end behavior explicit.

## Non-goals

- Do not implement `odin-graph`, `odin-store`, a database, or a server here.
- Do not move source code from the component repositories into this repository.
- Do not introduce git submodules as the primary integration mechanism.
- Do not collect arbitrary knowledge documents or generated content.
- Do not freeze unstable implementation APIs merely to create a matrix.

## Phase G0 — Charter and dependency map

### Deliverables

- [x] Repository charter in `README.md`.
- [x] This execution plan.
- [ ] `docs/architecture.md` with the dependency map, package boundaries, and
  long-term semantic-data vocabulary.
- [ ] `docs/adr/0001-defer-odin-graph.md`, recording why the graph/store layer
  remains pending.

### Acceptance

The architecture identifies the owner of each concern and preserves the current
allowed direction:

```text
odin-sparql   -> odin-rdf
odin-reasoner -> odin-rdf
reasoner SPARQL adapter -> odin-sparql
odin-garden   -> no runtime dependency
```

## Phase G1 — Compatibility baseline

### Deliverables

- [ ] `ecosystem.toml` with pinned Odin compiler revision and component release
  revisions.
- [ ] A compatibility policy: supported combinations, upgrade procedure, and
  required integration gates before changing `rdf.Term`, blank-node scope,
  ownership contracts, or public dataset boundaries.
- [ ] A machine-readable command manifest for local and CI verification.

### Acceptance

An integration run can state exactly which component revisions and compiler
revision produced a result. No integration check silently follows moving
`main` branches.

## Phase G2 — First end-to-end semantic closure example

### Preconditions

- `odin-reasoner` completes its RDFS Core materializer and exposes a completed
  closure snapshot through its optional SPARQL adapter.
- The integration uses only public APIs from `odin-rdf`, `odin-reasoner`, and
  `odin-sparql`.

### Deliverables

- [ ] A small source RDF fixture with documented provenance.
- [ ] Expected asserted and inferred triples, including provenance expectations.
- [ ] SPARQL `SELECT`, `ASK`, and `CONSTRUCT` queries over the same immutable
  closure snapshot.
- [ ] A single reproducible verification command and CI job.

### Acceptance

```text
RDF input
  -> reasoner fact store
  -> profiled materialization
  -> immutable closure snapshot
  -> SPARQL query
```

The gate proves both semantics and ownership boundaries. It must reject an
unsupported named-graph or profile case explicitly rather than silently making
up behavior.

## Phase G3 — Curated semantic fixture policy

### Deliverables

- [ ] `docs/fixture-policy.md` defining required provenance, source version,
  interpretation, expected result, and license for every fixture.
- [ ] `fixtures/` taxonomy separating source documents, normalized claims,
  asserted RDF, inferred output, and test expectations.
- [ ] A review checklist for entity identity, contradictions, validity periods,
  and semantic-profile applicability.

### Acceptance

Every fixture answers: who asserted it, what supports it, under which profile
it is interpreted, and how an expected conclusion was derived. This is the
first defense against low-quality or ungrounded semantic data.

## Phase G4 — Release and change governance

### Deliverables

- [ ] Cross-project compatibility table and release checklist.
- [ ] ADR template for shared semantic decisions.
- [ ] Change policy for data-model, blank-node, equality/hash, snapshot, and
  provenance changes.

### Acceptance

A core change cannot be released without identifying affected consumers and
running their relevant integration gates.

## Decision gate: whether to create `odin-graph` or `odin-store`

Neither project is scheduled by date. Revisit extraction only when all of the
following are true:

1. `odin-reasoner` and `odin-sparql` each use the same owned term identity,
   indexed scan, and immutable snapshot semantics in production-quality paths.
2. The RDFS closure-to-SPARQL integration gate has passed against pinned
   versions and fixtures.
3. The candidate shared API can be written from existing use cases without
   speculative methods.
4. There is a concrete requirement for persistence, transactions, named graphs,
   or a second independently maintained consumer.
5. Ownership, blank-node identity, set/multiset boundaries, resource limits,
   and migration semantics have an ADR and tests.

### If the gate passes

- Extract only the validated common kernel into `odin-graph`.
- Keep inference, SPARQL algebra, parsing, and network/service concerns out of
  that kernel.
- Consider `odin-store` only when durable storage and transaction semantics are
  concrete requirements; it may depend on `odin-graph`, but need not exist at
  the same time.

### If the gate does not pass

Continue evolving the reasoner-internal fact store and SPARQL adapters. Record
new evidence in an ADR; do not create a placeholder repository.

## First work session checklist

1. Create `docs/architecture.md` from the current approved cross-project
   boundaries.
2. Create ADR 0001 documenting the deferral of `odin-graph`.
3. Add an empty versioned `ecosystem.toml` schema with comments, without yet
   pinning unreleased reasoner code.
4. Define the end-to-end fixture format before adding any semantic data.
5. Only after RDFS Core has an adapter, implement the first integration gate.
