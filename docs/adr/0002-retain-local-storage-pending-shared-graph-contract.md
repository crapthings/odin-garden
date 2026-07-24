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
| Scan work | The store selects an exact lookup, two-term index, one-term index, or full scan.  The immutable snapshot copies closure facts then scans linearly; released `indexed_view` reuses the store index while the source lives. | `Memory_Dataset` linearly scans sealed owned quads. | Partial: the direct reasoner→SPARQL live path reuses an index, but no shared immutable scan implementation exists. |
| Ownership and lifetime | The store owns interned terms.  `indexed_view` borrows those terms while the source lives; `adopt_store` transfers them into an immutable indexed Snapshot, while `init` retains the copied Snapshot option. | The memory dataset owns copied lexical values; its sealed view borrows terms until destruction. | Partial: direct reasoner→SPARQL now has an independent no-copy immutable Snapshot, but it is not the shared `Memory_Dataset` representation. |
| Limits and errors | Copied Snapshot has `max_quads`, all-or-nothing initialization, and adapter-specific `Quad_Limit`; an adopted Snapshot retains the source Store's bounded admission rules. | Dataset has `Quad_Limit`, `Lexical_Limit`, validation, sealing, and Dataset error codes. | Not met: the limit/error surface still differs. |

The pinned Garden integration passes the source-RDF → RDFS closure → immutable
SPARQL-view path and the live indexed View/result-equivalence path, including
source lifetime, default-graph rejection, atomic quad limit, early stop, and
blank-node boundaries.  In particular, the
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

The limit/error differences are semantic, not merely naming differences.
`Memory_Dataset` validates and admits one mutable quad at a time, so it can
report invalid input, sealing, lexical-byte, and quad-capacity failures at the
write boundary. The reasoner Store instead admits terms and triples while
importing or materializing a closure, with term, lexical-byte, and fact limits.
Only after that work does copied `Snapshot.init` apply its all-or-nothing
`max_quads` bound; `adopt_store` performs no new admission at all. A future
common contract must first choose its mutation phase, atomicity, and resource
ownership before it can define stable shared error codes.

## Decision

Keep the reasoner store, the reasoner-to-SPARQL snapshot adapter, and
`Memory_Dataset` local to their respective components.  Do not create or
extract `odin-graph` yet.

The candidate minimum graph contract will be reconsidered only after two
production-quality consumers demonstrably use one shared graph representation
for all of the following:

1. one owned RDF term/blank-node identity boundary;
2. graph-scoped default, named, and any-named scan semantics where consumers
   require them;
3. an evidence-backed indexed scan implementation reused by both paths; and
4. one immutable snapshot ownership, bounded-resource, and stable-error
   contract.

The reasoner keeps a copying default-graph Snapshot for bounded
`max_quads` admission and also offers a Store-adopting default-graph Snapshot
for no-copy indexed ownership transfer. Both reject unsupported graph modes
explicitly. Neither is a provisional public graph kernel.

## Released convergence evidence

`odin-reasoner v0.3.0` (`c62ebd8`) includes `indexed_view`, a borrowing `dataset.View`
that calls the reasoner store's indexed `match` path directly.  Its adapter
tests prove that it preserves store-owned term and blank-node identity while
the source store remains alive, rejects named graph modes, and produces the
same public SPARQL query results as the immutable `Snapshot` for its covered
default-graph cases. Its v0.3.0 release-commit CI run is
[30079193793](https://github.com/crapthings/odin-reasoner/actions/runs/30079193793).
Garden now adds a release-pinned RDFS closure comparison using both views.
It also verifies `adopt_store`, which transfers the completed Store into an
immutable Snapshot and preserves its indexed scans after the source handle is
destroyed.

This is useful release-qualified convergence evidence, but it remains a live
borrowed view.  Callers must retain the source `Store` and must not mutate it
during a scan or query. `adopt_store` removes that lifetime restriction by
moving the Store into its Snapshot, but this remains reasoner-specific.
Consequently this release does not yet provide a common graph snapshot,
named/any-named graph semantics, or a unified limit/error model, and it does
not satisfy the extraction gate.

## Consequences

### Positive

- The passing release-qualified integration stays valid without freezing an
  accidental storage representation as a public dependency.
- Blank-node scope and source/snapshot lifetime are now regression-tested at
  the integration boundary.
- Any future extraction has explicit, measurable convergence criteria.

### Costs and risks

- The copied snapshot remains available for compatibility and bounded
  `max_quads` admission, but only the adopted Snapshot retains the existing
  reasoner indexes without a second Dataset copy.
- Named-graph queries cannot be served by this closure adapter until a
  production requirement defines their closure semantics.
- A future shared kernel needs a migration comparison against the existing
  adapter, including result equivalence and limit/error behavior.

## Evidence and rollout

The comparison uses `odin-rdf v0.31.1` (`daa3505`), `odin-reasoner v0.3.0`
(`c62ebd8`), and `odin-sparql v0.1.1` (`fcba9b6`) under the pinned
`dev-2026-07-nightly:ab0131c` Odin compiler. Garden CI run
[30079510562](https://github.com/crapthings/odin-garden/actions/runs/30079510562)
verifies the v0.3.0 release tags and commits, then passes all seven integration
tests, including the Store-adopting Snapshot case.

Re-run `scripts/verify-rdfs-sparql.sh` from Garden whenever any pinned
component, the adapter, or a listed fixture changes.  Revisit this ADR only
with a second consumer path that proves the four convergence criteria above;
then add the corresponding fixture, result-equivalence test, migration plan,
and release note before proposing `odin-graph`.
