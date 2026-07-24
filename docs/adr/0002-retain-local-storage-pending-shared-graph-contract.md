# ADR 0002: retain local storage pending a shared graph contract

- Status: accepted
- Date: 2026-07-24
- Owners: `odin-reasoner`, `odin-sparql`, and Garden maintainers
- Related fixtures: `fixtures/rdfs-core/first-closure`,
  `fixtures/rdfs-core/blank-node-boundary`,
  `fixtures/rdfs-core/default-graph-boundary`, and
  `fixtures/rdfs-core/cross-ingestion-blank-node`

## Context

ADR 0001 deferred extraction until the existing production paths could be
compared.  That comparison is now based on released revisions, rather than on
an anticipated store design:

| Concern | `odin-reasoner` store and SPARQL snapshot adapter | `odin-sparql` Dataset boundary / `Memory_Dataset` | Common contract today |
| --- | --- | --- | --- |
| Term equality | Interned terms compare kind, lexical value, datatype, folded language, and blank-node scope.  The adapter copies RDF values and applies the same comparison. | RDF term equality uses the same fields; quads are a set under that equality. | Compatible value equality; no shared owner or identity table. |
| Graph scope | Internal facts and the adapter snapshot are default-graph only.  Named and any-named scans return `dataset.Invalid_View`. | Read-only views require graph-mode-aware scans; the memory implementation supports default, named, and any-named graphs. | Not met. |
| Scan work | The internal triple store selects an exact lookup, two-term index, one-term index, or full scan.  The adapter copies closure facts and then linearly scans its snapshot. | `Memory_Dataset` linearly scans sealed owned quads. | Not met: no indexed scan is reused across consumers. |
| Ownership and lifetime | The store owns interned terms.  The adapter owns a copied immutable quad snapshot that outlives the source store; scan values are borrowed until snapshot destruction. | The memory dataset owns copied lexical values; its sealed view borrows terms until destruction. | Similar lifetime shape, but separate allocation and copy paths. |
| Limits and errors | Snapshot has `max_quads`, all-or-nothing initialization, and adapter-specific `Quad_Limit`. | Dataset has `Quad_Limit`, `Lexical_Limit`, validation, sealing, and Dataset error codes. | Not met: the limit/error surface differs. |

The pinned Garden integration passes the source-RDF → RDFS closure → immutable
SPARQL-view path, including source lifetime, default-graph rejection, atomic
quad limit, early stop, and blank-node boundaries.  In particular, the
cross-ingestion fixture proves that equal parser labels from separate parser
calls are distinct blank nodes, while repeated labels within one document are
identical.  The fixture is evidence for the current adapter contract, not
proof that the two consumers share an in-memory graph implementation.

The component-level identity rules are also directly regression-tested:
`odin-reasoner/reasoner/term/dictionary_test.odin` checks language-tag
case-folding and blank-node scope in its interned dictionary, while
`odin-sparql/tests/dataset/dataset_test.odin` checks the corresponding
`Memory_Dataset` set and scan behavior.  The latter is current-main regression
evidence, not part of the pinned `v0.1.1` Garden release baseline; a future
baseline must publish and pin it before treating it as release-qualified.

## Decision

Keep the reasoner store, the reasoner-to-SPARQL snapshot adapter, and
`Memory_Dataset` local to their respective components.  Do not create or
extract `odin-graph` yet.

The candidate minimum graph contract will be reconsidered only after two
production-quality consumers demonstrably use all of the following without
materializing a second dataset:

1. one owned RDF term/blank-node identity boundary;
2. graph-scoped default, named, and any-named scan semantics where consumers
   require them;
3. an evidence-backed indexed scan implementation reused by both paths; and
4. one immutable snapshot ownership, bounded-resource, and stable-error
   contract.

The current reasoner snapshot remains a deliberately copying, default-graph
adapter.  It must reject unsupported graph modes explicitly and keep its
all-or-nothing `Quad_Limit` behavior.  It is not a provisional public graph
kernel.

## Consequences

### Positive

- The passing release-qualified integration stays valid without freezing an
  accidental storage representation as a public dependency.
- Blank-node scope and source/snapshot lifetime are now regression-tested at
  the integration boundary.
- Any future extraction has explicit, measurable convergence criteria.

### Costs and risks

- The closure adapter continues to allocate copied RDF terms and quads.
- Querying a reasoner closure does not currently reuse the reasoner indexes.
- Named-graph queries cannot be served by this closure adapter until a
  production requirement defines their closure semantics.
- A future shared kernel needs a migration comparison against the existing
  adapter, including result equivalence and limit/error behavior.

## Evidence and rollout

The comparison uses `odin-rdf v0.31.1` (`daa3505`), `odin-reasoner v0.1.0`
(`3ac9267`), and `odin-sparql v0.1.1` (`fcba9b6`) under the pinned
`dev-2026-07-nightly:ab0131c` Odin compiler.  Garden CI run
[30077117814](https://github.com/crapthings/odin-garden/actions/runs/30077117814)
verifies the declared release tags and commits, then passes all five
release-qualified integration tests, including the cross-ingestion blank-node
case.

Re-run `scripts/verify-rdfs-sparql.sh` from Garden whenever any pinned
component, the adapter, or a listed fixture changes.  Revisit this ADR only
with a second consumer path that proves the four convergence criteria above;
then add the corresponding fixture, result-equivalence test, migration plan,
and release note before proposing `odin-graph`.
