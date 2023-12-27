// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabModel: Equatable {
    let tabUUID: String
    let isSelected: Bool
    let isPrivate: Bool
    let isFxHomeTab: Bool
    let tabTitle: String
    let url: URL?

    let screenshot: UIImage?
    let hasHomeScreenshot: Bool

    let margin: CGFloat // (Changes depending on fullscreen)

    static func emptyTabState(tabUUID: String, title: String) -> TabModel {
        return TabModel(
            tabUUID: tabUUID,
            isSelected: false,
            isPrivate: false,
            isFxHomeTab: false,
            tabTitle: title,
            url: nil,
            screenshot: nil,
            hasHomeScreenshot: false,
            margin: 0.0
        )
    }
}
