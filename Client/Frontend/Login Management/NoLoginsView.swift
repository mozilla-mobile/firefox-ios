// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// Empty state view when there is no logins to display.
class NoLoginsView: UIView {
    lazy var titleLabel: UILabel = .build { label in
        label.font = LoginListViewModel.LoginListUX.NoResultsFont
        label.textColor = LoginListViewModel.LoginListUX.NoResultsTextColor
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
}
