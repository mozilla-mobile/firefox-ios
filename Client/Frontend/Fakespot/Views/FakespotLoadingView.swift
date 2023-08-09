// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class FakespotLoadingView: UIView, ThemeApplicable {
    private enum UX {
        static let card1And3Height: CGFloat = 192
        static let card2Height: CGFloat = 40
        static let card4And5Height: CGFloat = 80
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }

    private lazy var cardView1: UIView = .build()
    private lazy var cardView2: UIView = .build()
    private lazy var cardView3: UIView = .build()
    private lazy var cardView4: UIView = .build()
    private lazy var cardView5: UIView = .build()

    private lazy var cardViews = [self.cardView1, self.cardView2, self.cardView3, self.cardView4, self.cardView5]

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        cardViews.map { $0.backgroundColor = theme.colors.layer3 }
    }

    private func setupLayout() {
        cardViews.map { cardView in
            addSubview(cardView)
            cardView.layer.cornerRadius = UX.cornerRadius
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            cardView1.topAnchor.constraint(equalTo: topAnchor),
            cardView1.bottomAnchor.constraint(equalTo: cardView2.topAnchor, constant: -UX.cardPadding),
            cardView1.heightAnchor.constraint(equalToConstant: UX.card1And3Height),

            cardView2.bottomAnchor.constraint(equalTo: cardView3.topAnchor, constant: -UX.cardPadding),
            cardView2.heightAnchor.constraint(equalToConstant: UX.card2Height),

            cardView3.bottomAnchor.constraint(equalTo: cardView4.topAnchor, constant: -UX.cardPadding),
            cardView3.heightAnchor.constraint(equalToConstant: UX.card1And3Height),

            cardView4.bottomAnchor.constraint(equalTo: cardView5.topAnchor, constant: -UX.cardPadding),
            cardView4.heightAnchor.constraint(equalToConstant: UX.card4And5Height),

            cardView5.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.cardPadding),
            cardView5.heightAnchor.constraint(equalToConstant: UX.card4And5Height),
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
        UIView.animate(withDuration: 1.0, delay: delay, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            card.alpha = 0.25
        }
    }
}
