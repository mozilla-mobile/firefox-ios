// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// WIP. Defines tab-specific state that is reflected in the new TabCell.
struct TabCellState {
    let isSelected: Bool
    let isPrivate: Bool
    let isFxHomeTab: Bool

    let tabTitle: String
    let url: URL?

    let screenshot: UIImage? // TBD.
    let hasHomeScreenshot: Bool // TBD.

    let margin: CGFloat // (Changes depending on fullscreen)

    static func emptyTabState(title: String) -> TabCellState {
        return TabCellState(isSelected: false,
                            isPrivate: false,
                            isFxHomeTab: false,
                            tabTitle: title,
                            url: nil,
                            screenshot: nil,
                            hasHomeScreenshot: false,
                            margin: 0.0)
    }
}
