# Proposed bounded SHACL Core validation contract

This document defines the contract to be release-qualified with the first
`odin-shacl` release. It does not amend the already-supported
RDFS-to-SPARQL tuple in `ecosystem.toml`; that tuple continues to defer a
public validation layer until the new component's exact release and Garden gate
have passed.

## Ownership and graph boundary

`odin-rdf:rdf` owns `Term` and `Triple` identity. `odin-shacl` borrows two
default-graph triple slices for one validation call and never keeps them or
mutates either graph. It has no dependency on a graph store, SPARQL, Reasoner,
filesystem, or network transport.

The returned report owns all result terms. It remains valid after the input
parser buffers, RDF collector, and optional upstream Reasoner snapshot have
been destroyed. An error produces an empty report; a completed non-conforming
validation returns success with `conforms = false`.

## Profile and report model

The first profile is the narrow public surface documented by
[`odin-shacl`](https://github.com/crapthings/odin-shacl): explicit
`sh:NodeShape`, `sh:targetClass`, simple IRI property paths, `sh:minCount`,
`sh:maxCount`, `sh:datatype` for `xsd:string`/`xsd:integer`, and `sh:nodeKind`
for IRI/blank-node/literal values. Target-class selection follows the explicit
`rdfs:subClassOf` hierarchy in the supplied data graph; validation does not
perform RDFS or OWL materialization.

Each result exposes a focus node, result path, optional value node, source
property shape, source constraint component, and the fixed default severity
`sh:Violation`. The results are ordered deterministically by focus node, path,
component, source shape, and value.

Unsupported SHACL semantics, malformed shapes, invalid RDF, allocation
failure, and every configured resource limit are errors. No unsupported shape
may be treated as a successful validation. Complex paths, other Core
components, custom severity/message policy, recursive/nested shapes,
SHACL-SPARQL, JavaScript, rules, and extensions are outside this profile.

## Evidence required for qualification

The [`person-record`](../fixtures/shacl-core/person-record/) fixture defines
the profile's first end-to-end report. The qualifying Garden command must:

1. parse the pinned data and shapes graphs with `odin-rdf`;
2. run the exact released `odin-shacl` profile;
3. destroy input ownership before inspecting the report; and
4. assert `conforms`, result count, every result field, report ordering, and
   an unsupported-construct error case.

Any change to target selection, constraint interpretation, result identity,
ordering, ownership, resource limits, or error codes requires the component
tests, this fixture, and a release-qualified Garden run to be updated together.
