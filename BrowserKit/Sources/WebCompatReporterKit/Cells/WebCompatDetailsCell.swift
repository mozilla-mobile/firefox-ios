// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Optional multiline details row. Scrolling is disabled so the text view grows
/// with its content and the self-sizing cell tracks the height; the value is
/// reported on editing-end. `onHeightChange` lets the host re-measure as the user types.
final class WebCompatDetailsCell: UICollectionViewListCell, UITextViewDelegate {
    private var editingEndedHandler: ((String) -> Void)?
    private var heightChangeHandler: (() -> Void)?
    private var placeholderText = ""

    private lazy var textView: UITextView = .build { textView in
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
    }

    private lazy var placeholderLabel: UILabel = .build { label in
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        // Decorative; the placeholder is surfaced as the text view's value when empty.
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
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textView.topAnchor.constraint(equalTo: margins.topAnchor),
            textView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            textView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.DetailsField.minimumHeight
            ),

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor)
        ])
    }

    func configure(
        text: String,
        placeholder: String,
        accessibilityLabel: String,
        theme: Theme,
        onEditingEnded: @escaping (String) -> Void,
        onHeightChange: @escaping () -> Void
    ) {
        editingEndedHandler = onEditingEnded
        heightChangeHandler = onHeightChange
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        if !textView.isFirstResponder {
            textView.text = text
        }
        textView.textColor = theme.colors.textPrimary
        textView.tintColor = theme.colors.actionPrimary
        textView.accessibilityLabel = accessibilityLabel
        placeholderText = placeholder
        placeholderLabel.text = placeholder
        placeholderLabel.textColor = theme.colors.textSecondary
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateAccessibilityValue()
    }

    private func updateAccessibilityValue() {
        textView.accessibilityValue = textView.text.isEmpty ? placeholderText : textView.text
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateAccessibilityValue()
        heightChangeHandler?()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        editingEndedHandler?(textView.text ?? "")
    }
}
