# First RDFS Core closure fixture

This is an authored, CC0-1.0 fixture. Its provenance and semantic boundary are
recorded in `fixture.toml`; it is deliberately small enough to audit by hand.

`source.ttl` has seven asserted triples. The expected closure has seven new
triples, in `inferred.nt`:

- subclass transitivity derives `Person rdfs:subClassOf Entity`;
- subclass application derives `ada a Agent` and `ada a Entity`;
- subproperty application derives `ada relatedTo bea`; and
- range derives `bea a Person`, then subclass application derives `bea a Agent`
  and `bea a Entity`.

The domain conclusion `ada a Person` is already asserted, so it remains a
duplicate rather than another inferred fact. The integration test checks the
four rule IDs that yield new facts and thus have first-support provenance.

The fixture is default-graph only. The same test confirms that the adapter
rejects named-graph scans instead of silently changing graph scope.
