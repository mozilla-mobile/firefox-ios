// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

// MARK: - PhotonActionSheetSeparator
class PhotonActionSheetSeparator: UITableViewHeaderFooterView, ReusableCell, ThemeApplicable {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.borderPrimary
    }
}
