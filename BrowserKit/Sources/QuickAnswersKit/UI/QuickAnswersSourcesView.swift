// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Displays a "Sources" header and a horizontally scrollable row of `SourceCardView` items.
/// Corresponds to the sources section in the QuickAnswers results state in Figma (iPhone 16 – 131).
final class QuickAnswersSourcesView: UIView, ThemeApplicable {
    private struct UX {
        static let headerFontSize: CGFloat = 12.0
        static let cardWidth: CGFloat = 164.5
        static let cardSpacing: CGFloat = 16.0
        static let cardsTopPadding: CGFloat = 8.0
        // thumbnailHeight(123) + titleTopPadding(8) + faviconSize(16)
        static let scrollViewHeight: CGFloat = 147.0
    }

    private let headerLabel: UILabel = .build {
        $0.font = .systemFont(ofSize: UX.headerFontSize, weight: .semibold)
        $0.text = "Sources" // TODO: Localize
    }
    private let scrollView: UIScrollView = .build {
        $0.showsHorizontalScrollIndicator = false
        $0.clipsToBounds = false
    }
    private let cardsStack: UIStackView = .build {
        $0.axis = .horizontal
        $0.spacing = UX.cardSpacing
        $0.alignment = .top
    }
    private var cardViews: [SourceCardView] = []
    private var currentTheme: (any Theme)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [SourceCardView.Item]) {
        cardsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cardViews = []

        for item in items {
            let card: SourceCardView = .build()
            card.configure(with: item)
            if let theme = currentTheme { card.applyTheme(theme: theme) }
            cardsStack.addArrangedSubview(card)
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(equalToConstant: UX.cardWidth),
            ])
            cardViews.append(card)
        }
    }

    private func setupSubviews() {
        scrollView.addSubview(cardsStack)
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubviews(headerLabel, scrollView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: UX.cardsTopPadding),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: UX.scrollViewHeight),

            cardsStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            cardsStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            cardsStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            cardsStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            cardsStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        currentTheme = theme
        headerLabel.textColor = theme.colors.textSecondary
        cardViews.forEach { $0.applyTheme(theme: theme) }
    }
}
