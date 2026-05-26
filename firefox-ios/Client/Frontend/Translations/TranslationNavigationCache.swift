// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol TranslationNavigationCaching {
    func savedTranslation(for item: WKBackForwardListItem, tabUUID: TabUUID) -> TranslationConfiguration?
    func saveTranslation(_ configuration: TranslationConfiguration, for item: WKBackForwardListItem, tabUUID: TabUUID)
    func clearTranslation(for item: WKBackForwardListItem, tabUUID: TabUUID)
}

class TranslationNavigationCache: TranslationNavigationCaching {
    private var pages: [TabUUID: [(item: WKBackForwardListItem, configuration: TranslationConfiguration)]] = [:]

    func savedTranslation(for item: WKBackForwardListItem, tabUUID: TabUUID) -> TranslationConfiguration? {
        pages[tabUUID]?.first { $0.item === item }?.configuration
    }

    func saveTranslation(_ configuration: TranslationConfiguration, for item: WKBackForwardListItem, tabUUID: TabUUID) {
        var entries = pages[tabUUID] ?? []
        entries.removeAll { $0.item === item }
        entries.append((item: item, configuration: configuration))
        pages[tabUUID] = entries
    }

    func clearTranslation(for item: WKBackForwardListItem, tabUUID: TabUUID) {
        pages[tabUUID]?.removeAll { $0.item === item }
    }
}
