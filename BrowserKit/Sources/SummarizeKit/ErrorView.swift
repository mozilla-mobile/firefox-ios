// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

struct ErrorViewModel {
    let title: String
    let titleA11yId: String
    let actionButtonLabel: String
    let actionButtonA11yId: String
    let actionButtonCallback: () -> Void
}

class ErrorView: UIView,
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
    private let label: UILabel = .build {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubviews(label, actionButton)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.labelHorizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.labelHorizontalPadding),

            actionButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: UX.actionButtonTopPadding),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            actionButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        actionButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func configure(viewModel: ErrorViewModel) {
        label.text = viewModel.title
        label.accessibilityIdentifier = viewModel.titleA11yId
        actionButton.configuration?.title = viewModel.actionButtonLabel
        actionButton.accessibilityIdentifier = viewModel.actionButtonA11yId
        actionButton.addAction(UIAction(handler: { _ in
            viewModel.actionButtonCallback()
        }), for: .touchUpInside)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        label.textColor = theme.colors.textOnDark
        if #unavailable(iOS 26) {
            actionButton.configuration?.baseBackgroundColor = theme.colors.actionTabActive
        }
        actionButton.configuration?.baseForegroundColor = theme.colors.textPrimary
    }
}
