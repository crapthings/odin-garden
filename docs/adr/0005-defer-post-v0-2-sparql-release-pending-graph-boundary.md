# ADR 0005: Defer a post-v0.2 SPARQL release pending an explicit Graph boundary

- Status: Accepted
- Date: 2026-07-26

## Context

Garden's release-qualified tuple continues to pin `odin-rdf v0.33.0`,
`odin-reasoner v0.6.0`, and `odin-sparql v0.2.0`. `odin-shacl v0.1.0` and
`odin-cli v0.1.0` independently qualify the local validation path.

The current development heads have more capability than those tags. Reasoner's
post-v0.6 work adds bounded OWL RL profile behavior and conformance evidence
while its core still depends only on `odin-rdf`. SPARQL's post-v0.2 work changes
the public `sparql/dataset` implementation to own `odin-graph:graph`; its
`graph_dataset` package also uses the Graph-to-SPARQL adapter. Its release
verifier requires an adjacent `odin-graph` checkout.

`odin-graph v0.1.0` is explicitly an experimental Garden baseline, not an
independently supported public API. Current-source convergence proves SPARQL
uses Graph directly and that a Reasoner closure can be copied into it, but the
Reasoner Store does not share Graph's identity, indexes, or lifecycle at
runtime. There is not yet a second no-copy production-quality consumer of the
Graph contract.

Publishing a new SPARQL tag without resolving that dependency would make an
undeclared moving Graph source revision part of the effective release. It would
contradict the Garden rule that release evidence does not follow `main`.

## Decision

1. Retain the current Garden release-qualified tuple; do not advance it to
   development heads merely because their local evidence passes.
2. Do not publish a post-v0.2 `odin-sparql` release while its public Dataset
   packages require an unqualified `odin-graph` checkout.
3. Before proposing such a release, make one explicit delivery decision and
   prove it in Garden:
   - establish a reviewed, versioned Graph support contract and a fixed
     co-release input; or
   - make SPARQL's released public Dataset boundary independent of Graph and
     keep Graph as a development-only implementation detail.
4. Keep `odin-graph` experimental. A Graph/store extraction or public support
   promise still requires its existing multi-consumer, ownership, identity,
   resource-limit, and migration gates.
5. `odin-reasoner` may undergo a separate pre-1.0 release assessment because
   its core boundary is `odin-rdf`; its optional SPARQL/Graph adapters are not
   a reason to release or block a core tag by themselves.

## Consequences

- No new tags, Garden pins, or capability claims follow from this ADR alone.
- The current-source Graph convergence command remains development evidence;
  it never substitutes for a fixed-revision release gate.
- A real consumer that needs the post-v0.2 SPARQL Dataset becomes the trigger
  for choosing one delivery boundary. A release owner may separately request a
  Reasoner release assessment with its documented profile and CI evidence.
- `odin-store`, transactions, SPARQL Update, server work, and a generic
  vocabulary repository remain out of scope.
