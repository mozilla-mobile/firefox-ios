# 8. Lazy Tab Screenshot Restoration

Date: 2026-04-22

## Status

Proposed

## Context

When tab restoration runs at startup, `TabRestorer` currently calls `restoreScreenshot(tab:)` for every restored tab immediately as each tab is created. For a session with many tabs this means dozens of concurrent image loads from disk, all racing to complete during the same narrow startup window. Each loaded screenshot is held in memory as a `UIImage`, even for tabs the user will never scroll to. On devices with constrained memory this can cause pressure early in the app lifecycle, before the user has interacted at all.

The screenshots are used mostly for the tab tray, a `UICollectionView` that only shows the selected tab and its immediate neighbours at startup. Off-screen tabs do not need their screenshots loaded upfront. Screenshots are also used in `StackedTabButton` and in the toolbar swipe gesture via `TabWebViewPreview`, so the selected tab's immediate neighbours must always have their screenshots preloaded.

## Decision

We will make screenshot restoration lazy and demand-driven rather than eager and bulk-loaded.

During tab restoration, `TabRestorer` will no longer call `restoreScreenshot` for every tab. Screenshots will instead be loaded on demand in two situations: when a tab becomes selected (load its screenshot and those of its immediate neighbours), and when a tab cell is about to appear in the tab tray (load that tab's screenshot if not already present).

Since the tab tray is a `UICollectionView`, we will adopt `UICollectionViewDataSourcePrefetching` to drive screenshot loading. This protocol allows the collection view to signal which index paths are about to become visible, so screenshots can be fetched just in time. Prefetch requests that are cancelled before completion (e.g. the user scrolls back quickly) can be used to abort in-flight loads.

`TabRestorer` will expose a `restoreScreenshot(tab:onComplete:)` method that remains available for these on-demand calls. `TabManagerImplementation` will trigger neighbour preloading inside `selectTab`, limiting the preload window to a configurable small radius (e.g. one tab on each side).

Screenshots that are already held in memory should be used as-is and not reloaded. A tab whose `screenshot` property is non-nil can be skipped.

## Consequences

### Positive

- Memory usage at startup is significantly reduced because only a handful of screenshots are loaded instead of the entire session.
- The demand-driven model naturally prioritises the tabs the user is actually looking at.
- `UICollectionViewDataSourcePrefetching` provides a built-in hook for just-in-time loading without requiring custom scroll observation.

### Negative

- Tabs in the tab tray may briefly display a placeholder before their screenshot loads, introducing a short visual delay on first scroll.
- `selectTab` gains a side effect (triggering async loads), which must be accounted for in tests that assert on tab state immediately after selection.
- Without an explicit eviction strategy, screenshots accumulate in memory as the user scrolls. A user who browses their full tab tray will end up with the same memory footprint as the current eager approach, just reached later rather than at startup.

## References
- [Investigate deeplink delay](https://mozilla-hub.atlassian.net/browse/FXIOS-15285)
- [Improve tabs restoration process](https://mozilla-hub.atlassian.net/browse/FXIOS-11269)