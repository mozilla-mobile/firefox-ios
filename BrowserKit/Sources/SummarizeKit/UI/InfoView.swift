// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

struct InfoViewModel {
    let title: NSAttributedString?
    let titleA11yId: String
    let actionButtonLabel: String
    let actionButtonA11yId: String
    let actionButtonCallback: () -> Void
    let linkCallback: (URL) -> Void
}

class InfoView: UIView,
                UITextViewDelegate,
                 ThemeApplicable {
    private struct UX {
        static let labelHorizontalPadding: CGFloat = 44.0
        static let actionButtonTopPadding: CGFloat = 32.0
        static let actionButtonInsets = NSDirectionalEdgeInsets(
            top: 12.0,
            leading: 32.0,
            bottom: 12.0,
            trailing: 32.0
        )
    }
    private let contentView: UITextView = .build {
        $0.adjustsFontForContentSizeCategory = true
        $0.isEditable = false
        $0.isScrollEnabled = false
        $0.textAlignment = .center
    }
    private let actionButton: UIButton = .build {
        // This checks for Xcode 26 sdk availability thus we can compile on older Xcode version too
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        #else
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        #endif
        $0.configuration?.contentInsets = UX.actionButtonInsets
    }
    private var viewModel: InfoViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.delegate = self
        addSubviews(contentView, actionButton)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.labelHorizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.labelHorizontalPadding),

            actionButton.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: UX.actionButtonTopPadding),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            actionButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        contentView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        actionButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func configure(viewModel: InfoViewModel) {
        self.viewModel = viewModel
        contentView.attributedText = viewModel.title
        contentView.accessibilityIdentifier = viewModel.titleA11yId
        actionButton.configuration?.title = viewModel.actionButtonLabel
        actionButton.accessibilityIdentifier = viewModel.actionButtonA11yId
        actionButton.addAction(UIAction(handler: { _ in
            viewModel.actionButtonCallback()
        }), for: .touchUpInside)
    }

    // MARK: - UITextViewDelegate
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        viewModel?.linkCallback(URL)
        return false
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        contentView.textColor = theme.colors.textOnDark
        contentView.backgroundColor = .clear
        if #unavailable(iOS 26) {
            actionButton.configuration?.baseBackgroundColor = theme.colors.textOnDark
            actionButton.configuration?.baseForegroundColor = theme.colors.textOnLight
        } else {
            actionButton.configuration?.baseForegroundColor = theme.colors.textOnDark
        }
        contentView.linkTextAttributes = [
            .font: FXFontStyles.Regular.subheadline.scaledFont(),
            .foregroundColor: theme.colors.textOnDark.withAlphaComponent(0.8),
            .underlineColor: theme.colors.textOnDark.withAlphaComponent(0.8),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
}
