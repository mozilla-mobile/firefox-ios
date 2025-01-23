// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct SettingDisclosureUtility {
    static func buildDisclosureIndicator(theme: Theme) -> UIImageView {
        let disclosureIndicator = UIImageView()
        disclosureIndicator.image = UIImage(
            named: StandardImageIdentifiers.Large.chevronRight
        )?.withRenderingMode(.alwaysTemplate).imageFlippedForRightToLeftLayoutDirection()
        disclosureIndicator.tintColor = theme.colors.iconSecondary
        disclosureIndicator.sizeToFit()
        disclosureIndicator.adjustsImageSizeForAccessibilityContentSizeCategory = true
        return disclosureIndicator
    }
}
