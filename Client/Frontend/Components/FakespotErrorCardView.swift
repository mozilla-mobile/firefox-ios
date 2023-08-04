// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class FakespotErrorCardView: UIView, ThemeApplicable {
    private enum UX {
        static let buttonFontSize: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13
        static let containerSpacing: CGFloat = 8
        static let containerMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let iconStackViewSpacing: CGFloat = 4
        static let horizontalStackViewSpacing: CGFloat = 12
        static let verticalStackViewSpacing: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let titleFontSize: CGFloat = 13
        static let descriptionFontSize: CGFloat = 13
        static let cornerRadius: CGFloat = 4
    }

    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.addArrangedSubview(self.infoContainerStackView)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(self.primaryButton)
        stackView.axis = .vertical
        stackView.spacing = UX.containerSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.containerMargins
    }

    private lazy var iconStackView: UIStackView = .build { stackView in
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(self.iconImageView)
        stackView.addArrangedSubview(UIView())
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = UX.iconStackViewSpacing
    }

    private lazy var infoContainerStackView: UIStackView = .build { stackView in
        stackView.addArrangedSubview(self.iconStackView)
        stackView.addArrangedSubview(self.labelContainerStackView)
        stackView.axis = .horizontal
        stackView.spacing = UX.horizontalStackViewSpacing
    }

    private lazy var labelContainerStackView: UIStackView = .build { stackView in
        stackView.addArrangedSubview(self.titleLabel)
        stackView.addArrangedSubview(self.descriptionLabel)
        stackView.axis = .vertical
        stackView.spacing = UX.verticalStackViewSpacing
    }

    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        // Set the icon image here
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.criticalFill)
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textColor = .white
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .footnote,
            size: UX.buttonFontSize)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.accessibilityIdentifier = AccessibilityIdentifiers.ErrorCard.title
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.textColor = .white
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.accessibilityIdentifier = AccessibilityIdentifiers.ErrorCard.description
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
        button.accessibilityIdentifier = AccessibilityIdentifiers.ErrorCard.primaryAction
    }

    /// Custom init method to pass title, description text, action text
    init(title: String, description: String, actionTitle: String) {
        super.init(frame: .zero)
        setupLayout()
        titleLabel.text = title
        descriptionLabel.text = description
        primaryButton.setTitle(actionTitle, for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    private func setupLayout() {
        layer.cornerRadius = UX.cornerRadius
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),

            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
    }

    @objc
    private func primaryAction() {
        // Add your button action here
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textInverted
        descriptionLabel.textColor  = theme.colors.textInverted
        iconImageView.tintColor = theme.colors.textInverted

        primaryButton.setTitleColor(theme.colors.textInverted, for: .normal)
        primaryButton.backgroundColor = theme.colors.iconAccentYellow

        layer.backgroundColor = theme.colors.textWarning.cgColor
    }
}
