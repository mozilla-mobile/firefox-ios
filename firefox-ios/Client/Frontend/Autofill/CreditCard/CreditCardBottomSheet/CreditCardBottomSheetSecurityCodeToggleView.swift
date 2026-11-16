// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// The "Save security codes" row shown in the save / update credit card bottom sheet.
final class CreditCardBottomSheetSecurityCodeToggleView: UIView, ThemeApplicable {
    private enum UX {
        static let cornerRadius: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 11
        static let labelSwitchSpacing: CGFloat = 8
    }

    /// Called with the new value whenever the user flips the switch.
    var onToggle: ((Bool) -> Void)?

    private lazy var titleLabel: UILabel = .build { label in
        label.text = .CreditCard.RememberCreditCard.SaveSecurityCodesToggleTitle
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private(set) lazy var toggle: ThemedSwitch = .build { toggle in
        toggle.accessibilityIdentifier = AccessibilityIdentifiers.RememberCreditCard.saveSecurityCodesToggle
        toggle.addTarget(self, action: #selector(self.didToggle), for: .valueChanged)
    }

    init(isOn: Bool) {
        super.init(frame: .zero)
        toggle.isOn = isOn
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        layer.cornerRadius = UX.cornerRadius
        clipsToBounds = true
        addSubviews(titleLabel, toggle)
        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.verticalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.verticalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -UX.labelSwitchSpacing),

            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalPadding),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggle.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: UX.verticalPadding),
            toggle.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -UX.verticalPadding),
        ])

        isAccessibilityElement = false
        toggle.accessibilityLabel = .CreditCard.RememberCreditCard.SaveSecurityCodesToggleTitle
        titleLabel.isAccessibilityElement = false
    }

    @objc
    private func didToggle() {
        onToggle?(toggle.isOn)
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        toggle.applyTheme(theme: theme)
    }
}
