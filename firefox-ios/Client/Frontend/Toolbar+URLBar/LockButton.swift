// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class LockButton: UIButton {
    // MARK: - Variables

    var selectedTintColor: UIColor?
    var unselectedTintColor: UIColor?
    var disabledTintColor: UIColor?

    override open var isHighlighted: Bool {
        didSet {
            self.tintColor = isHighlighted ? selectedTintColor : unselectedTintColor
        }
    }

    override open var isEnabled: Bool {
        didSet {
            self.tintColor = isEnabled ? unselectedTintColor : disabledTintColor
        }
    }

    override var tintColor: UIColor? {
        didSet {
            self.imageView?.tintColor = self.tintColor
        }
    }

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = false
        setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.lock), for: .normal)
        imageView?.contentMode = .scaleAspectFill
        configuration = .plain()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Theme protocols
extension LockButton: ThemeApplicable {
    func applyTheme(theme: Theme) {
        selectedTintColor = theme.colors.actionPrimary
        disabledTintColor = theme.colors.iconDisabled
        unselectedTintColor = theme.colors.textPrimary
        tintColor = isEnabled ? unselectedTintColor : disabledTintColor
    }
}
