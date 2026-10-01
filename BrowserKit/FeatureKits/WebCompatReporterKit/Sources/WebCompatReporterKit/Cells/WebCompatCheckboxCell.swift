// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A checkbox row in Additional Info. The whole row is the tap target, so the
/// sheet's `didSelectItemAt` reports the flip.
final class WebCompatCheckboxCell: UICollectionViewListCell, ThemeApplicable, ReusableCell, Notifiable {
    private var isChecked = false
    private var theme: Theme?

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.isAccessibilityElement = false
    }

    private let checkboxView = WebCompatCheckboxView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        let margins = contentView.layoutMarginsGuide
        // .defaultHigh (not required) avoids the self-sizing vs. min-height constraint conflict.
        let topConstraint = titleLabel.topAnchor.constraint(equalTo: margins.topAnchor)
        let bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(
                equalTo: margins.leadingAnchor,
                constant: WebCompatReporterUX.Spacing.interItem
            ),
            titleLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            topConstraint,
            bottomConstraint,
            titleLabel.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            )
        ])
        accessories = [.customView(configuration: UICellAccessory.CustomViewConfiguration(
            customView: checkboxView,
            placement: .leading()
        ))]
    }

    func configure(title: String, isChecked: Bool, a11yIdentifier: String) {
        self.isChecked = isChecked
        titleLabel.text = title
        accessibilityIdentifier = a11yIdentifier
        isAccessibilityElement = true
        accessibilityLabel = title
        // .toggleButton makes VoiceOver speak the state in both directions; before iOS 17
        // an unchecked row can only fall back to reading as a plain button.
        if #available(iOS 17.0, *) {
            accessibilityTraits.insert(.toggleButton)
        } else {
            accessibilityTraits.insert(.button)
        }
        if isChecked {
            accessibilityTraits.insert(.selected)
        } else {
            accessibilityTraits.remove(.selected)
        }
        updateCheckbox()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        updateCheckbox()
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            self?.checkboxView.applyScaledMetrics()
        }
    }

    /// State and theme arrive on separate calls, so both funnel through here.
    private func updateCheckbox() {
        guard let theme else { return }
        checkboxView.update(isChecked: isChecked, theme: theme)
    }
}
