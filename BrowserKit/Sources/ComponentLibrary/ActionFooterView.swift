// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public struct ActionFooterViewModel {
    let title: String
    let actionTitle: String
    let a11yTitleIdentifier: String
    let a11yActionIdentifier: String
    let onTap: (() -> Void)?

    public init(
        title: String,
        actionTitle: String,
        a11yTitleIdentifier: String,
        a11yActionIdentifier: String,
        onTap: (() -> Void)?
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.a11yTitleIdentifier = a11yTitleIdentifier
        self.a11yActionIdentifier = a11yActionIdentifier
        self.onTap = onTap
    }
}

public final class ActionFooterView: UIView, ThemeApplicable {
    private struct UX {
        static let labelSize: CGFloat = 13
        static let buttonSize: CGFloat = 13
    }

    private var viewModel: ActionFooterViewModel?

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
        button.addTarget(self, action: #selector(self.didTapButton), for: .touchUpInside)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    public func configure(viewModel: ActionFooterViewModel) {
        self.viewModel = viewModel
        titleLabel.text = viewModel.title
        primaryButton.setTitle(viewModel.actionTitle, for: .normal)

        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier
        primaryButton.accessibilityIdentifier = viewModel.a11yActionIdentifier
    }

    @objc
    private func didTapButton() {
        viewModel?.onTap?()
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
    public func applyTheme(theme: Common.Theme) {
        primaryButton.setTitleColor(theme.colors.actionPrimary, for: .normal)
        primaryButton.setTitleColor(theme.colors.actionPrimaryHover, for: .highlighted)
        titleLabel.textColor = theme.colors.textSecondary
    }
}
