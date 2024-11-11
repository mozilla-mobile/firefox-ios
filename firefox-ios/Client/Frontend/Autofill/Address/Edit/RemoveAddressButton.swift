// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class RemoveAddressButton: UIButton, ThemeApplicable {
    private let topSeparator: UIView = .build()
    private let bottomSeparator: UIView = .build()

    init() {
        super.init(frame: .zero)
        self.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()

        addSubview(topSeparator)
        addSubview(bottomSeparator)

        backgroundColor = .systemBackground

        setupSeparatorConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSeparatorConstraints() {
        NSLayoutConstraint.activate([
            topSeparator.bottomAnchor.constraint(equalTo: topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 1),

            bottomSeparator.topAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparator.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bringSubviewToFront(topSeparator)
        bringSubviewToFront(bottomSeparator)
    }

    func applyTheme(theme: any Theme) {
        let color = theme.colors
        backgroundColor = color.layer2
        setTitleColor(color.textCritical, for: .normal)
        topSeparator.backgroundColor = color.borderPrimary
        bottomSeparator.backgroundColor = color.borderPrimary
    }
}
