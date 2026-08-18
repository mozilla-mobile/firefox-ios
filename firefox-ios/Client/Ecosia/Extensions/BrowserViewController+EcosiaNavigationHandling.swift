// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia

// MARK: - Ecosia Web View Event Handling
extension BrowserViewController {

    /// Single entry point for all Ecosia-specific processing in `decidePolicyFor`.
    /// Runs vertical preservation, URL ecosification, and navigation tracking in order.
    /// Returns `true` when a replacement navigation was started — caller is responsible for
    /// calling `decisionHandler(.cancel)` and returning.
    func ecosiaDecidePolicyForNavigation(
        url: URL,
        webView: WKWebView,
        tab: Tab,
        navigationAction: WKNavigationAction
    ) -> Bool {
        guard navigationAction.targetFrame?.isMainFrame == true else { return false }
        if ecosiaApplyVerticalPreservingSearchNavigationIfNeeded(
            navigationURL: url,
            currentPageURL: webView.url ?? tab.url,
            navigationType: navigationAction.navigationType,
            tab: tab
        ) {
            return true
        }
        if ecosiaEcosifyNavigationIfNeeded(url: url, tab: tab) {
            return true
        }
        ecosiaHandleNavigationAction(url: url, navigationAction: navigationAction)
        return false
    }

    /// Handles any Ecosia-specific tracking when a navigation action is allowed.
    /// Stores a pending URL to be tracked at didCommit.
    private func ecosiaHandleNavigationAction(url: URL, navigationAction: WKNavigationAction) {
        // Clear any stale pending tracking from a previous navigation
        pendingInappSearchUrl = nil

        guard url.isEcosiaSearchVertical() else { return }

        // Back/forward navigations are suppressed: on web, bfcache keeps the page mounted so
        // Vue never refires. Tab switching doesn't reach this delegate at all, so any other
        // navigation type arriving here is a genuine user action and should always track.
        guard navigationAction.navigationType != .backForward else { return }

        // Store the URL; the event fires in ecosiaHandleDidCommit when content starts rendering
        pendingInappSearchUrl = url
    }

    /// Fires the in-app search event when the web content starts to be received (didCommit).
    /// This matches the timing of Vue's mounted event on web (DOM ready, before full page load).
    /// - Parameters:
    ///   - url: The URL that just committed
    ///   - isPrivate: Whether the tab is in private browsing mode
    func ecosiaHandleDidCommit(url: URL, isPrivate: Bool) {
        guard url == pendingInappSearchUrl else { return }
        pendingInappSearchUrl = nil
        Analytics.shared.inappSearch(url: url, isPrivate: isPrivate)
    }

    /// Rewrites in-page SERP navigations that target the default text vertical (`/search`) so they
    /// stay on the user's active vertical (e.g. Images). Returns `nil` when navigation should proceed unchanged.
    private func ecosiaSearchURLPreservingVertical(
        navigationURL: URL,
        currentPageURL: URL?,
        navigationType: WKNavigationType
    ) -> URL? {
        guard let rewritten = navigationURL.ecosiaSearchURLPreservingVertical(from: currentPageURL) else {
            return nil
        }
        // Same-query link to `/search` is a vertical-tab switch (e.g. Web from Images), not a new search.
        if navigationType == .linkActivated,
           let currentPageURL,
           let currentQuery = currentPageURL.getEcosiaSearchQuery(),
           let newQuery = navigationURL.getEcosiaSearchQuery(),
           currentQuery == newQuery {
            return nil
        }
        return rewritten
    }

    /// Returns `true` when navigation was rewritten to preserve the active SERP vertical.
    @discardableResult
    private func ecosiaApplyVerticalPreservingSearchNavigationIfNeeded(
        navigationURL: URL,
        currentPageURL: URL?,
        navigationType: WKNavigationType,
        tab: Tab
    ) -> Bool {
        guard let rewritten = ecosiaSearchURLPreservingVertical(
            navigationURL: navigationURL,
            currentPageURL: currentPageURL,
            navigationType: navigationType
        ) else {
            return false
        }
        tab.loadRequest(URLRequest(url: rewritten))
        return true
    }

    /// Ecosifies the navigation URL if it carries an absent or outdated Snowplow user id, reloading via
    /// `tab.loadRequest()` so `ecosiaUpdatedRequest` runs. Returns `true` when a replacement was started.
    private func ecosiaEcosifyNavigationIfNeeded(url: URL, tab: Tab) -> Bool {
        let ecosified = url.ecosified(isIncognitoEnabled: tab.isPrivate)
        guard ecosified != url else { return false }
        tab.loadRequest(URLRequest(url: ecosified))
        return true
    }
}
