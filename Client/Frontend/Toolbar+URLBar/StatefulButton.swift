// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

enum ReloadButtonState: String {
    case reload = "Reload"
    case stop = "Stop"
    case disabled = "Disabled"
}

class StatefulButton: UIButton {
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

    var _reloadButtonState = ReloadButtonState.disabled

    var reloadButtonState: ReloadButtonState {
        get {
            return _reloadButtonState
        }
        set (newReloadButtonState) {
            _reloadButtonState = newReloadButtonState
            switch _reloadButtonState {
            case .reload:
                setImage(UIImage.templateImageNamed("nav-refresh"), for: .normal)
            case .stop:
                setImage(UIImage.templateImageNamed("nav-stop"), for: .normal)
            case .disabled:
                self.isHidden = true
            }
        }
    }
}
