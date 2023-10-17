// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class CardContentView: UIView, ThemeApplicable {
    lazy var contentLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        contentLabel.textColor = theme.colors.textPrimary
    }

    private func setupView() {
        addSubview(contentLabel)

        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentLabel.topAnchor.constraint(equalTo: topAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
}
