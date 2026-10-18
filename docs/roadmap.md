# Development roadmap

## Current vertical slice

Three arithmetic skills, exact lesson allocation, runtime evaluation, scoring, correction review and resumable local history. Catalog IDs align with the product plan: ADD02, SUB02 and MUL04. These are the only currently implemented skills, not the full grades 2–7 curriculum.

## Next

- Complete the real-device Screen Time spike before promising enforcement.
- Add protected parent access, separate device roles and pairing.
- Replace the prototype JSON persistence with SwiftData and an idempotent upload outbox; migrate existing history.
- Define the 100-skill catalog and add validated generators progressively, including digit widths, carrying, borrowing and fraction renderers.
- Support hints with an explicit scoring policy and worked explanations.
- Introduce immutable weekly assignments and parent-authored template configurations/custom questions.
- Implement Cognito Lite authentication and scoped child-device credentials.
- Implement HTTP API/Lambda and a single DynamoDB table. Keep generated answer keys derived, not stored.
- Add policy acknowledgements, offline behavior, parent overrides and per-skill progress aggregation.
- Add FSRS within parent-selected skill allocations after stable review histories exist.

## Storage contract

Record question ID, skill/template/evaluator version and operands; retain the child's submitted answer, correctness, hints when supported, and timestamps. Generated answers are evaluated at runtime. Custom non-template questions require an explicit answer key. Immutable attempts are the source of truth; skill summaries are rebuildable. Preserve historical evaluator versions and original outcomes when correcting an evaluator bug.

More combinations or supported template parameters do not require a new interaction. New renderers/evaluators require an app release. No image uploads or S3 are in the initial architecture.

## Non-goals of this initial commit

No deployed AWS resources, subscription functionality, production authentication, app blocking, usage tracking, remote synchronization or automatic skill advancement. Parent settings control progression; the child cannot change them in the eventual production flow.
