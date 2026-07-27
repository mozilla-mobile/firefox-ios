// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

final class WebCompatToggleCell: UICollectionViewListCell, ThemeApplicable, ReusableCell {
    private var toggleHandler: ((Bool) -> Void)?

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        // The switch carries the label for VoiceOver, so this is decorative.
        label.isAccessibilityElement = false
    }

    private let switchControl = ThemedSwitch()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        contentView.addSubview(titleLabel)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: margins.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        ])
        accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(
            customView: switchControl,
            placement: .trailing()
        ))]
    }

    func configure(title: String, isOn: Bool, a11yIdentifier: String, onToggle: @escaping (Bool) -> Void) {
        toggleHandler = onToggle
        titleLabel.text = title
        switchControl.isOn = isOn
        switchControl.accessibilityLabel = title
        switchControl.accessibilityIdentifier = a11yIdentifier
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        switchControl.applyTheme(theme: theme)
    }

    @objc
    private func switchChanged() {
        toggleHandler?(switchControl.isOn)
    }
}
