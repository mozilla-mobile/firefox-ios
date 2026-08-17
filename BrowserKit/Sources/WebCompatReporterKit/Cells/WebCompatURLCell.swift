// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class WebCompatURLCell: UICollectionViewListCell,
                              ThemeApplicable,
                              ReusableCell,
                              UITextFieldDelegate,
                              Notifiable {
    private var editingEndedHandler: ((String) -> Void)?

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private lazy var textField: UITextField = .build { field in
        field.font = FXFontStyles.Regular.body.scaledFont()
        field.adjustsFontForContentSizeCategory = true
        field.keyboardType = .URL
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.delegate = self
    }

    private lazy var stackView: UIStackView = .build { stack in
        stack.spacing = WebCompatReporterUX.Spacing.interItem
    }

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
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textField)
        contentView.addSubview(stackView)
        let margins = contentView.layoutMarginsGuide
        // .defaultHigh avoids conflicting with the self-sizing pass.
        let topConstraint = stackView.topAnchor.constraint(equalTo: margins.topAnchor)
        let bottomConstraint = stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            topConstraint,
            bottomConstraint,
            stackView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            )
        ])
        updateStackAxis()
    }

    private func updateStackAxis() {
        applyStackLayout(isAccessibilityCategory: traitCollection.preferredContentSizeCategory.isAccessibilityCategory)
    }

    func applyStackLayout(isAccessibilityCategory: Bool) {
        stackView.axis = isAccessibilityCategory ? .vertical : .horizontal
        stackView.alignment = isAccessibilityCategory ? .fill : .center
    }

    func configure(
        title: String,
        text: String,
        a11yIdentifier: String,
        onEditingEnded: @escaping (String) -> Void
    ) {
        editingEndedHandler = onEditingEnded
        titleLabel.text = title
        textField.accessibilityIdentifier = a11yIdentifier
        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = title
        // The value round-trips on editing-end, so don't overwrite mid-edit.
        if !textField.isFirstResponder {
            textField.text = text
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textSecondary
        textField.textColor = theme.colors.textPrimary
        textField.tintColor = theme.colors.actionPrimary
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            self?.updateStackAxis()
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        editingEndedHandler?(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
