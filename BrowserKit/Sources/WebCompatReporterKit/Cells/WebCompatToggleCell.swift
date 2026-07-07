// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

final class WebCompatToggleCell: UICollectionViewListCell {
    private var toggleHandler: ((Bool) -> Void)?

    private lazy var titleLabel: UILabel = .build { label in
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        // The switch carries the label for VoiceOver, so this is decorative.
        label.isAccessibilityElement = false
    }

    // Not built via `.build`: as a custom-view cell accessory it must keep
    // `translatesAutoresizingMaskIntoConstraints = true` (UIKit asserts otherwise).
    private lazy var switchControl: ThemedSwitch = {
        let control = ThemedSwitch()
        control.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        return control
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: margins.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            titleLabel.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            )
        ])
        accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(
            customView: switchControl,
            placement: .trailing()
        ))]
    }

    func configure(title: String, isOn: Bool, theme: Theme, onToggle: @escaping (Bool) -> Void) {
        toggleHandler = onToggle
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        titleLabel.text = title
        titleLabel.textColor = theme.colors.textPrimary
        // Theme first so the off-track/thumb colors resolve before `isOn` reads them.
        switchControl.applyTheme(theme: theme)
        switchControl.isOn = isOn
        // The switch is the single accessibility element; it announces the title,
        // the switch role, and a localized on/off value, and toggles natively.
        switchControl.accessibilityLabel = title
    }

    @objc
    private func switchChanged() {
        toggleHandler?(switchControl.isOn)
    }
}
