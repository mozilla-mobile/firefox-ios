// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

struct RemoteTabCreator {
    @MainActor
    static func toRemoteTab(from tab: Tab) -> RemoteTab? {
        guard !tab.isPrivate else {
            return nil
        }

        let faviconURL = tab.faviconURL ?? tab.pageMetadata?.faviconURL
        if let displayURL = tab.url?.displayURL,
           RemoteTab.shouldIncludeURL(displayURL) {
            let filteredReversedHistory: [URL] = tab.historyList
                .filter(RemoteTab.shouldIncludeURL)
                .reversed()

            return RemoteTab(
                clientGUID: nil,
                URL: displayURL,
                title: tab.title ?? tab.displayTitle,
                history: filteredReversedHistory,
                lastUsed: tab.lastExecutedTime,
                icon: faviconURL?.asURL
            )
        }

        return nil
    }
}
