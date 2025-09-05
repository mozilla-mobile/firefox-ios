// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import ComponentLibrary
import Common

public struct ToSBottomSheetViewModel {
    let titleLabel: String
    let titleLabelA11yId: String
    let descriptionText: String
    let descriptionTextA11yId: String
    let linkButtonLabel: String
    let linkButtonURL: URL?
    let allowButtonTitle: String
    let allowButtonA11yId: String
    let allowButtonA11yLabel: String
    let cancelButtonTitle: String
    let cancelButtonA11yId: String
    let cancelButtonA11yLabel: String
    let onRequestOpenURL: ((URL?) -> Void)?
    let onAllowButtonPressed: (() -> Void)?
    let onDismiss: (() -> Void)?

    public init(
        titleLabel: String,
        titleLabelA11yId: String,
        descriptionText: String,
        descriptionTextA11yId: String,
        linkButtonLabel: String,
        linkButtonURL: URL?,
        allowButtonTitle: String,
        allowButtonA11yId: String,
        allowButtonA11yLabel: String,
        cancelButtonTitle: String,
        cancelButtonA11yId: String,
        cancelButtonA11yLabel: String,
        onRequestOpenURL: ((URL?) -> Void)?,
        onAllowButtonPressed: (() -> Void)?,
        onDismiss: (() -> Void)?
    ) {
        self.titleLabel = titleLabel
        self.titleLabelA11yId = titleLabelA11yId
        self.descriptionText = descriptionText
        self.descriptionTextA11yId = descriptionTextA11yId
        self.linkButtonLabel = linkButtonLabel
        self.linkButtonURL = linkButtonURL
        self.onAllowButtonPressed = onAllowButtonPressed
        self.onRequestOpenURL = onRequestOpenURL
        self.allowButtonTitle = allowButtonTitle
        self.allowButtonA11yId = allowButtonA11yId
        self.allowButtonA11yLabel = allowButtonA11yLabel
        self.cancelButtonTitle = cancelButtonTitle
        self.cancelButtonA11yId = cancelButtonA11yId
        self.cancelButtonA11yLabel = cancelButtonA11yLabel
        self.onDismiss = onDismiss
    }
}

public class ToSBottomSheetViewController: UIViewController,
                                           UITextViewDelegate,
                                           BottomSheetChild,
                                           Notifiable,
                                           Themeable {
    private struct UX {
        static let contentHorizontalPadding: CGFloat = 29.0
        static let titleLabelTopPadding: CGFloat = 30.0
        static let descriptionLabelTopPadding: CGFloat = 20.0
        static let allowButtonTopPadding: CGFloat = 20.0
        static let cancelButtonTopPadding: CGFloat = 10.0
        static let cancelButtonBottomPadding: CGFloat = 16.0
    }
    public var themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var notificationCenter: any Common.NotificationProtocol

    public var currentWindowUUID: Common.WindowUUID?
    private let viewModel: ToSBottomSheetViewModel
    public weak var delegate: BottomSheetDelegate?

    private let titleLabel: UILabel = .build {
        $0.textAlignment = .center
        $0.font = FXFontStyles.Bold.headline.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let descriptionTextView: UITextView = .build {
        $0.textAlignment = .center
        $0.isEditable = false
        $0.isScrollEnabled = false
        $0.adjustsFontForContentSizeCategory = true
    }
    private let allowButton: PrimaryRoundedButton = .build()
    private let cancelButton: SecondaryRoundedButton = .build()
    private var titleLabelTopConstraint: NSLayoutConstraint?

    public init(
        viewModel: ToSBottomSheetViewModel,
        themeManager: any Common.ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: any Common.NotificationProtocol = NotificationCenter.default,
        windowUUID: WindowUUID
    ) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.currentWindowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setupLayout()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    private func configure() {
        titleLabel.text = viewModel.titleLabel
        titleLabel.accessibilityLabel = viewModel.titleLabel
        titleLabel.accessibilityIdentifier = viewModel.titleLabelA11yId

        let description = NSMutableAttributedString(string: "\(viewModel.descriptionText) \(viewModel.linkButtonLabel)")
        let fullTextRange = NSRange(location: 0, length: description.length)
        let linkTextRange = (description.string as NSString).range(of: viewModel.linkButtonLabel)
        description.addAttributes(
            [
                .link: viewModel.linkButtonURL as Any,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ],
            range: linkTextRange
        )
        description.addAttribute(.font, value: FXFontStyles.Regular.subheadline.scaledFont(), range: fullTextRange)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        description.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullTextRange)

        descriptionTextView.delegate = self
        descriptionTextView.attributedText = description
        descriptionTextView.accessibilityIdentifier = viewModel.descriptionTextA11yId

        allowButton.configure(
            viewModel: PrimaryRoundedButtonViewModel(
                title: viewModel.allowButtonTitle,
                a11yIdentifier: viewModel.allowButtonA11yId
            )
        )
        allowButton.accessibilityLabel = viewModel.allowButtonA11yLabel
        allowButton.addAction(UIAction(handler: { [weak self] _ in
            self?.viewModel.onAllowButtonPressed?()
        }), for: .touchUpInside)
        cancelButton.configure(
            viewModel: SecondaryRoundedButtonViewModel(
                title: viewModel.cancelButtonTitle,
                a11yIdentifier: viewModel.cancelButtonA11yId
            )
        )
        cancelButton.accessibilityLabel = viewModel.cancelButtonA11yLabel
        cancelButton.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        applyTheme()
    }

    private func setupLayout() {
        view.addSubviews(titleLabel, descriptionTextView, allowButton, cancelButton)
        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                                                  constant: UX.titleLabelTopPadding)
        titleLabelTopConstraint?.isActive = true
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),

            descriptionTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                     constant: UX.descriptionLabelTopPadding),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                         constant: UX.contentHorizontalPadding),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                          constant: -UX.contentHorizontalPadding),

            allowButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: UX.allowButtonTopPadding),
            allowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            allowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),

            cancelButton.topAnchor.constraint(equalTo: allowButton.bottomAnchor, constant: UX.cancelButtonTopPadding),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                 constant: -UX.cancelButtonBottomPadding)
        ])
        updateDynamicFontSize()
    }

    private func updateDynamicFontSize() {
        let bottomSheetHeaderHeight = delegate?.getBottomSheetHeaderHeight() ?? 0.0
        titleLabelTopConstraint?.constant = bottomSheetHeaderHeight + UX.titleLabelTopPadding
    }

    public func willDismiss() {
        viewModel.onDismiss?()
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let delegate {
            delegate.dismissSheetViewController(completion: completion)
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
    }

    // MARK: - Notifiable
    public func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }

        ensureMainThread {
            self.updateDynamicFontSize()
        }
    }

    // MARK: - UITextViewDelegate
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        viewModel.onRequestOpenURL?(URL)
        dismiss(animated: true)
        return false
    }

    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        titleLabel.textColor = theme.colors.textPrimary
        descriptionTextView.textColor = theme.colors.textSecondary
        descriptionTextView.backgroundColor = .clear
        allowButton.applyTheme(theme: theme)
        cancelButton.applyTheme(theme: theme)
    }
}
