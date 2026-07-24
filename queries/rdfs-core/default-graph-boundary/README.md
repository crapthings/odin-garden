# Scan expectations

This adapter-boundary fixture intentionally verifies the public
`sparql/dataset.scan` contract rather than a query form.

| Operation | Expected result |
| --- | --- |
| Default-graph scan with a false-returning sink | Success and exactly one sink call |
| `Graph_Mode = Named` | `dataset.Invalid_View` |
| `Graph_Mode = Any_Named` | `dataset.Invalid_View` |
