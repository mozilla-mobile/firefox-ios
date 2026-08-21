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
    private var iconWidthConstraint: NSLayoutConstraint?
    private var iconHeightConstraint: NSLayoutConstraint?

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

    private lazy var errorLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private lazy var errorIcon: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.warning)?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
    }

    private lazy var errorStackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = WebCompatReporterUX.Spacing.interItem
        stack.isHidden = true
    }

    private lazy var fieldStackView: UIStackView = .build { stack in
        stack.spacing = WebCompatReporterUX.Spacing.interItem
    }

    private lazy var containerStackView: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = WebCompatReporterUX.Spacing.interItem
    }

    private var scaledIconSize: CGFloat {
        return UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.ErrorMessage.iconSize)
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
        fieldStackView.addArrangedSubview(titleLabel)
        fieldStackView.addArrangedSubview(textField)
        errorStackView.addArrangedSubview(errorIcon)
        errorStackView.addArrangedSubview(errorLabel)
        containerStackView.addArrangedSubview(fieldStackView)
        containerStackView.addArrangedSubview(errorStackView)
        contentView.addSubview(containerStackView)
        let margins = contentView.layoutMarginsGuide
        // .defaultHigh avoids conflicting with the self-sizing pass.
        let topConstraint = containerStackView.topAnchor.constraint(equalTo: margins.topAnchor)
        let bottomConstraint = containerStackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        topConstraint.priority = .defaultHigh
        bottomConstraint.priority = .defaultHigh
        let iconWidthConstraint = errorIcon.widthAnchor.constraint(equalToConstant: scaledIconSize)
        let iconHeightConstraint = errorIcon.heightAnchor.constraint(equalToConstant: scaledIconSize)
        self.iconWidthConstraint = iconWidthConstraint
        self.iconHeightConstraint = iconHeightConstraint
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            topConstraint,
            bottomConstraint,
            fieldStackView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: WebCompatReporterUX.Control.minimumTapTarget
            ),
            iconWidthConstraint,
            iconHeightConstraint
        ])
        updateStackAxis()
    }

    private func updateStackAxis() {
        applyStackLayout(isAccessibilityCategory: traitCollection.preferredContentSizeCategory.isAccessibilityCategory)
    }

    func applyStackLayout(isAccessibilityCategory: Bool) {
        fieldStackView.axis = isAccessibilityCategory ? .vertical : .horizontal
        fieldStackView.alignment = isAccessibilityCategory ? .fill : .center
    }

    func configure(
        title: String,
        text: String,
        errorMessage: String?,
        a11yIdentifier: String,
        onEditingEnded: @escaping (String) -> Void
    ) {
        editingEndedHandler = onEditingEnded
        titleLabel.text = title
        textField.accessibilityIdentifier = a11yIdentifier
        titleLabel.isAccessibilityElement = false
        textField.accessibilityLabel = [title, errorMessage].compactMap { $0 }.joined(separator: ", ")
        errorLabel.text = errorMessage
        setErrorRowHidden(errorMessage == nil)
        // The value round-trips on editing-end, so don't overwrite mid-edit.
        if !textField.isFirstResponder {
            textField.text = text
        }
    }

    /// Outside the list's reconfigure animation, or the stack squashes against the animating height.
    private func setErrorRowHidden(_ isHidden: Bool) {
        guard errorStackView.isHidden != isHidden else { return }
        UIView.performWithoutAnimation {
            errorStackView.isHidden = isHidden
            contentView.layoutIfNeeded()
        }
        guard !isHidden, let message = errorLabel.text else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundConfiguration = .listGroupedCell()
        backgroundConfiguration?.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textSecondary
        textField.textColor = theme.colors.textPrimary
        textField.tintColor = theme.colors.actionPrimary
        errorLabel.textColor = theme.colors.textCritical
        errorIcon.tintColor = theme.colors.textCritical
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            guard let self else { return }
            self.updateStackAxis()
            self.iconWidthConstraint?.constant = self.scaledIconSize
            self.iconHeightConstraint?.constant = self.scaledIconSize
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
