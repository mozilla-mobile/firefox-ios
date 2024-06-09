// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class ReaderPanelEmptyStateView: UIView {
    let windowUUID: WindowUUID
    let themeManager: Common.ThemeManager

    init(
        windowUUID: WindowUUID,
        frame: CGRect = .zero,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {

    }
}
