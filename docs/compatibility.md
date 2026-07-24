# Compatibility baseline and upgrade policy

## Current baseline

`ecosystem.toml` is the authoritative, machine-readable record for every
Garden integration run. Its initial baseline is intentionally a fixed
**development snapshot**, not a supported release combination:

- `odin-reasoner` has no release tag;
- `odin-rdf` and `odin-sparql` are checked out after their listed releases; and
- the Odin compiler is a development build.

The command in `commands.rdfs_sparql_first_closure` verifies all four exact
identities before executing the fixture. It therefore produces reproducible
implementation evidence, but cannot satisfy the architecture's
release-qualified graph-extraction gate.

## Supported combinations

No release-qualified Garden combination is supported yet. A baseline becomes
supported only when every component entry refers to a published revision,
`release_qualified = true` for each component, and all listed integration
commands pass without local source changes.

## Upgrade procedure

1. Check out the proposed released component revisions in adjacent repositories.
2. Update `ecosystem.toml` with immutable commit IDs, release labels, and the
   compiler identity used for the run.
3. Run every command declared in the manifest, starting with
   `sh scripts/verify-rdfs-sparql.sh`.
4. Review fixture output and any change to RDF term, blank-node, ownership,
   resource-limit, Dataset-view, or error behavior.
5. Record an ADR before accepting behavior changes in those boundaries, then
   mark the compatible entries release-qualified.

Never substitute a branch name such as `main` for a recorded revision. A
failing or unavailable release-qualified run leaves the prior supported
baseline unchanged.
