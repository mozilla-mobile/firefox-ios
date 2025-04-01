// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Protocol for a view which displays the current search engine inside the toolbar.
protocol SearchEngineView: UIView {
    func configure(
        _ config: LocationViewConfiguration,
        isLocationTextCentered: Bool,
        delegate: LocationViewDelegate
    )
    func applyTheme(theme: Theme)
}
