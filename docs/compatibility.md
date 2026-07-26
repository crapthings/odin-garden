# Compatibility baseline and upgrade policy

## Current baselines

`ecosystem.toml` is the authoritative, machine-readable record for every
Garden integration run. It contains three fixed **release-qualified component
combinations**. The RDFS-to-SPARQL baseline pins `odin-rdf v0.32.1`,
`odin-reasoner v0.6.0`, `odin-sparql v0.2.0`, and the experimental
`odin-graph v0.1.0`. The separate SHACL validation baseline pins
`odin-rdf v0.33.0` and `odin-shacl v0.1.0`. The local CLI application baseline
adds `odin-cli v0.1.0` to that released pair and fixes its JSON report and exit
status. The Odin compiler remains a pinned development build and is recorded
exactly rather than treated as a moving dependency.

The command in `commands.rdfs_sparql_first_closure` verifies all four exact
identities before executing the fixture. It supplies release-qualified local
integration evidence for the documented RDFS Core default-graph path; it does
not satisfy the separate shared-graph extraction gate.

GitHub Actions runs the same command against those exact component commits in
the `Release-qualified integration` workflow. The workflow installs the pinned
`dev-2026-07` Odin release and recreates the documented adjacent-checkout
layout without following any component branch.

`commands.shacl_core_person_record` similarly verifies the exact RDF and SHACL
tags before parsing the fixture's data and shapes graphs. It proves a bounded,
owned validation report only; it is not an inference, query, named-graph, or
shared-store compatibility claim.

`commands.odin_cli_validate_person_record` verifies all three exact tags and
runs the local command over the same authored input graphs. It compares the
complete machine-readable report and checks exit status 1, so it proves the
command boundary without exposing a component's internal API or implying a
network, service, or storage layer.

`commands.odin_cli_wikidata_south_africa_capital_selection` uses the same
released tuple but a separately versioned public-source application fixture.
It proves that a source fact excerpt is preserved while a consumer-owned
single-select policy is enforced; it neither declares the source erroneous nor
chooses a value.

## Supported combinations

The current baseline is supported for its documented local integration path.
Any baseline is supported only when every component entry refers to a published
revision, `release_qualified = true` for each component, and all listed
integration commands pass without local source changes.

## Upgrade procedure

1. Check out the proposed released component revisions in adjacent repositories.
2. Update `ecosystem.toml` with immutable commit IDs, release labels, and the
   compiler identity used for the run.
3. Run every command declared for the affected baseline in the manifest, such
   as `sh scripts/verify-rdfs-sparql.sh`, `sh scripts/verify-shacl.sh`, or
   `sh scripts/verify-cli-validate.sh` or
   `sh scripts/verify-cli-wikidata-capital-selection.sh`.
4. Review fixture output and any change to RDF term, blank-node, ownership,
   resource-limit, Dataset-view, or error behavior.
5. Record an ADR before accepting behavior changes in those boundaries, then
   mark the compatible entries release-qualified.

Never substitute a branch name such as `main` for a recorded revision. A
failing or unavailable release-qualified run leaves the prior supported
baseline unchanged.
