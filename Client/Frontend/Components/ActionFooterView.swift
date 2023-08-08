// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

struct ActionFooterViewModel {
    let title: String
    let actionTitle: String
    let a11yTitleIdentifier: String = AccessibilityIdentifiers.ActionFooter.title
    let a11yActionIdentifier: String = AccessibilityIdentifiers.ActionFooter.primaryAction
}

final class ActionFooterView: UIView, ThemeApplicable {
    private struct UX {
        static let labelSize: CGFloat = 13
        static let buttonSize: CGFloat = 13
        static let containerMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.labelSize)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.buttonSize)
        button.buttonEdgeSpacing = 0
        button.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.spacing = 0
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.containerMargins
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
        addSubview(stackView)
        stackView.addArrangedSubview(self.titleLabel)
        stackView.addArrangedSubview(self.primaryButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Common.Theme) {
        primaryButton.setTitleColor(theme.colors.actionPrimary, for: .normal)
        primaryButton.setTitleColor(theme.colors.actionPrimaryHover, for: .highlighted)
        titleLabel.textColor = theme.colors.textSecondary
    }
}
