// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

// MARK: View Model
struct FakespotAdViewModel {
    let title: String = .Shopping.AdCardTitleLabel
    let footerText: String = .localizedStringWithFormat(.Shopping.AdCardFooterLabel,
                                                        FakespotName.shortName.rawValue)
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.title
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.card
    let priceA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.price
    let productTitleA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.productTitle
    let descriptionA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.description
    let footerA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.footer

    private let tabManager: TabManager
    var dismissViewController: (() -> Void)?
    let productAdsData: ProductAdsResponse

    // MARK: Init
    init(tabManager: TabManager,
         productAdsData: ProductAdsResponse) {
        self.tabManager = tabManager
        self.productAdsData = productAdsData
    }

    // MARK: Tap Product
    func onTapProductLink() {
        tabManager.addTabsForURLs([productAdsData.url], zombie: false, shouldSelectTab: true)
        dismissViewController?()
    }
}

class FakespotAdView: UIView, Notifiable, ThemeApplicable, UITextViewDelegate {
    private enum UX {
        static let labelFontSize: CGFloat = 15
        static let descriptionFontSize: CGFloat = 13
        static let margins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let linkInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        static let hStackSpacing: CGFloat = 12
        static let vStackSpacing: CGFloat = 8
        static let starSize: CGFloat = 24
        static let starMaxSize: CGFloat = 42

        static let productImageMinWidth: CGFloat = 70
        static let productImageMinHeight: CGFloat = 60
        static let productImageMaxWidth: CGFloat = 206
        static let productImageMaxHeight: CGFloat = 173
    }

    // MARK: Views
    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var productImageView: FakespotImageLoadingView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var viewModel: FakespotAdViewModel?

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline,
                                                            size: UX.labelFontSize,
                                                            weight: .semibold)
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var footerLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .footnote,
                                                            size: UX.descriptionFontSize,
                                                            weight: .regular)
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.staticText)
    }

    private lazy var priceLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .footnote,
                                                                size: UX.descriptionFontSize)
        label.numberOfLines = 0
    }
    private lazy var productLinkButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapProductLink), for: .touchUpInside)
    }

    private lazy var gradeReliabilityScoreView = FakespotReliabilityScoreView(grade: .f)

    private lazy var starRatingView: FakespotStarRatingView = .build()

    private lazy var secondRowStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.hStackSpacing
    }

    private lazy var thirdRowStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.hStackSpacing
    }

    private lazy var contentStackView: UIStackView = .build { stackView in
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

    // MARK: Configuration
    func configure(_ viewModel: FakespotAdViewModel) {
        self.viewModel = viewModel
        let productAdsData = viewModel.productAdsData
        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        footerLabel.text = viewModel.footerText
        footerLabel.accessibilityIdentifier = viewModel.footerA11yId

        priceLabel.text = productAdsData.currency + productAdsData.price
        priceLabel.accessibilityIdentifier = viewModel.priceA11yId

        starRatingView.rating = productAdsData.adjustedRating
        starRatingView.isAccessibilityElement = true
        let rating = String(format: "%.1f", productAdsData.adjustedRating)
        starRatingView.accessibilityLabel = String(format: .Shopping.AdjustedRatingStarsAccessibilityLabel, rating)

        let productLinkButtonViewModel = LinkButtonViewModel(
            title: productAdsData.name,
            a11yIdentifier: viewModel.productTitleA11yId,
            fontSize: UX.labelFontSize,
            contentInsets: UX.linkInsets
        )
        productLinkButton.configure(viewModel: productLinkButtonViewModel)
        gradeReliabilityScoreView.configure(grade: productAdsData.grade)
        Task {
            try? await productImageView.loadImage(from: productAdsData.imageUrl)
        }

        let cardModel = ShadowCardViewModel(view: contentStackView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var starRatingHeightConstraint: NSLayoutConstraint?
    private var productImageHeightConstraint: NSLayoutConstraint?
    private var productImageWidthConstraint: NSLayoutConstraint?

    // MARK: Layout Setup
    private func setupLayout() {
        addSubview(cardContainer)
        insertSubview(footerLabel, belowSubview: cardContainer)
        // normal setup
        let starsHeight = min(UIFontMetrics.default.scaledValue(for: UX.starSize), UX.starMaxSize)
        let imageWidth = min(UIFontMetrics.default.scaledValue(for: UX.productImageMinWidth), UX.productImageMaxWidth)
        let imageHeight = min(UIFontMetrics.default.scaledValue(for: UX.productImageMinHeight), UX.productImageMaxHeight)
        starRatingHeightConstraint = starRatingView.heightAnchor.constraint(equalToConstant: starsHeight)
        starRatingHeightConstraint?.isActive = true

        productImageHeightConstraint = productImageView.heightAnchor.constraint(equalToConstant: imageHeight)
        productImageHeightConstraint?.isActive = true

        productImageWidthConstraint = productImageView.widthAnchor.constraint(equalToConstant: imageWidth)
        productImageWidthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: footerLabel.topAnchor, constant: -UX.vStackSpacing),

            footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        adjustLayout()
    }

    private func adjustLayout() {
        secondRowStackView.removeAllArrangedViews()
        thirdRowStackView.removeAllArrangedViews()
        contentStackView.removeAllArrangedViews()

        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        starRatingHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.starSize), UX.starMaxSize)
        productImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.productImageMinHeight), UX.productImageMaxHeight)
        productImageWidthConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.productImageMinWidth), UX.productImageMaxWidth)

        if contentSizeCategory.isAccessibilityCategory {
            secondRowStackView.axis = .vertical
            spacer.isHidden = false
            setupLayoutForAccessibilityView()
        } else {
            secondRowStackView.axis = .horizontal
            spacer.isHidden = true
            setupLayoutForDefaultView()
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func setupLayoutForDefaultView() {
        // first line
        contentStackView.addArrangedSubview(titleLabel)

        // second line
        productLinkButton.setContentHuggingPriority(.required, for: .vertical)
        productLinkButton.setContentCompressionResistancePriority(.required, for: .vertical)
        productLinkButton.setContentHuggingPriority(.required, for: .horizontal)
        productLinkButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        secondRowStackView.addArrangedSubview(productImageView)
        secondRowStackView.addArrangedSubview(productLinkButton)
        secondRowStackView.addArrangedSubview(gradeReliabilityScoreView)
        secondRowStackView.distribution = .fill
        secondRowStackView.alignment = .top

        // third line
        thirdRowStackView.addArrangedSubview(priceLabel)
        thirdRowStackView.addArrangedSubview(spacer)
        thirdRowStackView.addArrangedSubview(starRatingView)
        thirdRowStackView.distribution = .fill
        thirdRowStackView.alignment = .leading

        priceLabel.centerYAnchor.constraint(equalTo: starRatingView.centerYAnchor).isActive = true

        contentStackView.addArrangedSubview(secondRowStackView)
        contentStackView.addArrangedSubview(thirdRowStackView)
        contentStackView.distribution = .fill
    }

    private func setupLayoutForAccessibilityView() {
        contentStackView.distribution = .fill
        // first line
        contentStackView.addArrangedSubview(titleLabel)

        // second line
        let spacerTrailing = UIView()
        let secondLineStackView = UIStackView(arrangedSubviews: [productImageView, spacerTrailing])
        secondLineStackView.axis = .horizontal
        secondLineStackView.distribution = .fill
        contentStackView.addArrangedSubview(secondLineStackView)

        // third line
        let spacerBottom = UIView()
        let gradeStackView = UIStackView(arrangedSubviews: [starRatingView, gradeReliabilityScoreView, spacerBottom])
        gradeStackView.axis = .horizontal
        gradeStackView.spacing = UX.hStackSpacing
        gradeStackView.distribution = .fill
        gradeReliabilityScoreView.centerYAnchor.constraint(equalTo: starRatingView.centerYAnchor).isActive = true
        contentStackView.addArrangedSubview(gradeStackView)

        // fourth line
        contentStackView.addArrangedSubview(productLinkButton)

        // fifth line
        contentStackView.addArrangedSubview(priceLabel)
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    // MARK: Button Actions
    @objc
    private func didTapProductLink() {
        viewModel?.onTapProductLink()
    }

    // MARK: Theming
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        titleLabel.textColor = theme.colors.textPrimary
        priceLabel.textColor = theme.colors.textPrimary
        footerLabel.textColor = theme.colors.textSecondary
        productLinkButton.setTitleColor(theme.colors.textAccent, for: .normal)
        gradeReliabilityScoreView.applyTheme(theme: theme)
        productImageView.theme = theme
    }
}
