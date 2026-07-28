# Store operational workload contract

Status: experimental contract for the independent `odin-store` alpha. It is
not a promise that Garden has a shared graph or production storage runtime.

## Purpose and boundary

This contract describes a local application that has already validated its
input and needs to atomically preserve RDF facts with the operational lineage
needed to audit them later. It is intentionally vocabulary-neutral: Store
does not parse SKOS or another ontology, call a model, read source files,
chunk text, resolve entities, or choose a winning review state.

Applications retain source bytes, prompts, model outputs, and domain policy.
They may submit only caller-selected locators, hashes, byte ranges, explicit
RDF facts, and explicit review inputs. Store must not turn a locator or an
application label into semantic authority.

## Atomic generation

One committed generation contains both planes or neither:

1. RDF Dataset memberships and exact provenance occurrences.
2. Operational records: document versions, locators, ordered chunks,
   extraction attempts, evidence links, and append-only review decisions.

Every visible Snapshot is one complete generation. Reopen must verify the
selected closure and reject corrupt, unknown, or unsupported state rather than
repair or reinterpret it.

## Required behavior

| Phase | Required observable behavior |
| --- | --- |
| W1 | Admit a document identity, an allowed locator, ordered chunks, and candidate RDF atomically. |
| W2 | Replaying the exact document/chunk/profile/config attempt is idempotent. |
| W3 | An alternative locator for the same document identity does not create a second document version. |
| W4 | Changed source bytes create a distinct document version and do not overwrite prior lineage. |
| W5 | Evidence links ground a specific RDF membership in explicit document, chunk, and attempt records. |
| W6 | Closing and freshly reopening every published generation preserves the verified semantic and operational closure. |
| W7 | A caller-provided approve, reject, or relate decision is append-only; it never deletes candidate facts or infers a final review status. |
| W8 | At each durable-commit crash point, a fresh open exposes either the prior complete generation or the new complete generation, never a partial mixture. |

The exact source vocabulary, candidate graph naming, canonical graph policy,
and review-file format remain application concerns. A Store API may expose
immutable events and exact lookup paths, but it must not add automatic merge,
inference, label normalization, or source-content retention under this
contract.

## Compatibility posture

The current alpha is local, single-writer, and Darwin-only. It is not an
ecosystem compatibility baseline. Before Garden records a release-qualified
Store combination, a proposed release must pin its public API and format,
declare its platform support, and pass a reproducible W1–W8 gate without
private source material.
