// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class PasswordGeneratorPasswordFieldView: UIView, ThemeApplicable, Notifiable {
    private enum UX {
        static let passwordFieldBorderWidth: CGFloat = 1
        static let passwordFieldCornerRadius: CGFloat = 4
        static let passwordFieldHorizontalPadding: CGFloat = 16
        static let passwordFieldVerticalPadding: CGFloat = 10
        static let passwordLabelAndButtonSpacing: CGFloat = 10
        static let passwordRefreshButtonHeight: CGFloat = 18
        static let passwordHiddenAlpha: CGFloat = 0
        static let passwordVisibleAlpha: CGFloat = 1
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private var scaledRefreshButtonSize = UIFontMetrics.default.scaledValue(for: UX.passwordRefreshButtonHeight)

    private lazy var passwordRefreshButtonWidthConstraint = passwordRefreshButton.widthAnchor.constraint(
        equalToConstant: scaledRefreshButtonSize)
    private lazy var passwordRefreshButtonHeightConstraint = passwordRefreshButton.heightAnchor.constraint(
        equalToConstant: scaledRefreshButtonSize)

    private lazy var passwordLabel: UILabel = .build { label in
        label.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordlabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = FXFontStyles.Regular.body.scaledFont()
    }

    private lazy var passwordRefreshButton: UIButton = .build { button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.arrowClockwise)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.accessibilityLabel = .PasswordGenerator.RefreshPasswordButtonA11yLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordRefreshButton
        button.addTarget(self, action: #selector(self.refreshOnClick), for: .touchUpInside)
    }

    var refreshPasswordButtonOnClick: (() -> Void)?

    convenience init(frame: CGRect, notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.init(frame: frame)
        self.notificationCenter = notificationCenter
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = UX.passwordFieldBorderWidth
        self.layer.cornerRadius = UX.passwordFieldCornerRadius
        self.accessibilityIdentifier = AccessibilityIdentifiers.PasswordGenerator.passwordField
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        self.addSubviews(passwordLabel, passwordRefreshButton)
        NSLayoutConstraint.activate([
            passwordLabel.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: UX.passwordFieldHorizontalPadding),
            passwordLabel.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.passwordFieldVerticalPadding),
            passwordLabel.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -UX.passwordFieldVerticalPadding),
            passwordRefreshButton.leadingAnchor.constraint(
                greaterThanOrEqualTo: passwordLabel.trailingAnchor,
                constant: UX.passwordLabelAndButtonSpacing),
            passwordRefreshButton.trailingAnchor.constraint(
                equalTo: self.trailingAnchor,
                constant: -UX.passwordFieldHorizontalPadding),
            passwordRefreshButton.centerYAnchor.constraint(
                equalTo: self.centerYAnchor),
            passwordRefreshButtonWidthConstraint,
            passwordRefreshButtonHeightConstraint,
        ])
    }

    func configure(password: String) {
        passwordLabel.text = password
        passwordLabel.accessibilityAttributedLabel = generateAccessibilityAttributedLabel(password: password)
        self.becomeFirstResponder()
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(self.handleLongPress))
        longPressGesture.cancelsTouchesInView = true
        self.addGestureRecognizer(longPressGesture)
    }

    private func generateAccessibilityAttributedLabel(password: String) -> NSMutableAttributedString {
        let fullString = String(format: .PasswordGenerator.PasswordReadoutPrefaceA11y, password)
        let attributedString = NSMutableAttributedString(string: fullString)
        let rangeOfPassword = (attributedString.string as NSString).range(of: password)
        attributedString.addAttributes([.accessibilitySpeechSpellOut: true], range: rangeOfPassword)
        return attributedString
    }

    func setPasswordHidden(_ hidden: Bool) {
        passwordLabel.alpha = hidden ? UX.passwordHiddenAlpha : UX.passwordVisibleAlpha
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let copyItem = UIMenuItem(title: .PasswordGenerator.CopyPasswordButtonLabel, action: #selector(self.copyText))
        let menuController = UIMenuController.shared
        menuController.menuItems = [copyItem]
        menuController.showMenu(from: passwordLabel, rect: passwordLabel.bounds)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc
    private func copyText(_ sender: Any?) {
        UIPasteboard.general.string = passwordLabel.text
    }

    @objc
    private func refreshOnClick() {
        self.refreshPasswordButtonOnClick?()
    }

    func applyTheme(theme: any Common.Theme) {
        self.backgroundColor = theme.colors.layer2
        self.layer.borderColor = theme.colors.borderPrimary.cgColor
        passwordLabel.textColor = theme.colors.textPrimary
        passwordRefreshButton.tintColor = theme.colors.iconPrimary
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            applyDynamicFontChange()
        default: break
        }
    }

    private func applyDynamicFontChange() {
        scaledRefreshButtonSize = UIFontMetrics.default.scaledValue(for: UX.passwordRefreshButtonHeight)
        passwordRefreshButtonHeightConstraint.constant = scaledRefreshButtonSize
        passwordRefreshButtonWidthConstraint.constant = scaledRefreshButtonSize
        setNeedsLayout()
        layoutIfNeeded()
    }
}
