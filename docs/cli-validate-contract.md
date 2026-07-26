# Local CLI validation contract

This contract defines the first application-layer workflow qualified by
Garden. It covers `odin-cli v0.1.0` over the released `odin-rdf v0.33.0`
and `odin-shacl v0.1.0` components. It does not expand their RDF or SHACL
public contracts.

## Qualified workflow

The command accepts exactly two ordinary local Turtle paths and bounded
positive limits:

    odin validate --data DATA.ttl --shapes SHAPES.ttl
      [--max-data-triples N]
      [--max-shapes-triples N]
      [--max-statement-bytes N]
      [--max-results N]

It parses each file through the released RDF parser, keeps bounded
application-owned copies, calls the released bounded SHACL profile, releases
both input collections, and only then renders the report that the validator
owns. One completed validation writes exactly one newline-terminated,
deterministic JSON object to standard output.

Exit code 0 means conforming data. Exit code 1 means validation completed with
one or more violations. Exit code 2 means argument, local I/O, Turtle,
configured-limit, unsupported/malformed-shape, allocation, or output failure;
that path emits no partial JSON report.

The `odin-cli-validate-person-record` fixture pins a non-conforming
invocation to a full JSON byte sequence, result order, fixed limits, and exit
code 1. The qualifying verifier also rejects diagnostic output on its completed
validation path.

## Explicit boundary

Version 0.1 has no standard-input admission, output-file option, RDF syntax
selection, remote context, URL loading, HTTP or other network activity,
inference, SPARQL, named-graph input, persistence, server process, or
authentication behavior. It does not turn the SHACL report into an RDF report
graph or promise any profile beyond the documented bounded Core subset.

Any change to argument interpretation, local-file admission, resource limits,
term JSON rendering, report order, exit status, diagnostic behavior, or
component pin requires an `odin-cli` release, an updated application fixture,
and a successful Garden application gate.
