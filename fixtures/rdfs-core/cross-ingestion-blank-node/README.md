# Cross-ingestion blank-node identity fixture

`source.ttl` is parsed twice into one reasoner store. Each parser call creates
a distinct non-zero blank-node scope, so identical lexical `_:same` labels do
not become one fact. The snapshot therefore contains two quads.

After the source store is destroyed, SPARQL SELECT returns two blank-node
bindings. They share lexical label `same` but have different non-zero scopes.
This is the negative counterpart to the single-document blank-node fixture:
same document scope co-refers; separate parser calls do not.
