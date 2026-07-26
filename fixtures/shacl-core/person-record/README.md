# Person-record SHACL Core validation fixture

This is an authored CC0-1.0 validation fixture. It represents a small import
quality gate: each `ex:Person` must have exactly one IRI-valued `ex:email` and
exactly one integer `ex:employeeId`.

`data.ttl` contains three focus nodes:

- `ex:ada` conforms;
- `ex:bea` has a literal email and a string employee ID; and
- `ex:cora` reaches `ex:Person` through `ex:Worker rdfs:subClassOf ex:Person`,
has no email, and has two employee IDs.

The expected report has four deterministic results: NodeKind and Datatype for
Bea, then MinCount and MaxCount for Cora. `expected-report.toml` records the
report fields independently from any future report-serialization syntax.

The fixture validates a supplied immutable graph. It does not ask SHACL to
materialize a closure; the class relation is deliberately present in the data
to exercise the profile's documented `targetClass` behavior.
