// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared

enum ReloadButtonState: String {
    case reload = "Reload"
    case stop = "Stop"
    case disabled = "Disabled"
}

class StatefulButton: UIButton {
    // MARK: - Initializers

    convenience init(frame: CGRect, state: ReloadButtonState) {
        self.init(frame: frame)
        reloadButtonState = state
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var savedReloadButtonState = ReloadButtonState.disabled

    var reloadButtonState: ReloadButtonState {
        get {
            return savedReloadButtonState
        }
        set (newReloadButtonState) {
            savedReloadButtonState = newReloadButtonState
            switch savedReloadButtonState {
            case .reload:
                setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
            case .stop:
                setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: .normal)
            case .disabled:
                self.isHidden = true
            }
        }
    }
}

// MARK: - Theme protocols
extension StatefulButton: ThemeApplicable {
    func applyTheme(theme: Theme) {
        tintColor = isEnabled ? theme.colors.iconSecondary : theme.colors.iconDisabled
        imageView?.tintColor = tintColor
    }
}
