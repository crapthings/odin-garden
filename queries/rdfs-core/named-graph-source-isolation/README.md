# Named source-graph isolation queries

`exact-source-a.rq` verifies exact named-graph selection. `all-sources.rq`
verifies `GRAPH ?source` binds only named graph names and preserves each
source's result. `default-does-not-leak.rq` must return `false`, because its
triple exists only in source A's named graph.
