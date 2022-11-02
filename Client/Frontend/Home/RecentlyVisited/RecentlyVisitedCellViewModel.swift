// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct RecentlyVisitedCellViewModel {
    let title: String
    let description: String?
    let favIconImage: UIImage?
    let corners: CACornerMask?
    let hideBottomLine: Bool
    let isFillerCell: Bool
    let shouldAddShadow: Bool
    var accessibilityLabel: String {
        if let description = description {
            return "\(title), \(description)"
        } else {
            return title
        }
    }

    init(title: String,
         description: String?,
         shouldHideBottomLine: Bool,
         with corners: CACornerMask? = nil,
         and heroImage: UIImage? = nil,
         andIsFillerCell: Bool = false,
         shouldAddShadow: Bool = false) {
        self.title = title
        self.description = description
        self.hideBottomLine = shouldHideBottomLine
        self.corners = corners
        self.favIconImage = heroImage
        self.isFillerCell = andIsFillerCell
        self.shouldAddShadow = shouldAddShadow
    }

    // Filler cell init
    init(shouldHideBottomLine: Bool,
         with corners: CACornerMask? = nil,
         shouldAddShadow: Bool) {

        self.init(title: "",
                  description: "",
                  shouldHideBottomLine: shouldHideBottomLine,
                  with: corners,
                  and: nil,
                  andIsFillerCell: true,
                  shouldAddShadow: shouldAddShadow)
    }
}
