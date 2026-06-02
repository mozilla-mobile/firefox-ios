// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol NavigationListItem: AnyObject {}
extension WKBackForwardListItem: NavigationListItem {}

protocol TranslationNavigationCaching {
    func savedTranslation(for item: NavigationListItem, tabUUID: TabUUID) -> TranslationConfiguration?
    func saveTranslation(_ configuration: TranslationConfiguration, for item: NavigationListItem, tabUUID: TabUUID)
    func clearTranslation(for item: NavigationListItem, tabUUID: TabUUID)
}

/// Remembers the translation state of pages as the user navigates a tab's back/forward history.
/// WKWebView restores a page's DOM on back/forward navigation but not our injected translation, so
/// we map each `WKBackForwardListItem` to the `TranslationConfiguration` that page had and re-apply
/// it on the next commit (see `BrowserViewController+WebViewDelegates`). Entries are keyed by
/// `TabUUID` for per-tab isolation, and items are matched by identity (`===`) because WebKit reuses
/// the same back/forward item reference for a given history entry.
class TranslationNavigationCache: TranslationNavigationCaching {
    private var pages: [TabUUID: [(item: NavigationListItem, configuration: TranslationConfiguration)]] = [:]

    func savedTranslation(for item: NavigationListItem, tabUUID: TabUUID) -> TranslationConfiguration? {
        pages[tabUUID]?.first { $0.item === item }?.configuration
    }

    func saveTranslation(_ configuration: TranslationConfiguration, for item: NavigationListItem, tabUUID: TabUUID) {
        var entries = pages[tabUUID] ?? []
        entries.removeAll { $0.item === item }
        entries.append((item: item, configuration: configuration))
        pages[tabUUID] = entries
    }

    func clearTranslation(for item: NavigationListItem, tabUUID: TabUUID) {
        pages[tabUUID]?.removeAll { $0.item === item }
    }
}
