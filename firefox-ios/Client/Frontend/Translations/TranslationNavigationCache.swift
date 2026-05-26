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
