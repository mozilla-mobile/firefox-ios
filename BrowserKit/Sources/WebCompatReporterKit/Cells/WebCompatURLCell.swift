// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Editable URL row: leading label, trailing text field. Reports the typed value
/// on editing-end, not per keystroke, so the connected screen re-renders only
/// after the field resigns.
final class WebCompatURLCell: UICollectionViewListCell, UITextFieldDelegate {
    private var editingEndedHandler: ((String) -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textAlignment = .right
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
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
        contentView.addSubview(textField)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: margins.centerYAnchor),

            textField.leadingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor,
                constant: WebCompatReporterUX.Spacing.interItem
            ),
            textField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textField.topAnchor.constraint(equalTo: margins.topAnchor),
            textField.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            textField.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            )
        ])
    }

    func configure(
        title: String,
        text: String,
        placeholder: String,
        theme: Theme,
        onEditingEnded: @escaping (String) -> Void
    ) {
        editingEndedHandler = onEditingEnded
        titleLabel.text = title
        titleLabel.textColor = theme.colors.textSecondary
        // The field is the accessibility element; carry the label onto it so
        // VoiceOver announces "<title>, text field" instead of a bare field.
        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = title
        // Don't overwrite the field mid-edit; the value round-trips on end.
        if !textField.isFirstResponder {
            textField.text = text
        }
        textField.textColor = theme.colors.textPrimary
        textField.tintColor = theme.colors.actionPrimary
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: theme.colors.textSecondary]
        )
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
