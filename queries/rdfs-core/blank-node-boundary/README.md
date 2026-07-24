# Query expectations

Both queries execute after the parser input and reasoner store have been
destroyed, while the immutable snapshot remains alive.

| Query | Expected result |
| --- | --- |
| `select-subject.rq` | One bound blank-node subject with lexical label `same` and non-zero scope |
| `ask-knows.rq` | `true` |
