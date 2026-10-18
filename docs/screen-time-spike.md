# Screen Time integration gate

Do not connect a lesson pass to real restrictions until the complete cycle is tested on a child device. Never substitute individual authorization for child authorization.

1. Register an app ID and development team, add Family Controls and an App Group.
2. Add Device Activity Monitor and Shield Configuration targets with matching capabilities.
3. Request `AuthorizationCenter.shared.requestAuthorization(for: .child)` with a parent in Family Sharing.
4. Select monitored apps and exclusions on the child device; keep their opaque tokens local.
5. Atomically persist a cycle ID and policy version for the app and extension.
6. Register a fresh threshold monitor, then release this app's shields after a passing lesson.
7. Apply all eligible application-category shields except exclusions when the threshold arrives.
8. Ignore stale cycle callbacks and grant exactly once per completed lesson.
9. Verify at least three successive cycles, reboot, app termination, offline use, midnight, revoked permissions and recovery.
10. Verify actual behavior for picture-in-picture, background audio and calls; shielding does not force-quit another app.

The current repository intentionally contains no fake timer or simulated successful authorization. No Screen Time extension is shipped yet. Settings cannot be universally shielded. Parent authentication and a recovery path must precede production enforcement.

Sources: https://developer.apple.com/documentation/familycontrols and https://developer.apple.com/documentation/deviceactivity/deviceactivityevent
