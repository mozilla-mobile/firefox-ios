# 10. Offload Background WebViews on Memory Warning

Date: 2026-04-30

## Status

Proposed

## Context

Firefox iOS has no meaningful response to OS memory warnings. `applicationDidReceiveMemoryWarning` logs the event and returns. When the app exceeds the system memory limit, the OS watchdog terminates it without warning and without a stacktrace — making the crash nearly invisible during development.

Sentry issue (WatchdogTermination) has accumulated 7.8 million occurrences across 285,000 users since February 2023 and remains unresolved. Breadcrumb analysis of affected sessions consistently shows users with thousands of open tabs (one sample session had 3,629). The existing zombie-tab architecture already avoids creating WebViews for tabs that have never been selected, but background tabs that have been visited at any point hold live `WKWebView` instances. Each of those can consume memory.

The crash is not a code defect but an architectural gap: the app accumulates memory and ignores the OS signals that precede the kill.

## Decision

We will respond to OS memory warnings by offloading the WebViews of all background tabs that currently have one, returning those tabs to zombie state.

When `applicationDidReceiveMemoryWarning` fires, `AppDelegate` will iterate all active windows and call `offloadBackgroundWebViews()` on each `TabManager`. That method collects every tab whose `webView` is non-nil and that is not the currently selected tab, then offloads them sequentially in a single `Task`. The selected tab is never touched.

Offloading a tab calls the existing `Tab.close()` method, which stops media playback, removes the WebView from the view hierarchy, notifies the `LegacyTabDelegate` so BVC can tear down its KVO observers, and sets `webView = nil`. The tab's URL, title, and metadata are preserved. When the user returns to the tab, `createWebview()` is called as usual and the page reloads from its URL, exactly as it does for tabs restored from a previous session.

One consequence of reusing `close()` is that `TabContentScriptManager.uninstall()` must also clear its internal `helpers` dictionary. Previously `uninstall()` only removed script message handlers from the `WKUserContentController` but left `helpers` populated, which was harmless for permanent tab closure. For an offloaded tab that will be re-activated, leaving `helpers` populated would prevent `addContentScript` from re-registering scripts on the new WebView (the method guards against duplicate names). We extend `uninstall()` to call `helpers.removeAll()` so that content scripts are correctly reinstalled when the tab's WebView is recreated.

A debug menu entry in the hidden settings section allows the behaviour to be triggered manually, since OS memory warnings are difficult to reproduce in development.

## Consequences

### Positive

- Background WebView memory is freed on demand when the OS signals pressure.
- The selected tab is never affected; the user's active browsing session is uninterrupted.
- Offloaded tabs behave identically to zombie tabs restored from a previous session, so the re-activation path is already well-tested and understood.
- Content scripts, login autofill, and all other tab helpers are correctly reinstalled on the new WebView when a tab is re-activated.

### Negative

- Background tabs that were loaded will need to be reloaded when the user returns to them after a memory warning.
- Users who accumulate thousands of tabs will still encounter performance degradation and continued memory pressure from tab metadata serialisation.
- `Tab.close()` now always clears `helpers`, which is a behaviour change for permanent tab closure as well. For permanently closed tabs this is harmless (the tab object is discarded), but it is a subtle semantic extension of what `uninstall()` does and must be kept in mind if `close()` is ever called in contexts where `helpers` state needs to persist.

## References

- [Sentry issue](https://mozilla.sentry.io/issues/3914209929/)
- [FXIOS-15671](https://mozilla-hub.atlassian.net/browse/FXIOS-15671)
