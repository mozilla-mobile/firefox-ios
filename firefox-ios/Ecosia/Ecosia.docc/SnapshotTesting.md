# Snapshot testing — Ecosia iOS

SnapshotTestHelper is used to capture UI snapshots and compare them against reference images across themes, locales and devices.

Quick run

- Run the snapshot test plan in Xcode under the `EcosiaBeta` scheme (Cmd+U).
- See `SNAPSHOT_TESTING_WIKI.md` in the repo for full instructions.

Notes

- Snapshots rely on deterministic data. If a snapshot intentionally changes, update the reference image(s) in a focused PR.
- The test helper supports multiple device configurations and locales; prefer small, focused snapshot diffs.