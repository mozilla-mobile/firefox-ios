// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Optional multiline details row: a box sized to a fixed number of text lines whose
/// text view scrolls internally once the content exceeds it. Value reported on editing-end.
final class WebCompatDetailsCell: UICollectionViewListCell,
                                  ThemeApplicable,
                                  ReusableCell,
                                  UITextViewDelegate {
    private var editingEndedHandler: ((String) -> Void)?

    /// Carries the current body line height so Auto Layout scales the box with Dynamic Type
    /// on its own; the label itself is never drawn.
    private lazy var lineHeightSizingLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = " "
        label.isHidden = true
    }

    private lazy var textView: UITextView = .build { textView in
        textView.font = FXFontStyles.Regular.body.scaledFont()
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
    }

    private lazy var placeholderLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        // Purely a visual hint; the text view owns the accessibility label/value.
        label.isAccessibilityElement = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
        contentView.addSubview(lineHeightSizingLabel)
        let margins = contentView.layoutMarginsGuide
        let verticalInset = WebCompatReporterUX.Card.contentInset
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalInset),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalInset),
            textView.heightAnchor.constraint(
                equalTo: lineHeightSizingLabel.heightAnchor,
                multiplier: CGFloat(WebCompatReporterUX.DetailsField.visibleLineCount)
            ),

            lineHeightSizingLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            lineHeightSizingLabel.topAnchor.constraint(equalTo: textView.topAnchor),

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor)
        ])
    }

    func configure(
        text: String,
        placeholder: String,
        accessibilityLabel: String,
        a11yIdentifier: String,
        onEditingEnded: @escaping (String) -> Void
    ) {
        editingEndedHandler = onEditingEnded
        if !textView.isFirstResponder {
            textView.text = text
        }
        textView.accessibilityLabel = accessibilityLabel
        textView.accessibilityIdentifier = a11yIdentifier
        placeholderLabel.text = placeholder
        updatePlaceholderVisibility()
        updateAccessibilityValue()
    }

    private var currentText: String {
        return textView.text ?? ""
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !currentText.isEmpty
    }

    /// Only the typed text is exposed as the value; the placeholder is a visual
    /// hint, so VoiceOver announces the field label once rather than twice.
    private func updateAccessibilityValue() {
        textView.accessibilityValue = currentText.isEmpty ? nil : currentText
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        textView.textColor = theme.colors.textPrimary
        textView.tintColor = theme.colors.actionPrimary
        placeholderLabel.textColor = theme.colors.textSecondary
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateAccessibilityValue()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        editingEndedHandler?(currentText)
    }
}
