// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

class FakespotLoadingView: UIView, ThemeApplicable {
    private enum UX {
        static let bigCardHeight: CGFloat = 192
        static let mediumCardHeight: CGFloat = 80
        static let smallCardHeight: CGFloat = 40
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let minimumAlpha: CGFloat = 0.25
    }

    private lazy var cardView1: CardView = .build()
    private lazy var cardView2: CardView = .build()
    private lazy var cardView3: CardView = .build()
    private lazy var cardView4: CardView = .build()
    private lazy var cardView5: CardView = .build()

    private lazy var cardViews = [self.cardView1, self.cardView2, self.cardView3, self.cardView4, self.cardView5]

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        let viewModel = CardViewModel(view: UIView(), a11yId: "CardView", backgroundColor: { theme in
            return theme.colors.layer3
        })
        cardViews.forEach { $0.configure(viewModel) }

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        cardViews.forEach { $0.applyTheme(theme: theme) }
    }

    private func setupLayout() {
        cardViews.forEach { cardView in
            addSubview(cardView)
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            cardView1.topAnchor.constraint(equalTo: topAnchor),
            cardView1.bottomAnchor.constraint(equalTo: cardView2.topAnchor, constant: -UX.cardPadding),
            cardView1.heightAnchor.constraint(equalToConstant: UX.bigCardHeight),

            cardView2.bottomAnchor.constraint(equalTo: cardView3.topAnchor, constant: -UX.cardPadding),
            cardView2.heightAnchor.constraint(equalToConstant: UX.smallCardHeight),

            cardView3.bottomAnchor.constraint(equalTo: cardView4.topAnchor, constant: -UX.cardPadding),
            cardView3.heightAnchor.constraint(equalToConstant: UX.bigCardHeight),

            cardView4.bottomAnchor.constraint(equalTo: cardView5.topAnchor, constant: -UX.cardPadding),
            cardView4.heightAnchor.constraint(equalToConstant: UX.mediumCardHeight),

            cardView5.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.cardPadding),
            cardView5.heightAnchor.constraint(equalToConstant: UX.mediumCardHeight),
        ])
    }

    func animate() {
        animateCard(cardView1, delay: 0.5)
        animateCard(cardView2, delay: 1.5)
        animateCard(cardView3, delay: 0)
        animateCard(cardView4, delay: 1)
        animateCard(cardView5, delay: 0)
    }

    private func animateCard(_ card: UIView, delay: TimeInterval) {
        guard !UIAccessibility.isReduceMotionEnabled else {
            card.alpha = UX.minimumAlpha
            return
        }

        UIView.animate(withDuration: 1.0, delay: delay, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            card.alpha = UX.minimumAlpha
        }
    }
}
