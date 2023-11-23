// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class SettingsLoadingView: UIView, ThemeApplicable {
    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var indicator: UIActivityIndicatorView = .build { indicator in
        indicator.style = .medium
        indicator.hidesWhenStopped = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        indicator.startAnimating()
    }

    func applyTheme(theme: Theme) {
        indicator.color = theme.colors.iconSpinner
        backgroundColor = theme.colors.layer1
    }

    override internal func updateConstraints() {
        super.updateConstraints()

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -(searchBarHeight / 2))
        ])
    }
}
