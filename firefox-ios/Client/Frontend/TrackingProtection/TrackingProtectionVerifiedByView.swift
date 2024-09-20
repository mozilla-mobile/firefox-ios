// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import ComponentLibrary

class TrackingProtectionVerifiedByView: UIView {
    private let verifiedByLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Setup
    private func setupView() {
        addSubview(verifiedByLabel)

        NSLayoutConstraint.activate([
            verifiedByLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: TPMenuUX.UX.horizontalMargin),
            verifiedByLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -TPMenuUX.UX.horizontalMargin),
            verifiedByLabel.topAnchor.constraint(equalTo: topAnchor, constant: TPMenuUX.UX.horizontalMargin),
            verifiedByLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -TPMenuUX.UX.horizontalMargin)
        ])
    }

    func configure(verifiedBy: String?) {
        verifiedByLabel.text = verifiedBy
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        verifiedByLabel.textColor = theme.colors.textPrimary
    }
}
