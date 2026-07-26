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
- [x] `docs/architecture.md` with the dependency map, package boundaries, and
  long-term semantic-data vocabulary.
- [x] `docs/adr/0001-defer-odin-graph.md`, recording why the graph/store layer
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

- [x] `ecosystem.toml` with a pinned Odin compiler revision and released
  component revisions.
- [x] A compatibility policy: supported combinations, upgrade procedure, and
  required integration gates before changing `rdf.Term`, blank-node scope,
  ownership contracts, or public dataset boundaries.
- [x] A machine-readable command manifest for local and CI verification.

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

- [x] A small source RDF fixture with documented provenance.
- [x] Expected asserted and inferred triples, including provenance expectations.
- [x] SPARQL `SELECT`, `ASK`, and `CONSTRUCT` queries over the same immutable
  closure snapshot.
- [x] A reproducible release-qualified local verification command and CI gate.

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

- [x] `docs/fixture-policy.md` defining required provenance, source version,
  interpretation, expected result, and license for every fixture.
- [x] `fixtures/` taxonomy separating source documents, normalized claims,
  asserted RDF, inferred output, and test expectations.
- [x] A review checklist for entity identity, contradictions, validity periods,
  and semantic-profile applicability.

### Acceptance

Every fixture answers: who asserted it, what supports it, under which profile
it is interpreted, and how an expected conclusion was derived. This is the
first defense against low-quality or ungrounded semantic data.

## Phase G4 — Release and change governance

### Deliverables

- [x] Cross-project compatibility table and release checklist.
- [x] ADR template for shared semantic decisions.
- [x] Change policy for data-model, blank-node, equality/hash, snapshot, and
  provenance changes.

### Acceptance

A core change cannot be released without identifying affected consumers and
running their relevant integration gates.

## Phase G5 — Bounded validation profile

Validation is a separate semantic concern from closure materialization. It may
consume an application-owned asserted graph or a completed upstream closure,
but it must not turn Reasoner provenance or Rule IDs into validation results.

### Deliverables

- [x] An authored SHACL Core fixture with separate data graph, shapes graph,
  deterministic expected report, ownership expectation, and explicit
  exclusions.
- [x] A proposed report/ownership contract that rejects unsupported SHACL
  semantics instead of treating them as conforming.
- [x] Pin the first `odin-shacl` release and its `odin-rdf` dependency in a
  dedicated Garden command and CI job.

### Acceptance

```text
RDF data + SHACL shapes
  -> bounded validation
  -> owned deterministic report
```

The qualifying gate must parse both graphs through the released RDF component,
destroy input ownership before reading the report, assert every expected result
field, and prove that an unsupported SHACL construct returns an error. It must
not claim SHACL-SPARQL, complex property paths, a shared graph store, or RDFS
materialization by the validator.

## Phase G6 — First local application workflow

The CLI is a consumer-facing boundary, not a replacement for the component
contracts. Garden qualifies it only as a fixed workflow over released parser
and validator inputs.

### Deliverables

- [x] An exact-output CLI fixture over the authored person-record data and
  shape graphs.
- [x] A versioned local-file, JSON-output, exit-status, and limits contract.
- [x] A dedicated command that checks all release tags, output bytes, exit
  status, and absence of diagnostics for completed validation.
- [x] A successful remote and post-merge Garden CI run for this application
  baseline.

### Acceptance

    local Turtle data + local Turtle shapes
      -> released RDF parsing + bounded SHACL validation
      -> deterministic JSON report + conventional exit status

The gate must not silently add standard input, output files, another RDF
syntax, remote loading, inference, SPARQL, named graphs, persistence, or a
server concern. Further application behavior starts only from a real consumer
requirement and its fixture.

## Phase G7 — First public-source application evidence

The first real-data workflow must distinguish source facts from an
application’s admission policy. A validation violation is not automatically a
claim that the source is false, malformed, or should be rewritten.

### Deliverables

- [x] A small external CC0 source excerpt with immutable revision, retrieval
  date, content digest, source/license record, and completed fixture review.
- [x] An explicit normalization boundary and ADR for a consumer-owned
  single-select capital policy.
- [x] A deterministic released-CLI command that returns the full policy result
  without any network access.
- [x] A successful remote and post-merge Garden CI run for the public-source
  application baseline.

### Acceptance

    immutable public source facts
      -> explicit application normalization
      -> local released CLI policy validation
      -> preserve source values + require a product decision

The gate must not silently choose a capital, treat a source multiplicity as a
logical contradiction, refresh the external source in CI, or use inference,
query, persistence, or network loading.

## Phase G8 — Local consumer-data evidence

Real consumer inputs may prove an application/content policy without becoming
a Garden fixture. They must first use the local intake and may publish only
owner-authorized, redacted aggregates.

### Deliverables

- [x] A local intake boundary that prevents unauthorized source data and full
  reports from entering Garden.
- [x] A first user-owned content-library evaluation, recording only structural
  aggregates, component revisions, the constraint category, and remediation
  ownership.
- [x] An ADR distinguishing absent curator-owned navigation links from invalid
  source content, and rejecting automatic relationship generation.
- [x] A license/publication boundary: no source or derived fixture until the
  owner resolves the source repository's inconsistent license declaration.

### Acceptance

    authorized local consumer input
      -> released local CLI validation
      -> redacted aggregate evidence
      -> owner chooses remediation or an evidenced Odin gap

The record must not turn a content policy into a truth claim, publish raw data
without clear authorization, or start a component solely because the data was
useful to inspect. The current Ism Library result is handled through curation,
an explicit standalone policy, or a UI fallback; it does not start C1–C5.
It is an evidence sample, not an Odin dependency or a scheduled product
workstream.

## Phase G9 — Release-boundary review for development integrations

Development convergence is useful evidence, but it cannot turn an adjacent
checkout into an undeclared runtime release dependency. A component may be
tagged only when every public dependency has a stable, reviewable delivery
boundary.

### Deliverables

- [x] Compare released Garden pins with the current Reasoner, SPARQL, and
  Graph heads.
- [x] Record that the post-v0.2 SPARQL public Dataset implementation requires
  experimental Graph, while Reasoner's core remains RDF-only.
- [x] Decide in ADR 0005 to defer a post-v0.2 SPARQL release until its Graph
  delivery boundary is explicitly chosen and Garden-qualified.
- [ ] When a release is actually proposed, choose the boundary, run the
  component release guide, then add a fixed-version Garden gate without
  weakening the existing baseline.

### Acceptance

Every published component can state the exact supported revisions and public
contracts it needs. Current-source convergence may inform a release decision,
but no consumer needs an unqualified adjacent checkout to reproduce a tagged
release.

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
