# Compatibility baseline and upgrade policy

## Current baseline

`ecosystem.toml` is the authoritative, machine-readable record for every
Garden integration run. The current baseline is a fixed
**release-qualified component combination**: `odin-rdf v0.31.1`,
`odin-reasoner v0.2.0`, and `odin-sparql v0.1.1`. The Odin compiler remains a
pinned development build and is recorded exactly rather than treated as a
moving dependency.

The command in `commands.rdfs_sparql_first_closure` verifies all four exact
identities before executing the fixture. It supplies release-qualified local
integration evidence for the documented RDFS Core default-graph path; it does
not satisfy the separate shared-graph extraction gate.

GitHub Actions runs the same command against those exact component commits in
the `Release-qualified integration` workflow. The workflow installs the pinned
`dev-2026-07` Odin release and recreates the documented adjacent-checkout
layout without following any component branch.

## Supported combinations

The current baseline is supported for its documented local integration path.
Any baseline is supported only when every component entry refers to a published
revision, `release_qualified = true` for each component, and all listed
integration commands pass without local source changes.

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
