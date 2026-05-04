# 7. Deeplink Startup Flow Refactor

Date: 2026-04-22

## Status

Proposed

## Context

When the app launches via a deeplink (e.g. from a push notification or external URL), two competing operations race: handling the deeplink and restoring the previous tab session. The old approach serialised these by blocking deeplink handling until tab restoration finished. This caused measurable startup latency and made the code path difficult to reason about, as `isRestoringTabs` and `tabRestoreHasFinished` booleans were scattered across multiple classes. An `AppEventQueue.tabRestoration` event was also used to coordinate timing across the stack, adding another layer of state that callers had to account for.

A subsequent attempt introduced a `deeplinkTab` property that held the deeplink tab separately during restoration, then appended it afterwards. While directionally correct, this required the restoration path to carry URL-deduplication logic to detect when the deeplink tab matched a tab being restored from disk, and to special-case tab selection accordingly. The deeplink concern was woven through several restoration methods rather than being handled in one place.

The root issue was that tab restoration used a destructive `tabs = restoredTabs` assignment, which meant any tab created before restoration would be displaced or lost.

## Decision

We will make the tab manager agnostic of deeplinks, meaning it will not care whether a tab it holds originated from a deeplink or from a normal session restore. Tab restoration will happen concurrently with deeplink handling. Timing between the two should not matter.

We will remove the `deeplinkOptimizationRefactor` old feature flag code path. Deeplinks are handled immediately when `BrowserViewController` loads, without waiting for restoration.

We will also replace the destructive restore assignment with a snapshot-and-merge model. `restoreTabs()` snapshots any pre-existing tabs (`preRestoreTabs`) before clearing the store. After restoration completes, `applyRestorationResult` merges those tabs back at the end of the array. This will ensure any deeplink tabs always lands at the last position. We'll also add a protection mechanism in place to ensure the restore tabs function is called only one time per session, to avoid any misuage of the restore functionality.

Third, we will introduce `TabRestorer`, a dedicated class that owns the full restoration lifecycle: fetching persisted data, filtering private tabs, building tab objects through a narrow delegate protocol (`TabRestorerDelegate`) and restoring screenshots. `TabManagerImplementation` knows nothing about how tabs are fetched or filtered; it only applies the returned `TabRestorationResult` to its own state. This aims at reducing the responsibilities of the tab manager.

## Consequences

### Positive

- Deeplinks are handled immediately at startup, reducing perceived latency.
- Tab restoration is isolated in `TabRestorer`; `TabManagerImplementation` has no knowledge of deeplinks or restoration internals.
- Eliminates `isRestoringTabs`, `tabRestoreHasFinished`, and `isPendingDeeplink` booleans from production code.

### Negative

- The telemetry still needs to be defined and evaluated namely with `recordStartupTimeOpenDeeplinkComplete` and `recordStartupTimeOpenDeeplinkCancelled`.

## Referencess
- [Investigate deeplink delay](https://mozilla-hub.atlassian.net/browse/FXIOS-15285)
- [Improve tabs restoration process](https://mozilla-hub.atlassian.net/browse/FXIOS-11269)