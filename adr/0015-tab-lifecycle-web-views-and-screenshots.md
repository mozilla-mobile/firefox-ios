# 15. Tab Lifecycle: Bounded Screenshots and Web Views

Date: 2026-10-07

## Status

Proposed. Amends [ADR-0008](0008-lazy-tab-screenshot-restoration.md) and [ADR-0010](0010-offload-background-webviews-on-memory-warning.md).

## Context

Every tab Firefox visits keeps a screenshot at screen resolution (about 12 MB on an iPhone 17 Pro) and a web view in the app process, and nothing bounds either. Screenshots are never evicted; ADR-0008 makes restoring them lazy, so far only in beta and developer builds, and notes the missing eviction. A web view stays alive until a memory warning (ADR-0010); iOS may kill its WebKit process sooner, leaving the web view with no page behind it. Firefox doesn't handle that kill for background tabs: the tab later loads its URL as a new page, losing the user's place and typed text and adding a duplicate history entry.

This fails in two ways. Screenshots alone take Firefox to its memory limit: on an iPhone 17 Pro it exited at tab 265 near its limit with no crash report, the kind of exit Sentry counts as a WatchdogTermination. And each live web view (one whose page is in a running WebKit process) adds about 100 MB to the app's address space; in testing, with about 50 alive, Firefox crashed from a failed allocation. ADR-0010's offload prevents neither: it keeps every screenshot, and it runs only on a memory warning, which in testing usually hadn't arrived before the crash.

Firefox for Android stopped keeping tab thumbnails in memory in Firefox 108 because they used too much memory, leaves the choice of which content processes to kill to the OS, guided by priority hints, and restores tabs whose content process the OS killed from saved state. The measurements are in the issue linked below.

## Decision

We will keep screenshots in memory only for the tabs the user is using now or used recently, leave WebKit's memory to iOS, and cap live web views below the point where the app crashes.

We will capture every screenshot at no more than one pixel per point (1x) while the web view is still in the window, and save it to disk as the copy of record. Each view that shows a tab's image will load it itself, from memory or, behind a placeholder, from disk, and release it when it goes away; UI state will carry only what is needed to fetch an image. Besides the images on screen, we will keep in memory only the current tab's, its neighbours' and recently used tabs'. Recently used means up to N tabs selected or opened in the last M minutes; N and M (for example 10 and 10) are Nimbus variables, and the time limit lets an idle or backgrounded app let go of them. We will record when each tab was last used and check the set at points such as going to the background and changing tabs. We will load screenshots restored at launch on demand in every build. During an address-bar swipe to a tab with a live web view, we will render that page at full resolution and never store the render.

WebKit already suspends a page once it leaves the window, and iOS kills idle WebKit processes under memory pressure, so we will add no rule of our own for them. We will only cap live web views (a Nimbus variable) below the crash, which comes without memory pressure for iOS to act on: past the cap, we will unload the least recently used tab, saving its `interactionState` and closing its web view, as ADR-0010's offload does. Active tabs (the current tab and tabs doing work in the background: media, Picture in Picture, camera or microphone, downloads) and the current tab's neighbours are exempt. On a memory warning, we will unload every tab that isn't active and release every in-memory screenshot but active tabs' and those on screen. When iOS kills a background tab's WebKit process, we will treat that tab as unloaded too. We will rebuild every unloaded tab the way offloaded and relaunched tabs already are: from its last saved `interactionState`. On the pages tested this brought back the scroll position, history and typed text; the page itself reloads, so how much comes back depends on the page.

This makes ADR-0008's on-demand loading the only path, in every build, and adds the eviction it lacks. It extends ADR-0010's response to screenshots and to tabs whose WebKit process iOS kills, and adds a bound that doesn't wait for a memory warning.

## Consequences

### Positive

- Firefox's own memory follows what is on screen instead of growing with every tab visited.
- Live web views stay well below the point where the app crashes, without waiting for a memory warning.
- A memory warning no longer closes tabs playing media or in Picture in Picture, as ADR-0010's offload does today.
- Tabs whose WebKit process iOS killed come back at the same place, as offloaded tabs already do.
- Release builds stop loading every screenshot at launch.

### Negative

- Tray cells show a placeholder briefly when an image isn't cached, more often after a memory warning.
- Screenshots are softer on 3x iPhones (the swipe, the tray animation, the tab peek); the swipe's live render covers this only for tabs that still have a web view.
- Tabs unloaded by the cap reload their page when the user returns.

## References

- [#35962](https://github.com/mozilla-mobile/firefox-ios/issues/35962): Memory growth analysis (evidence and test reports)
- [ADR-0008](0008-lazy-tab-screenshot-restoration.md): Lazy Tab Screenshot Restoration
- [ADR-0010](0010-offload-background-webviews-on-memory-warning.md): Offload Background WebViews on Memory Warning
- [#31164](https://github.com/mozilla-mobile/firefox-ios/issues/31164): Screenshot optimization
- [#32164](https://github.com/mozilla-mobile/firefox-ios/issues/32164): Investigate the cause of Watchdog Terminations
- [Bug 1795105](https://bugzilla.mozilla.org/show_bug.cgi?id=1795105): Firefox for Android, tab thumbnails use too much memory
- [android-components#11300](https://github.com/mozilla-mobile/android-components/issues/11300): Firefox for Android stops suspending tabs itself and leaves content processes to the OS
