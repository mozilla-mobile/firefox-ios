// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

struct HighlightsCardViewModel {
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.card
    let footerTitle: String
    let footerActionTitle: String
    let footerA11yTitleIdentifier: String = AccessibilityIdentifiers.Shopping.HighlightsCard.footerTitle
    let footerA11yActionIdentifier: String = AccessibilityIdentifiers.Shopping.HighlightsCard.footerAction

    var footerModel: ActionFooterViewModel {
        return ActionFooterViewModel(title: footerTitle,
                                     actionTitle: footerActionTitle,
                                     a11yTitleIdentifier: footerA11yTitleIdentifier,
                                     a11yActionIdentifier: footerA11yActionIdentifier)
    }
}

class HighlightsCardView: UIView, ThemeApplicable {
    private struct UX {
        static let cardBottomSpace: CGFloat = 16
        static let footerHorizontalSpace: CGFloat = 16
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()
    private lazy var footerView: ActionFooterView = .build()

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: HighlightsCardViewModel) {
        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
        footerView.configure(viewModel: viewModel.footerModel)
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        footerView.applyTheme(theme: theme)
    }

    private func setupLayout() {
        addSubview(cardContainer)
        addSubview(footerView)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -UX.cardBottomSpace),

            footerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.footerHorizontalSpace),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.footerHorizontalSpace),
            footerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
