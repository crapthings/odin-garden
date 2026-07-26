# Local CLI query contract

This release-qualified application contract covers `odin-cli v0.2.0` over
`odin-rdf v0.33.0`, `odin-sparql v0.7.0`, and the CLI's released
`odin-shacl v0.1.0` compile-time dependency. It is an application composition
record; it does not expand the public RDF, SHACL, or SPARQL contracts.

## Qualified workflow

```text
odin query --data DATA.ttl --query QUERY.rq
  [--format auto|json|xml|csv|tsv|nt|turtle]
  [--max-data-triples N]
  [--max-statement-bytes N]
  [--max-query-bytes N]
  [--max-results N]
```

The command accepts one ordinary local Turtle file as its default graph and one
ordinary local SPARQL Query document. Every limit is a positive decimal
integer. The qualified fixture supplies explicit limits of 8 data triples,
1024 statement bytes, 512 query bytes, and 8 materialized solutions.

The CLI parses Turtle through RDF, copies accepted triples into SPARQL v0.7's
bounded RDF-only `Memory_Dataset`, releases the parser-owned input, seals the
Dataset, then executes one query over its read-only View. `auto` writes SPARQL
Results JSON for SELECT and ASK, and N-Triples for graph results. A completed
query, including an empty result, exits 0; command, input, limit, parse,
execution, and serializer failures exit 2 without partial standard output.

`odin-cli` compiles its `validate` command into the same executable, so this
Garden build pins SHACL v0.1. It does **not** mean query execution invokes
SHACL. The query execution path uses only RDF and SPARQL's released core
Dataset; no Graph checkout, collection, or import is allowed by the gate.

## Fixed evidence

`odin-cli-query-local-friends` is an authored two-triple default graph. Its
SELECT query checks the default JSON binding document and deliberately verifies
that it has no terminal newline. Its CONSTRUCT query checks byte-exact
N-Triples with the terminal LF required by that representation. Both successful
queries must be quiet on standard error and return exit 0.

The fixture and verifier add no new cross-project semantic decision; they apply
the RDF-only SPARQL boundary accepted in [ADR 0006](adr/0006-qualify-sparql-v0-7-without-graph.md)
to the separately released CLI application surface.

## Explicit boundary

Version 0.2 admits no standard input, named-graph input, RDF syntax selection,
remote context, URL loading, HTTP, `FROM` fetching, remote `SERVICE` resolver,
inference, SPARQL Update, persistence, output files, server process, or
authentication behavior. It is not an endpoint, graph store, or general query
hosting contract.

Any change to argument interpretation, local-file admission, limits, Dataset
ownership, result format/order, terminal bytes, exit status, diagnostic
behavior, or component pin requires an `odin-cli` release, an updated fixture,
and a successful Garden application gate.
