// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

/// The view model used to configure a `FakespotActionFooterView`
public struct FakespotActionFooterViewModel {
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

public final class FakespotActionFooterView: UIView, ThemeApplicable {
    private struct UX {
        static let buttonInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 17, trailing: 0)
    }

    private var viewModel: FakespotActionFooterViewModel?

    private lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var linkButton: LinkButton = .build { button in
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

    public func configure(viewModel: FakespotActionFooterViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier

        let linkButtonViewModel = LinkButtonViewModel(
            title: viewModel.actionTitle,
            a11yIdentifier: viewModel.a11yActionIdentifier,
            font: FXFontStyles.Regular.footnote.scaledFont(),
            contentInsets: UX.buttonInsets,
            contentHorizontalAlignment: .leading
        )
        linkButton.configure(viewModel: linkButtonViewModel)
    }

    @objc
    private func didTapButton() {
        viewModel?.onTap?()
    }

    private func setupLayout() {
        addSubviews(titleLabel, linkButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: linkButton.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            linkButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            linkButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            linkButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        let colors = theme.colors
        linkButton.applyTheme(theme: theme)
        titleLabel.textColor = colors.textSecondary
    }
}
