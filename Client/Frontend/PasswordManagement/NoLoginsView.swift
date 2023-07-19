// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Empty state view when there is no logins to display.
class NoLoginsView: UIView, ThemeApplicable {
    lazy var titleLabel: UILabel = .build { label in
        label.font = PasswordManagerViewModel.UX.noResultsFont
        label.text = .NoLoginsFound
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textDisabled
    }
}
