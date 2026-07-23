// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Editable URL row: a leading label and a single-line text field. Long URLs scroll
/// horizontally, matching the native form-field behavior (Settings/Contacts). The label
/// and field stack vertically at accessibility text sizes. Reports the typed value on
/// editing-end, not per keystroke, so the connected screen re-renders only after resign.
final class WebCompatURLCell: UICollectionViewListCell,
                              ThemeApplicable,
                              ReusableCell,
                              UITextFieldDelegate,
                              Notifiable {
    private var editingEndedHandler: ((String) -> Void)?
    private var placeholder = ""

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
        // Native clear button carries a system-localized accessibility label for free.
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
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: margins.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            stackView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            )
        ])
        updateStackAxis()
    }

    private func updateStackAxis() {
        applyStackLayout(isAccessibilityCategory: traitCollection.preferredContentSizeCategory.isAccessibilityCategory)
    }

    /// Horizontal (field beside the label, right-aligned) at standard sizes; vertical
    /// (field full-width below the label) at accessibility sizes, where a single row is
    /// too cramped.
    func applyStackLayout(isAccessibilityCategory: Bool) {
        stackView.axis = isAccessibilityCategory ? .vertical : .horizontal
        stackView.alignment = isAccessibilityCategory ? .fill : .center
        textField.textAlignment = isAccessibilityCategory ? .natural : .right
    }

    func configure(
        title: String,
        text: String,
        placeholder: String,
        a11yIdentifier: String,
        onEditingEnded: @escaping (String) -> Void
    ) {
        editingEndedHandler = onEditingEnded
        self.placeholder = placeholder
        titleLabel.text = title
        textField.accessibilityIdentifier = a11yIdentifier
        // The field is the accessibility element; carry the label onto it so
        // VoiceOver announces "<title>, text field" instead of a bare field.
        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = title
        // Don't overwrite the field mid-edit; the value round-trips on end.
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
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
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
