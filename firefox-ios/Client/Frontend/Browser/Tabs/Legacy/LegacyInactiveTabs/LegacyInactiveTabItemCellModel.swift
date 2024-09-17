// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

struct LegacyInactiveTabItemCellModel {
    struct UX {
        static let ImageSize: CGFloat = 28
        static let BorderViewMargin: CGFloat = 16
        static let LabelTopBottomMargin: CGFloat = 11
        static let ImageTopBottomMargin: CGFloat = 10
        static let ImageViewLeadingConstant: CGFloat = 16
        static let MidViewLeadingConstant: CGFloat = 12
        static let MidViewTrailingConstant: CGFloat = -16
        static let SeparatorHeight: CGFloat = 0.5
        static let FaviconCornerRadius: CGFloat = 5
    }

    var fontForLabel: UIFont {
        return FXFontStyles.Regular.body.systemFont()
    }

    var title: String?
    var website: URL?
}
