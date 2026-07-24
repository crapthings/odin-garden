# Default-graph boundary fixture

This fixture contains two default-graph triples. It first tries to create a
snapshot with `max_quads = 1`, which must fail with `Quad_Limit` and leave no
partial snapshot. It then creates an unbounded snapshot, destroys the source
store, and verifies the external Dataset view behavior.

Only default-graph scans are supported. A normal sink early-stop is successful,
while `Named` and `Any_Named` scan requests return `dataset.Invalid_View` rather
than being silently reinterpreted as default-graph scans.
