# Blank-node boundary fixture

The same `_:same` label is used twice in one Turtle document. The parser assigns
one non-zero document scope; the reasoner accepts the first triple and treats
the second as a duplicate under its triple set semantics.

The test copies that one fact into a snapshot, destroys the source store, then
executes SELECT and ASK through the SPARQL view. It verifies the SELECT binding
is still a blank node with the same lexical label and a non-zero scope.

This fixture does **not** claim that equal blank-node labels from two parser
calls or two source documents co-refer. That would require an explicit
cross-ingestion contract and a separate fixture.
