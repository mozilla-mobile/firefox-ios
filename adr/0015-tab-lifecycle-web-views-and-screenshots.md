# 15. Tab Lifecycle: Bounded Screenshots and Web Views

Date: 2026-10-07

## Status

Proposed. Builds on [ADR-0008](0008-lazy-tab-screenshot-restoration.md) and amends [ADR-0010](0010-offload-background-webviews-on-memory-warning.md).

## Context

Every tab Firefox visits keeps its screenshot in memory at screen resolution (about 12 MB on an iPhone 17 Pro) and a web view in the app process, and nothing bounds either; only the copy saved to disk is reduced to 1x. Screenshots in memory are never evicted. ADR-0008 makes restoring them at launch lazy, behind the `deeplinkOptimizationRefactor` flag, which is on in beta and developer builds, with a release rollout planned after an experiment, and notes the missing eviction. A web view stays alive until a memory warning (ADR-0010); iOS may kill its WebKit process sooner, leaving the web view with no page behind it. Firefox doesn't handle that kill for background tabs: the tab later loads its URL as a new page, losing the user's place and typed text and adding a duplicate history entry.

This fails in two ways. Screenshots alone take Firefox to its memory limit: on an iPhone 17 Pro it exited at tab 265 near its limit with no crash report, the kind of exit Sentry counts as a WatchdogTermination. And each live web view (one whose page is in a running WebKit process) adds about 100 MB to the app's address space; in testing, with about 50 alive, Firefox crashed from a failed allocation. ADR-0010's offload prevents neither: it keeps every screenshot, and it runs only on a memory warning, which in testing usually hadn't arrived before the crash.

ADR-0010 says an offloaded tab reloads from its URL. It doesn't: the offload only closes the web view, and when the tab is selected again Firefox rebuilds it from the `interactionState` saved when the user last left it, as it does for every tab after a relaunch.

Firefox for Android stopped keeping tab thumbnails in memory in Firefox 108 because they used too much memory, leaves the choice of which content processes to kill to the OS, guided by priority hints, and restores tabs whose content process the OS killed from saved state. The measurements are in the issue linked below.

## Decision

We will keep screenshots in memory only for the tabs the user is using now or used recently, leave WebKit's memory to iOS, and cap live web views below the point where the app crashes.

We will capture every screenshot at no more than one pixel per point (1x) while the web view is still in the window, and keep the copy on disk as the copy of record. Each view that shows a tab's image will load it itself, from memory or, behind a placeholder, from disk, and release it when it goes away. Besides the images on screen, we will keep in memory only the current tab's, its neighbours' and recently used tabs'. Recently used means up to N tabs selected or opened in the last M minutes; N and M (for example 10 and 10) are Nimbus variables, and the time limit lets an idle or backgrounded app let go of them. We will record when each tab was last used and check the set at points such as going to the background and changing tabs.

This builds on ADR-0008's on-demand path. `preloadScreenshotsAroundSelectedTab` stays as the step that warms the cache for the selected tab and its neighbours, and `screenshotRestored` stays until tray cells load their own images and that path is the default. The new loading, eviction and memory-warning screenshot release sit behind their own Nimbus flag and run only where ADR-0008's flag is also on; the legacy path is left to ADR-0008's rollout.

The current tab's neighbours keep their 1x screenshots through eviction and memory warnings, as ADR-0008 requires for the address-bar swipe. During a swipe, the preview shows the neighbour's page rendered at full resolution if it is a web page with a live web view, otherwise its stored screenshot, otherwise its favicon (the Firefox logo for the homepage). The render is never stored.

WebKit already suspends a page once it leaves the window, and iOS kills idle WebKit processes under memory pressure, so we will add no rule of our own for them. We will only cap live web views (a Nimbus variable) below the crash, which comes without memory pressure for iOS to act on: past the cap, we will unload the least recently used tab, saving its `interactionState` and then closing its web view. Active tabs and the current tab's neighbours are exempt. A tab is active if it is the selected tab of its window, if its web view's `cameraCaptureState` or `microphoneCaptureState` isn't `.none`, if `requestMediaPlaybackState` reports `.playing`, which should also cover Picture in Picture, or if it is downloading. The cap and the memory warning use the same definition. Unsubmitted form input doesn't make a tab active: saved state brings back what was typed into form fields, and Firefox can't tell when a script-managed editor has unsaved changes.

On a memory warning, we will first release every in-memory screenshot except active tabs', the neighbours' and those on screen, then unload every tab that isn't active, one at a time, least recently used first, in a single `Task` as ADR-0010 does. The neighbours' web views are released too; their screenshots stay.

When iOS kills a background tab's WebKit process, we will drop its web view, as an unload does. When the user selects an unloaded tab, we will rebuild it through the same path offloaded and relaunched tabs already take: from the state saved at unload; for a tab whose WebKit process iOS killed, from the state saved when the user last left it; and, for a tab with no saved state, such as one opened in the background and never selected, from its URL. On the pages tested this brought back the scroll position, history and typed text; the page itself reloads, so how much comes back depends on the page. A background kill isn't reloaded or counted as a crash; once the tab is selected, Firefox's existing crash handling applies unchanged.

This adds the eviction ADR-0008 lacks. It amends ADR-0010: its description is corrected (an offloaded tab is rebuilt from saved state, not reloaded from its URL), and unloading now saves that state first. It extends ADR-0010's response to screenshots and to tabs whose WebKit process iOS kills, and adds a bound that doesn't wait for a memory warning.

## Consequences

### Positive

- Firefox's own memory follows what is on screen instead of growing with every tab visited.
- Live web views stay well below the point where the app crashes, without waiting for a memory warning.
- A memory warning no longer closes tabs playing media, in Picture in Picture or using the camera or microphone, as ADR-0010's offload does today.
- Tabs whose WebKit process iOS killed come back at the same place, as offloaded and relaunched tabs already do.

### Negative

- Tray cells show a placeholder briefly when an image isn't cached, more often after a memory warning.
- Screenshots are softer on 3x iPhones (the swipe, the tray animation, the tab peek); the swipe's live render covers this only for tabs that still have a web view.
- The new screenshot loading and eviction reach release builds only once ADR-0008's flag is on there.
- Tabs unloaded by the cap reload their page when the user returns. Content a page keeps only in JavaScript, such as a rich text editor's, is lost, as it is today when a memory warning offloads the tab or iOS kills its WebKit process.
- Restoring a tab whose page is a form result resends the form without asking, as restoring an offloaded tab does today; tabs unloaded by the cap or whose WebKit process iOS killed now do too.

## References

- [#35962](https://github.com/mozilla-mobile/firefox-ios/issues/35962): Memory growth analysis (evidence and test reports)
- [ADR-0008](0008-lazy-tab-screenshot-restoration.md): Lazy Tab Screenshot Restoration
- [ADR-0010](0010-offload-background-webviews-on-memory-warning.md): Offload Background WebViews on Memory Warning
- [#31164](https://github.com/mozilla-mobile/firefox-ios/issues/31164): Screenshot optimization
- [#32164](https://github.com/mozilla-mobile/firefox-ios/issues/32164): Investigate the cause of Watchdog Terminations
- [Bug 1795105](https://bugzilla.mozilla.org/show_bug.cgi?id=1795105): Firefox for Android, tab thumbnails use too much memory
- [android-components#11300](https://github.com/mozilla-mobile/android-components/issues/11300): Option to disable TrimMemoryMiddleware, which Firefox for Android uses to leave content processes to the OS
