// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

struct ReliabilityCardViewModel {
    let cardA11yId: String
    let title: String
    let titleA11yId: String
    let rating: ReliabilityRating
    let ratingLetterA11yId: String
    let ratingDescriptionA11yId: String
}

class ReliabilityCardView: UIView, ThemeApplicable {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 4
        static let letterVerticalPadding: CGFloat = 4
        static let letterHorizontalPadding: CGFloat = 4
        static let descriptionVerticalPadding: CGFloat = 6
        static let descriptionHorizontalPadding: CGFloat = 8
        static let titleFontSize: CGFloat = 17
        static let letterFontSize: CGFloat = 15
        static let descriptionFontSize: CGFloat = 12
        static let descriptionBackgroundAlpha: CGFloat = 0.15
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { view in
        view.adjustsFontForContentSizeCategory = true
        view.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                           size: UX.titleFontSize,
                                                           weight: .medium)
        view.numberOfLines = 0
    }

    private lazy var reliabilityScoreView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = 1
        view.clipsToBounds = true
    }

    private lazy var reliabilityLetterView: UIView = .build()
    private lazy var reliabilityDescriptionView: UIView = .build()

    private lazy var reliabilityLetterLabel: UILabel = .build { view in
        view.adjustsFontForContentSizeCategory = true
        view.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: UX.letterFontSize)
    }

    private lazy var reliabilityDescriptionLabel: UILabel = .build { view in
        view.adjustsFontForContentSizeCategory = true
        view.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1, size: UX.descriptionFontSize)
        view.numberOfLines = 0
    }

    private var viewModel: ReliabilityCardViewModel?

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: ReliabilityCardViewModel) {
        self.viewModel = viewModel

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        reliabilityLetterLabel.text = viewModel.rating.letter
        reliabilityLetterLabel.accessibilityIdentifier = viewModel.ratingLetterA11yId
        reliabilityDescriptionLabel.text = viewModel.rating.description
        reliabilityDescriptionLabel.accessibilityIdentifier = viewModel.ratingDescriptionA11yId

        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        reliabilityScoreView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        reliabilityScoreView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15).cgColor
        reliabilityLetterLabel.textColor = theme.colors.textOnDark
        reliabilityDescriptionLabel.textColor = theme.colors.textOnLight

        if let viewModel {
            reliabilityLetterView.layer.backgroundColor = viewModel.rating.color(theme: theme).cgColor
            reliabilityDescriptionView.layer.backgroundColor = viewModel.rating.color(theme: theme)
                .withAlphaComponent(UX.descriptionBackgroundAlpha).cgColor
        }
    }

    private func setupLayout() {
        addSubview(cardContainer)

        reliabilityLetterView.addSubview(reliabilityLetterLabel)
        reliabilityDescriptionView.addSubview(reliabilityDescriptionLabel)
        reliabilityScoreView.addSubview(reliabilityLetterView)
        reliabilityScoreView.addSubview(reliabilityDescriptionView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(reliabilityScoreView)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.horizontalPadding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.verticalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: reliabilityScoreView.topAnchor,
                                               constant: -UX.verticalPadding),

            reliabilityScoreView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                          constant: UX.horizontalPadding),
            reliabilityScoreView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor,
                                                           constant: -UX.horizontalPadding),
            reliabilityScoreView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                         constant: -UX.verticalPadding),

            reliabilityLetterView.leadingAnchor.constraint(equalTo: reliabilityScoreView.leadingAnchor),
            reliabilityLetterView.topAnchor.constraint(equalTo: reliabilityScoreView.topAnchor),
            reliabilityLetterView.trailingAnchor.constraint(equalTo: reliabilityDescriptionView.leadingAnchor),
            reliabilityLetterView.bottomAnchor.constraint(equalTo: reliabilityScoreView.bottomAnchor),

            reliabilityDescriptionView.topAnchor.constraint(equalTo: reliabilityScoreView.topAnchor),
            reliabilityDescriptionView.trailingAnchor.constraint(equalTo: reliabilityScoreView.trailingAnchor),
            reliabilityDescriptionView.bottomAnchor.constraint(equalTo: reliabilityScoreView.bottomAnchor),

            reliabilityLetterLabel.leadingAnchor.constraint(equalTo: reliabilityLetterView.leadingAnchor,
                                                            constant: UX.letterHorizontalPadding),
            reliabilityLetterLabel.topAnchor.constraint(equalTo: reliabilityLetterView.topAnchor,
                                                        constant: UX.letterVerticalPadding),
            reliabilityLetterLabel.trailingAnchor.constraint(equalTo: reliabilityLetterView.trailingAnchor,
                                                             constant: -UX.letterHorizontalPadding),
            reliabilityLetterLabel.bottomAnchor.constraint(equalTo: reliabilityLetterView.bottomAnchor,
                                                           constant: -UX.letterVerticalPadding),

            reliabilityDescriptionLabel.leadingAnchor.constraint(equalTo: reliabilityDescriptionView.leadingAnchor,
                                                                 constant: UX.descriptionHorizontalPadding),
            reliabilityDescriptionLabel.topAnchor.constraint(equalTo: reliabilityDescriptionView.topAnchor,
                                                             constant: UX.descriptionVerticalPadding),
            reliabilityDescriptionLabel.trailingAnchor.constraint(equalTo: reliabilityDescriptionView.trailingAnchor,
                                                                  constant: -UX.descriptionHorizontalPadding),
            reliabilityDescriptionLabel.bottomAnchor.constraint(equalTo: reliabilityDescriptionView.bottomAnchor,
                                                                constant: -UX.descriptionVerticalPadding),
        ])
    }
}
