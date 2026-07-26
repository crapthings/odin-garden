# Local real-data validation intake

Use this intake before running `odin validate` on business or otherwise
non-public data. It is intentionally a local workflow: completing this document
does not authorize uploading data, adding it to Garden, or treating a source
violation as a source-data error.

The data owner, or someone with explicit authority from that owner, must
provide the following record. Do not commit the completed form if it contains
confidential identifiers, internal paths, customer names, or other sensitive
material.

## Authorization record

```
Data owner / authorizing person:
Purpose of this validation:
Exact local input path:
Input format and approximate size:
Data classification (public / internal / confidential / regulated):
Retention and deletion expectation:
May a redacted aggregate result be committed? (yes/no):
May a synthetic or anonymized regression fixture be created? (yes/no):
```

If the input is not explicitly authorized, stop. Garden does not assume that a
file found on disk may be inspected, parsed, committed, or sent to a service.

## Application policy record

```
Record class or admission rule:
Required properties and cardinalities:
Accepted value kinds / datatypes:
Interpretation of each violation:
Who decides remediation:
Expected feedback path to the source owner:
```

Keep the policy separate from assertions about the source. For example, a
single-value import field can reject an otherwise valid multi-value source
fact; this tells the product to choose a policy, not the data steward to delete
facts.

## Local execution

Use only local file paths and released components. A completed validation
returns exit 0 for conformance, exit 1 for a deterministic violation report,
and exit 2 for an operational or profile error.

```
odin validate --data /absolute/path/data.ttl --shapes /absolute/path/shapes.ttl
```

Set explicit triple, statement-byte, and result limits appropriate to the
authorized input. Do not use standard input, URL loading, remote context,
network access, output files, inference, SPARQL, persistence, or a server as
part of this intake workflow.

## Safe evidence record

Keep raw data and full reports local unless their owner explicitly approves
publication. For Garden, record only:

- component versions and compiler revision;
- the authorization category, not private identities;
- input size and configured limits;
- conforming/violation/error outcome and aggregate result counts;
- redacted constraint categories; and
- the agreed remediation or reason no remediation is required.

Create a Garden fixture only when the data, source license, and report evidence
may be shared. Otherwise, a private run record remains external to this
repository.

## Decision gate after the run

Choose at most one next change, and only if the local record proves it is
needed:

| Observed need | Eligible next path |
| --- | --- |
| A required constraint cannot be expressed by the bounded profile | C1: one small SHACL profile extension |
| Users need local RDF inspection beyond validation | C2: read-only local query command |
| Domain authors require a new inference rule | C3: minimal front end to existing Rule IR |
| Two consumers need the same snapshot/index/identity contract | C4: graph/store extraction gate |
| Deployment, authentication, or concurrency is required | C5: server/API design gate |

No observed gap means no new component: retain the released baseline and the
local evidence record.
