// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct ActionFooterViewModel {
    let title: String
    let actionTitle: String
    let a11yTitleIdentifier: String
    let a11yActionIdentifier: String

    init(title: String,
         actionTitle: String,
         a11yTitleIdentifier: String = AccessibilityIdentifiers.ActionFooter.title,
         a11yActionIdentifier: String = AccessibilityIdentifiers.ActionFooter.primaryAction) {
        self.title = title
        self.actionTitle = actionTitle
        self.a11yTitleIdentifier = a11yTitleIdentifier
        self.a11yActionIdentifier = a11yActionIdentifier
    }
}

final class ActionFooterView: UIView, ThemeApplicable {
    private struct UX {
        static let labelSize: CGFloat = 13
        static let buttonSize: CGFloat = 13
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.labelSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.buttonSize)
        button.buttonEdgeSpacing = 0
        button.contentHorizontalAlignment = .leading
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    func configure(viewModel: ActionFooterViewModel) {
        titleLabel.text = viewModel.title
        primaryButton.setTitle(viewModel.actionTitle, for: .normal)

        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier
        primaryButton.accessibilityIdentifier = viewModel.a11yActionIdentifier
    }

    private func setupLayout() {
        addSubview(titleLabel)
        addSubview(primaryButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: primaryButton.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            primaryButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Common.Theme) {
        primaryButton.setTitleColor(theme.colors.actionPrimary, for: .normal)
        primaryButton.setTitleColor(theme.colors.actionPrimaryHover, for: .highlighted)
        titleLabel.textColor = theme.colors.textSecondary
    }
}
