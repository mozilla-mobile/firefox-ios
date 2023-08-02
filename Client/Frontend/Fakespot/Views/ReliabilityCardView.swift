// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

class ReliabilityCardView: UIView, ThemeApplicable {
    private struct UX {
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 8
        static let titleHorizontalPadding: CGFloat = 16
        static let titleTopPadding: CGFloat = 16
    }

    private lazy var cardContainer: CardContainer = .build { view in
    }

    private lazy var contentView: UIView = .build { view in
    }

    private lazy var titleLabel: UILabel = .build { view in
        view.adjustsFontForContentSizeCategory = true
        view.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: 17)
        view.text = .Shopping.ReliabilityCardTitleLabel
    }

    private lazy var reliabilityScoreView: UIView = .build { view in
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()

        let cardModel = CardContainerModel(view: contentView, a11yId: "")
        cardContainer.configure(cardModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
    }

    private func setupLayout() {
        addSubview(cardContainer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(reliabilityScoreView)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.titleHorizontalPadding),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.titleTopPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.titleHorizontalPadding),
            titleLabel.bottomAnchor.constraint(equalTo: reliabilityScoreView.topAnchor,
                                               constant: -UX.verticalPadding),

            reliabilityScoreView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                          constant: UX.horizontalPadding),
            reliabilityScoreView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.horizontalPadding),
            reliabilityScoreView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                         constant: -UX.verticalPadding),
        ])
    }
}
