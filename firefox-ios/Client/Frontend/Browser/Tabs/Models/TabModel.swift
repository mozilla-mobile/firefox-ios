// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabModel: Equatable {
    let tabUUID: TabUUID
    let isSelected: Bool
    let isPrivate: Bool
    let isFxHomeTab: Bool
    let tabTitle: String
    let url: URL?

    let screenshot: UIImage?
    let hasHomeScreenshot: Bool

    static func emptyTabState(tabUUID: TabUUID, title: String, isPrivate: Bool = false) -> TabModel {
        return TabModel(
            tabUUID: tabUUID,
            isSelected: false,
            isPrivate: isPrivate,
            isFxHomeTab: false,
            tabTitle: title,
            url: nil,
            screenshot: nil,
            hasHomeScreenshot: false
        )
    }
}
