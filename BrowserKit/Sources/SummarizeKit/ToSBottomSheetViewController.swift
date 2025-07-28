// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import ComponentLibrary
import Common

public struct ToSBottomSheetViewModel {
    let titleLabel: String
    let descriptionLabel: String
    let linkButtonLabel: String
    let linkButtonURL: URL?
    let allowButtonTitle: String
    let allowButtonA11yId: String
    let cancelButtonTitle: String
    let cancelButtonA11yId: String
    let onRequestOpenURL: ((URL?) -> Void)?
    let onAllowButtonPressed: (() -> Void)?

    public init(
        titleLabel: String,
        descriptionLabel: String,
        linkButtonLabel: String,
        linkButtonURL: URL?,
        allowButtonTitle: String,
        allowButtonA11yId: String,
        cancelButtonTitle: String,
        cancelButtonA11yId: String,
        onRequestOpenURL: ((URL?) -> Void)?,
        onAllowButtonPressed: (() -> Void)?
    ) {
        self.titleLabel = titleLabel
        self.descriptionLabel = descriptionLabel
        self.linkButtonLabel = linkButtonLabel
        self.linkButtonURL = linkButtonURL
        self.onAllowButtonPressed = onAllowButtonPressed
        self.onRequestOpenURL = onRequestOpenURL
        self.allowButtonTitle = allowButtonTitle
        self.allowButtonA11yId = allowButtonA11yId
        self.cancelButtonTitle = cancelButtonTitle
        self.cancelButtonA11yId = cancelButtonA11yId
    }
}

public class ToSBottomSheetViewController: UIViewController,
                                           UITextViewDelegate,
                                           BottomSheetChild,
                                           Themeable {
    private struct UX {
        static let contentHorizontalPadding: CGFloat = 29.0
        static let titleLabelTopPadding: CGFloat = 30.0
    }
    public var themeManager: any Common.ThemeManager
    public var themeObserver: (any NSObjectProtocol)?
    public var notificationCenter: any Common.NotificationProtocol
    
    public var currentWindowUUID: Common.WindowUUID?
    private let viewModel: ToSBottomSheetViewModel

    private let titleLabel: UILabel = .build {
        $0.textAlignment = .center
        $0.font = FXFontStyles.Bold.headline.scaledFont()
    }
    private let descriptionLabel: UITextView = .build {
        $0.textAlignment = .center
        $0.isEditable = false
        $0.isScrollEnabled = false
    }
    private let allowButton: PrimaryRoundedButton = .build()
    private let cancelButton: SecondaryRoundedButton = .build()

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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = viewModel.titleLabel
        titleLabel.accessibilityLabel = viewModel.titleLabel

        let description = NSMutableAttributedString(string: "\(viewModel.descriptionLabel) \(viewModel.linkButtonLabel)")
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

        descriptionLabel.delegate = self
        descriptionLabel.attributedText = description

        allowButton.configure(
            viewModel: PrimaryRoundedButtonViewModel(
                title: viewModel.allowButtonTitle,
                a11yIdentifier: viewModel.allowButtonA11yId
            )
        )
        allowButton.addAction(UIAction(handler: { [weak self] _ in
            self?.viewModel.onAllowButtonPressed?()
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        cancelButton.configure(
            viewModel: SecondaryRoundedButtonViewModel(
                title: viewModel.cancelButtonTitle,
                a11yIdentifier: viewModel.cancelButtonA11yId
            )
        )
        cancelButton.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)

        view.addSubviews(titleLabel, descriptionLabel, allowButton, cancelButton)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.titleLabelTopPadding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),

            allowButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            allowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            allowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),

            cancelButton.topAnchor.constraint(equalTo: allowButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.contentHorizontalPadding),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.contentHorizontalPadding),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        applyTheme()
    }

    public func willDismiss() {}

    // MARK: - UITextViewDelegate
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        dismiss(animated: true)
        viewModel.onRequestOpenURL?(URL)
        return false
    }

    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textSecondary
        descriptionLabel.backgroundColor = .clear
        allowButton.applyTheme(theme: theme)
        cancelButton.applyTheme(theme: theme)
    }
}
