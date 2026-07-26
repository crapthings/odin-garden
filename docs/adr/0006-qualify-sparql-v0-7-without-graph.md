# ADR 0006: Qualify SPARQL v0.7.0 through its RDF-only public boundary

- Status: Accepted
- Date: 2026-07-26
- Supersedes: ADR 0005's temporary post-v0.2 release deferral

## Context

ADR 0005 correctly stopped a post-v0.2 SPARQL release while its public
`Memory_Dataset` appeared to require an unqualified `odin-graph` checkout.
That would have made experimental Graph source part of an otherwise public
release without a fixed support contract.

`odin-sparql v0.7.0` changes that boundary deliberately. Its public
`sparql/dataset.Memory_Dataset` now owns its bounded RDF Dataset set directly
and imports only `odin-rdf`. The optional `sparql/graph_dataset` package is a
separate adapter and contract-test surface; it is not an input to the core
release verifier or a requirement for applications that use Memory_Dataset or
`dataset.custom_view`.

The existing RDFS closure tuple remains valuable fixed evidence for
`odin-sparql v0.2.0`, `odin-reasoner v0.6.0`, and experimental Graph. It is
not rewritten retroactively into evidence for the larger v0.7.0 API.

## Decision

1. Add a separate release-qualified `sparql-core-v0.7` Garden baseline with
   exactly `odin-rdf v0.33.0` and `odin-sparql v0.7.0`.
2. Its gate verifies release tags, compiler identity, default/named graph
   behavior of Memory_Dataset, and execution over an application-owned
   `custom_view`. The command has no Graph checkout or import.
3. Keep Graph as an optional experimental adapter. Its development convergence
   evidence may evolve separately, but it neither qualifies nor blocks the
   core SPARQL tag.
4. Retain the older RDFS-to-SPARQL-and-Graph row unchanged until a separately
   reviewed fixed version tuple is proposed for it.

## Consequences

- Applications may pin and consume the v0.7 core Dataset boundary using only
  the released RDF and SPARQL tags.
- This does not make Graph a supported common runtime, prove a no-copy
  Reasoner/Graph representation, or create a store requirement.
- An updated Reasoner-to-SPARQL release tuple requires its own candidate,
  fixed-version Garden gate, and compatibility review.
