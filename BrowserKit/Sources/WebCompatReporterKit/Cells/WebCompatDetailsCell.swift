// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Optional multiline details row: a fixed-height box (scaled with Dynamic Type) whose
/// text view scrolls internally once the content exceeds it. Value reported on editing-end.
final class WebCompatDetailsCell: UICollectionViewListCell,
                                  ThemeApplicable,
                                  ReusableCell,
                                  UITextViewDelegate,
                                  Notifiable {
    private var editingEndedHandler: ((String) -> Void)?
    private var heightConstraint: NSLayoutConstraint?

    private var scaledMinimumHeight: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.DetailsField.minimumHeight)
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
        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
        let margins = contentView.layoutMarginsGuide
        let height = textView.heightAnchor.constraint(equalToConstant: scaledMinimumHeight)
        heightConstraint = height
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textView.topAnchor.constraint(equalTo: margins.topAnchor),
            textView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            height,

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
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateAccessibilityValue()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        textView.textColor = theme.colors.textPrimary
        textView.tintColor = theme.colors.actionPrimary
        placeholderLabel.textColor = theme.colors.textSecondary
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            guard let self else { return }
            self.heightConstraint?.constant = self.scaledMinimumHeight
        }
    }

    /// Only the typed text is exposed as the value; the placeholder is a visual
    /// hint, so VoiceOver announces the field label once rather than twice.
    private func updateAccessibilityValue() {
        textView.accessibilityValue = textView.text.isEmpty ? nil : textView.text
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateAccessibilityValue()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        editingEndedHandler?(textView.text ?? "")
    }
}
