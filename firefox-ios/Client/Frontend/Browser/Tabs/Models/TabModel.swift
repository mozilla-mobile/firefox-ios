// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabModel: Equatable, Identifiable, Hashable {
    var id: String { return tabUUID }
    let tabUUID: TabUUID
    let isSelected: Bool
    let isPrivate: Bool
    let isFxHomeTab: Bool
    let tabTitle: String
    let url: URL?

    let screenshot: UIImage?
    let hasHomeScreenshot: Bool
    let hasScreenshotOnDisk: Bool

    /// Hash only the stable identity. `==` intentionally remains synthesized (full content):
    /// Redux subscriptions rely on content inequality to propagate updates, and the diffable
    /// data source uses `==` for item identity. Hashing only the UUID avoids O(N) normalized
    /// string hashing of titles/URLs on the main thread during snapshot applies.
    func hash(into hasher: inout Hasher) { hasher.combine(tabUUID) }

    static func emptyState(
        tabUUID: TabUUID,
        title: String,
        isPrivate: Bool = false,
        isSelected: Bool = false
    ) -> TabModel {
        return TabModel(
            tabUUID: tabUUID,
            isSelected: isSelected,
            isPrivate: isPrivate,
            isFxHomeTab: false,
            tabTitle: title,
            url: nil,
            screenshot: nil,
            hasHomeScreenshot: false,
            hasScreenshotOnDisk: false
        )
    }
}
