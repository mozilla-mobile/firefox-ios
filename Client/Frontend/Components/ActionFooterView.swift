// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class ActionFooterView: UIView, ThemeApplicable {
    private struct UX {
        static let labelSize: CGFloat = 13
        static let buttonSize: CGFloat = 13
        static let padding: CGFloat = 8
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
        button.titleLabel?.numberOfLines = 1
        button.buttonEdgeSpacing = 0
        button.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.addArrangedSubview(self.titleLabel)
        stackView.addArrangedSubview(self.primaryButton)
        stackView.spacing = 0
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.containerMargins
    }

    init(title: String, actionTitle: String) {
        super.init(frame: .zero)
        setupLayout()
        titleLabel.text = title
        primaryButton.setTitle(actionTitle, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    private func setupLayout() {
        addSubview(stackView)

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
