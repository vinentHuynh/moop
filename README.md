# moop

An initial SwiftUI math-learning prototype for a planned parent-controlled learning and app-access system. **This version does not block apps and is not a parental-control product yet.**

## Implemented

- Modular addition, subtraction and multiplication lesson counts.
- Generated question definitions with stable IDs; correct answers calculated at runtime.
- Parent-configurable passing percentage with ceiling-based required score.
- First-answer grading, results and correction review.
- Local atomic JSON persistence of plan, current lesson and completed history.
- Resume after closing the app; immutable active lesson plan snapshot.
- Pure Swift package with tests; macOS CI tests and builds the iOS prototype.
- Kid-friendly interface: mascot, mission card, in-app number keypad, per-answer feedback, optional counting dots, celebration and "so close" results, a weekly star tracker, and a press-and-hold grown-ups check in front of the plan editor.

The press-and-hold grown-ups check only keeps young children out; it is not a security lock. The plan editor has no parent PIN, account or remote permissions yet. The configured usage allowance does not grant or meter actual device access.

## Run on a Mac

Requires Xcode 15 or newer and iOS 17 or newer. Install XcodeGen using `brew install xcodegen`, then:

```sh
swift test
xcodegen generate
open Moop.xcodeproj
```

Select the Moop scheme and an iPhone simulator. For a physical device, set your development team and a unique bundle identifier. No AWS credentials or Screen Time entitlements are needed for this learning prototype.

## Storage

The prototype stores one versioned JSON snapshot in Application Support. Corrupt or unsupported data is preserved and writes are blocked rather than silently replacing it. This is a temporary local adapter; migrate it to SwiftData before scaling the history or implementing the upload outbox.

Target architecture: bundled catalog and SwiftUI illustrations; DynamoDB for remote plans, custom text/numeric content, attempts and derived progress; Cognito Lite; HTTP API Gateway and Lambda. No S3 initially. No cloud infrastructure has been deployed.

## Next engineering gate

See [Screen Time spike](docs/screen-time-spike.md) and [roadmap](docs/roadmap.md). Build and validate child authorization, application exclusions and repeated usage-threshold cycles on real family devices before enabling restriction controls in the product.

## Validation

The authoring environment has no Swift compiler or Xcode. GitHub Actions is configured to run the Swift tests and simulator build; check its results before relying on build compatibility. Device enforcement, remote synchronization and AWS integration are not implemented.

## License

See the existing [Apache 2.0 license](LICENSE).
