// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct AdjustRatingViewModel {
    let title: String
    let description: String
    let titleA11yId: String
    let cardA11yId: String
    let descriptionA11yId: String
}

class AdjustRatingView: UIView, Notifiable, ThemeApplicable {
    private enum UX {
        static let titleFontSize: CGFloat = 17
        static let descriptionFontSize: CGFloat = 13
    }

    var rating: Double = 0.0 {
        didSet {
            starRatingView.rating = rating
        }
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.titleFontSize,
                                                            weight: .medium)
        label.numberOfLines = 0
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.descriptionFontSize,
                                                            weight: .regular)
        label.numberOfLines = 0
    }

    private lazy var starRatingView: StarRatingView = .build()

    private lazy var hStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = 4
    }

    private lazy var vStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    func configure(_ viewModel: AdjustRatingViewModel) {
        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        descriptionLabel.text = viewModel.description
        descriptionLabel.accessibilityIdentifier = viewModel.descriptionA11yId

        let cardModel = ShadowCardViewModel(view: vStackView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        addSubview(cardContainer)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        hStackView.addArrangedSubview(titleLabel)
        hStackView.addArrangedSubview(starRatingView)

        vStackView.addArrangedSubview(hStackView)
        vStackView.addArrangedSubview(descriptionLabel)

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            hStackView.axis = .vertical
        } else {
            hStackView.axis = .horizontal
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
    }
}
