# Release-qualified interoperability contracts

This record freezes the cross-project behavior that is exercised by the
`rdfs-sparql-first-closure` baseline in
[`../ecosystem.toml`](../ecosystem.toml).  It is a compatibility commitment
for that pinned release tuple, not a claim that every internal implementation
type is a general ecosystem API.

The contract is intentionally narrower than a future shared graph, validation
layer, or rule-exchange format.  Each item below names its owner and the
evidence which must change with it.

## 1. RDF term identity and ownership

`odin-rdf:rdf` owns the syntax-independent `Term`, `Triple`, and `Quad`
model.  Across the current RDF, Reasoner, and SPARQL paths, RDF-term equality
means:

| Term kind | Identity fields |
| --- | --- |
| IRI | kind and lexical IRI string |
| Literal | kind, lexical form, datatype IRI, and language tag compared ASCII case-insensitively |
| Blank node | kind, label, and non-zero source scope |

Blank-node labels are not global identifiers.  One parser call gives repeated
labels one non-zero scope; equal labels from separate parser calls have
different scopes and therefore do not co-refer.  The zero scope is reserved
for explicitly caller-managed terms and must not be used to merge parser
documents accidentally.

Term strings received by a parser sink are borrowed for only the callback.
Any component retaining them must copy or intern them.  The Reasoner does this
on insertion; copied and Store-adopting snapshots own their data; a live
indexed View borrows its source Store.  Terms yielded by a Dataset View remain
borrowed until the lifetime documented by that View's owner.

There is no cross-project public term-hash API to freeze.  A dictionary or
index may choose its own hashing, but it must deduplicate exactly according to
the identity above.  Any change to the equality fields, language comparison,
blank-node scope, or retained-term lifetime is a semantic change rather than
an internal optimization.

**Evidence:** the release-qualified
[`blank-node boundary`](../fixtures/rdfs-core/blank-node-boundary/) and
[`cross-ingestion boundary`](../fixtures/rdfs-core/cross-ingestion-blank-node/)
fixtures, plus the corresponding `integration/rdfs_sparql` tests.

## 2. Read-only query and snapshot boundary

`odin-sparql:sparql/dataset.View` is the read-only query boundary.  Its scan
is synchronous; a sink returning `false` is a successful early stop, not a
storage error.  Adapters must preserve RDF-term equality and graph scope while
a scan or query is running.

The current baseline deliberately has two distinct behaviors:

| Provider | Supported graph modes | Lifetime and ownership |
| --- | --- | --- |
| `dataset.Memory_Dataset` | Default, Named, and Any_Named after sealing | Its View borrows a sealed, owned dataset. |
| Reasoner `sparql_adapter` Snapshot or `indexed_view` | Default only; Named and Any_Named return `dataset.Invalid_View` | A copied Snapshot owns copied terms; `adopt_store` transfers the finished Store; `indexed_view` borrows a live, unmodified Store. |

The Reasoner adapter must never reinterpret a named-graph request as a
default-graph request.  A copied Snapshot's `max_quads` admission is atomic:
`Quad_Limit` leaves no incomplete snapshot.  Store adoption is permitted only
after materialization is complete; it resets the source Store and the adopted
Snapshot becomes its owner.

**Evidence:** the release-qualified
[`default-graph boundary`](../fixtures/rdfs-core/default-graph-boundary/)
fixture and the first-closure SELECT, ASK, and CONSTRUCT tests.  These prove
the boundary, not a common storage representation or a shared mutable graph
API.

## 3. Materialization, rule identity, and provenance

`odin-reasoner` owns the bounded rule engine and the RDFS/OWL profile tables.
The active rule contract is observable at the profile boundary:

- `rule.Rule_ID` is caller- or profile-supplied and is recorded with every
  first-support derivation; the Garden RDFS fixture checks the four profile
  rule IDs that actually derive new facts.
- A derivation exposes one inferred fact ID, one rule ID, and ordered supporting
  fact IDs.  These IDs are local to the owning Store/Profile and its documented
  borrowed lifetime; they are not portable RDF identifiers.
- Re-inserting an existing fact is a successful set-semantics no-op.  The
  first insertion's asserted/inferred origin is retained.
- Configured fact, round, and derivation limits produce explicit errors and do
  not commit a partial materialized closure.  Allocation failure remains an
  explicit operational error, not a broader transaction guarantee.

The public `reasoner/rule` package is a bounded, in-process Rule IR for the
Reasoner.  This record does **not** promote it to a cross-language rule
serialization, a general policy language, or a universal public protocol.  A
future SWRL front end may compile to it only after a dedicated profile,
resource limits, and end-to-end fixture are agreed.

**Evidence:** the
[`first-closure`](../fixtures/rdfs-core/first-closure/) fixture, its expected
derivations, and the RDFS-to-SPARQL integration gate.

## 4. Validation reports are deferred, not implicit

The current Reasoner can expose bounded OWL consistency evidence, but that is
not a SHACL validation-report model.  No Garden-supported public validation
report exists yet.  A future SHACL slice must define its own result identity,
severity, paths, source-shape/source-constraint fields, ownership, limits, and
serialization before it can be release-qualified.

Likewise, provenance records explain the first support for an inferred fact;
they are not validation results and must not be presented as such.

## Change gates

The required evidence for a change is authoritative in the
[semantic change policy](change-policy.md).  In practical terms:

| Proposed change | Required gate(s) |
| --- | --- |
| Term identity, normalization, or retained strings | Component tests; both blank-node Garden fixtures; an ADR and migration note when identity changes. |
| Snapshot/View lifetime, scan behavior, graph scope, or limits | Dataset/adapter tests; default-graph fixture; SELECT/ASK/CONSTRUCT gate; adapter documentation. |
| Materialization meaning, profile rule IDs, origins, or provenance | Reasoner rule/profile tests; first-closure expected derivations; an ADR for semantic reinterpretation. |
| New validation or rule-authoring surface | A new bounded profile document and dedicated Garden fixture before a component is called supported. |

After any accepted semantic change, update the release-qualified tuple only
when the exact component releases and every affected Garden command pass.
