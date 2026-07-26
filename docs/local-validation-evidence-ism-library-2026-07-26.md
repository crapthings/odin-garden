# Local Ism Library graph-navigation validation evidence — 2026-07-26

## Scope and publication boundary

This is an aggregate-only record of a local evaluation of the user-owned public
[`crapthings/ism-library`](https://github.com/crapthings/ism-library) content
repository at commit `57b0a8fc242c13e57e886a8edc68a9a509270048`. It is not a
Garden fixture, a release-qualified CI gate, or a statement about the truth of
the source content.

The repository README names the MIT license while its package metadata declares
ISC. At the time of review, there was no `LICENSE` file and the repository
license metadata was unset. Until the owner resolves that discrepancy, Garden
must not copy source modules, generated RDF, or complete reports into this
repository. The local clone, generated inputs, and complete report are not
published here.

## Local application policy

The evaluation used a temporary, application-owned RDF projection of the
content entries. The projection preserved only the structure needed to test
navigation; it did not infer or synthesize relationships.

The policy has two independent parts:

1. Every entry has one string title, one string quotation, and four to six
   structured sections.
2. Every entry intended for graph navigation has at least one IRI-valued
   curated `related` link. A violation means the entry needs a product/content
   decision; it does not mean its ideas or source material are invalid.

## Redacted aggregate result

The local importer loaded all 113 modules successfully and projected 113
entries with 628 sections.

| Local check | Projected triples | Outcome |
| --- | ---: | --- |
| Structural policy | 3,966 | Conforms: exit 0, zero results |
| Graph-navigation policy | 4,191 | Exit 1: 25 deterministic `minCount` results |

For the navigation policy, 88 entries supplied 225 explicit related-link
edges. The remaining 25 entries had no such edge. The completed command
produced no diagnostics; the 25 results were all the expected minimum-count
category. The run used released `odin-rdf v0.33.0` (`eac24a8`),
`odin-shacl v0.1.0` (`4ee8249`), and `odin-cli v0.1.0` (`63c639e`) with Odin
compiler `dev-2026-07-nightly:ab0131c`.

## Decision and follow-through

The bounded SHACL profile expresses this policy without a change to Odin.
Garden will therefore not begin C1, C2, C3, C4, or C5 from this record.

The content owner should choose a policy for the 25 entries:

1. author one or more curated related links;
2. explicitly designate an entry as standalone/exempt; or
3. provide a UI fallback that does not require graph navigation.

Do not automatically infer links from shared words, titles, or categories, and
do not represent an absent curated link as a content error. After the owner
chooses the policy and resolves the repository license declaration, rerun the
same local aggregate check. A shareable regression fixture is a separate
decision under the [fixture policy](fixture-policy.md).
