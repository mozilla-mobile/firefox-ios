// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Redux
import Shared
import UIKit

final class AutoTranslatePromptView: UIView, ThemeApplicable, Notifiable {
    private struct UX {
        static let borderThickness: CGFloat = 1.0
        static let contentPadding = NSDirectionalEdgeInsets(
            top: 14,
            leading: 16,
            bottom: -14,
            trailing: -16
        )
        static let contentSpacing: CGFloat = 8
    }

    private let windowUUID: WindowUUID
    var notificationCenter: NotificationProtocol

    private var topBorderView: UIView = .build()

    private var messageLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
        label.text = .Translations.AutoTranslatePrompt.Message
    }

    private lazy var enableButton: UIButton = .build { button in
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        button.setTitle(.Translations.AutoTranslatePrompt.EnableButton, for: .normal)
        button.addTarget(self, action: #selector(self.didTapEnable), for: .touchUpInside)
    }

    private lazy var closeButton: CloseButton = .build { button in
        let viewModel = CloseButtonViewModel(
            a11yLabel: .Microsurvey.Prompt.CloseButtonAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.Translations.AutoTranslatePrompt.closeButton
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.didTapDismiss), for: .touchUpInside)
    }

    private lazy var contentRow: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = UX.contentSpacing
    }

    init(windowUUID: WindowUUID, notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        super.init(frame: .zero)
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentRow.addArrangedSubview(messageLabel)
        contentRow.addArrangedSubview(enableButton)
        contentRow.addArrangedSubview(closeButton)

        addSubview(topBorderView)
        addSubview(contentRow)

        NSLayoutConstraint.activate([
            topBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorderView.topAnchor.constraint(equalTo: topAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: UX.borderThickness),

            contentRow.topAnchor.constraint(equalTo: topBorderView.bottomAnchor, constant: UX.contentPadding.top),
            contentRow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.contentPadding.bottom),
            contentRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentPadding.leading),
            contentRow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: UX.contentPadding.trailing),
        ])
    }

    @objc
    private func didTapEnable() {
        store.dispatch(TranslationsAction(windowUUID: windowUUID, actionType: TranslationsActionType.didTapEnableAutoTranslate))
    }

    @objc
    private func didTapDismiss() {
        store.dispatch(TranslationsAction(windowUUID: windowUUID, actionType: TranslationsActionType.didDismissAutoTranslatePrompt))
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        topBorderView.backgroundColor = theme.colors.borderPrimary
        messageLabel.textColor = theme.colors.textPrimary
        enableButton.setTitleColor(theme.colors.textAccent, for: .normal)
        closeButton.tintColor = theme.colors.textSecondary
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.messageLabel.font = FXFontStyles.Regular.body.scaledFont()
                self.enableButton.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
            }
        default:
            break
        }
    }
}
