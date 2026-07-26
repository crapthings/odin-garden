# Local CLI query fixture

This authored fixture fixes the released `odin-cli v0.2.0` query boundary:

```text
local Turtle default graph + local SPARQL Query document
  -> bounded RDF-only SPARQL execution
  -> deterministic stdout + exit status 0
```

`select.rq` proves the default SPARQL Results JSON response and its declared
ascending result order. The JSON document has **no trailing newline**;
`expected-select.json` records its payload and the verifier checks the byte
count separately. `construct.rq` proves the default N-Triples graph result,
including its final LF, against `expected-construct.nt`.

The fixture admits one default graph only. It does not claim named graphs,
Graph, inference, Update, persistence, endpoint service, remote `SERVICE`,
`FROM` fetching, standard input, output files, or network behavior.
