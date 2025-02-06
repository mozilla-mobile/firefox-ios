// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class EcosiaPrimaryButton: UIButton {
    let windowUUID: WindowUUID

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { nil }

    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            update()
        }
    }

    override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            update()
        }
    }

    private func update() {
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        backgroundColor = (isSelected || isHighlighted) ? theme.colors.ecosia.buttonBackgroundPrimaryActive : theme.colors.ecosia.buttonBackgroundPrimary
    }
}
