# Local CLI validation fixture

This application fixture derives its data and shapes inputs from the authored
[SHACL Core person-record fixture](../../shacl-core/person-record/). It fixes
the first public `odin validate` workflow:

    local Turtle data + local Turtle shapes
      -> bounded SHACL Core validation
      -> one deterministic JSON report on stdout + exit status 1

`expected-report.json` is deliberately a complete byte-level output
expectation, including result order and its final newline. The fixture does
not claim a generic SHACL report-graph serialization, RDFS materialization,
SPARQL execution, named-graph input, persistence, standard input, output
files, or any network behavior.
