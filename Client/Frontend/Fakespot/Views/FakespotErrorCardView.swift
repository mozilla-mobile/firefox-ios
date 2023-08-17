// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct FakespotErrorCardViewModel {
    let title: String
    let description: String
    let actionTitle: String
    let iconImageName: String = StandardImageIdentifiers.Large.criticalFill
    let a11yCardIdentifier: String = AccessibilityIdentifiers.Shopping.ErrorCard.card
    let a11yTitleIdentifier: String = AccessibilityIdentifiers.Shopping.ErrorCard.title
    let a11yDescriptionIdentifier: String = AccessibilityIdentifiers.Shopping.ErrorCard.description
    let a11yActionIdentifier: String = AccessibilityIdentifiers.Shopping.ErrorCard.primaryAction
}

final class FakespotErrorCardView: UIView, ThemeApplicable {
    private enum UX {
        static let buttonFontSize: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13
        static let contentHorizontalSpacing: CGFloat = 4
        static let contentVerticalSpacing: CGFloat = 8
        static let iconStackViewSpacing: CGFloat = 4
        static let horizontalStackViewSpacing: CGFloat = 12
        static let verticalStackViewSpacing: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let titleFontSize: CGFloat = 13
        static let descriptionFontSize: CGFloat = 13
    }

    private lazy var cardView: CardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var iconStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = UX.iconStackViewSpacing
    }

    private lazy var infoContainerStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.horizontalStackViewSpacing
    }

    private lazy var labelContainerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.verticalStackViewSpacing
    }

    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .footnote,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.textColor = .white
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .footnote,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
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
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    func configure(viewModel: FakespotErrorCardViewModel) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description
        primaryButton.setTitle(viewModel.actionTitle, for: .normal)
        iconImageView.image = UIImage(named: viewModel.iconImageName)

        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier
        descriptionLabel.accessibilityIdentifier = viewModel.a11yDescriptionIdentifier
        primaryButton.accessibilityIdentifier = viewModel.a11yActionIdentifier

        let cardModel = CardViewModel(view: contentView,
                                      a11yId: viewModel.a11yCardIdentifier,
                                      backgroundColor: { theme in
            return theme.colors.textWarning // Update in FXIOS-7154
        })
        cardView.configure(cardModel)
    }

    private func setupLayout() {
        addSubview(cardView)

        iconStackView.addArrangedSubview(UIView())
        iconStackView.addArrangedSubview(iconImageView)
        iconStackView.addArrangedSubview(UIView())

        infoContainerStackView.addArrangedSubview(iconStackView)
        infoContainerStackView.addArrangedSubview(labelContainerStackView)

        labelContainerStackView.addArrangedSubview(titleLabel)
        labelContainerStackView.addArrangedSubview(descriptionLabel)

        contentView.addSubview(infoContainerStackView)
        contentView.addSubview(primaryButton)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize),
            iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),

            infoContainerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                            constant: UX.contentHorizontalSpacing),
            infoContainerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            infoContainerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                             constant: -UX.contentHorizontalSpacing),
            infoContainerStackView.bottomAnchor.constraint(equalTo: primaryButton.topAnchor,
                                                           constant: -UX.contentVerticalSpacing),

            primaryButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                   constant: UX.contentHorizontalSpacing),
            primaryButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                    constant: -UX.contentHorizontalSpacing),
            primaryButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc
    private func primaryAction() {
        // Add your button action here
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textOnDark
        descriptionLabel.textColor  = theme.colors.textOnDark
        iconImageView.tintColor = theme.colors.textOnDark

        primaryButton.setTitleColor(theme.colors.textOnDark, for: .normal)
        primaryButton.backgroundColor = theme.colors.iconAccentYellow // Update in FXIOS-7154
        cardView.applyTheme(theme: theme)
    }
}
