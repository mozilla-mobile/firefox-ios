// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct FakespotAdjustRatingViewModel {
    let title: String = .Shopping.AdjustedRatingTitle
    let description: String = .Shopping.AdjustedRatingDescription
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.AdjustRating.title
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.AdjustRating.card
    let descriptionA11yId: String = AccessibilityIdentifiers.Shopping.AdjustRating.description
    let rating: Double
}

class FakespotAdjustRatingView: UIView, Notifiable, ThemeApplicable {
    private enum UX {
        static let margins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let hStackSpacing: CGFloat = 4
        static let vStackSpacing: CGFloat = 8
        static let starSize: CGFloat = 24
        static let starMaxSize: CGFloat = 42
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private lazy var starRatingView: FakespotStarRatingView = .build()

    private lazy var hStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.hStackSpacing
    }

    private lazy var vStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.vStackSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.margins
    }

    private lazy var spacer: UIView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    func configure(_ viewModel: FakespotAdjustRatingViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        descriptionLabel.text = viewModel.description
        descriptionLabel.accessibilityIdentifier = viewModel.descriptionA11yId

        starRatingView.rating = viewModel.rating
        starRatingView.isAccessibilityElement = true
        let rating = String(format: "%.1f", viewModel.rating)
        starRatingView.accessibilityLabel = String(format: .Shopping.AdjustedRatingStarsAccessibilityLabel, rating)

        let cardModel = ShadowCardViewModel(view: vStackView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var starRatingHeightConstraint: NSLayoutConstraint?

    private func setupLayout() {
        addSubview(cardContainer)

        let size = min(UIFontMetrics.default.scaledValue(for: UX.starSize), UX.starMaxSize)
        starRatingHeightConstraint = starRatingView.heightAnchor.constraint(equalToConstant: size)
        starRatingHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hStackView.addArrangedSubview(titleLabel)
        let stackView = UIStackView(arrangedSubviews: [starRatingView, spacer])
        stackView.axis = .horizontal
        hStackView.addArrangedSubview(stackView)

        vStackView.addArrangedSubview(hStackView)
        vStackView.addArrangedSubview(descriptionLabel)

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        starRatingHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.starSize), UX.starMaxSize)

        if contentSizeCategory.isAccessibilityCategory {
            hStackView.axis = .vertical
            spacer.isHidden = false
        } else {
            hStackView.axis = .horizontal
            spacer.isHidden = true
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        starRatingView.applyTheme(theme: theme)
    }
}
