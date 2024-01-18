// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary
import MozillaAppServices

// MARK: View Model
struct FakespotAdViewModel: FeatureFlaggable {
    let title: String = .Shopping.AdCardTitleLabel
    let footerText: String = .localizedStringWithFormat(.Shopping.AdCardFooterLabel,
                                                        FakespotName.shortName.rawValue)
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.title
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.card
    let priceA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.price
    let starRatingA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.starRating
    let productTitleA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.productTitle
    let descriptionA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.description
    let footerA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.footer
    let defaultImageA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.defaultImage
    let productImageA11yId: String = AccessibilityIdentifiers.Shopping.AdCard.productImage

    var onTapProductLink: (() -> Void)?
    let productAdsData: ProductAdsResponse
    let urlCache: URLCache

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = productAdsData.currency

        let fallBackPrice = productAdsData.currency + productAdsData.price

        guard let price = Double(productAdsData.price),
              let formattedPrice = formatter.string(from: NSNumber(value: price)) else {
           return fallBackPrice
        }

         return formattedPrice
    }

    // MARK: Init
    init(productAdsData: ProductAdsResponse,
         urlCache: URLCache = URLCache.shared) {
        self.productAdsData = productAdsData
        self.urlCache = urlCache
    }

    // MARK: Image Loading
    @MainActor
    func loadImage(from url: URL) async throws -> UIImage? {
        if let cachedData = urlCache.cachedResponse(for: URLRequest(url: url))?.data,
           let image = UIImage(data: cachedData) {
            return image
        }

        do {
            let environment = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? FakespotEnvironment.staging : .prod
            guard
                let config = environment.config,
                let relay = environment.relay
            else {
                throw FakespotClient.FakeSpotClientError.invalidURL
            }

            // Create an instance of OhttpManager with the staging configuration
            let manager = OhttpManager(configUrl: config, relayUrl: relay)

            let (data, response) = try await manager.data(for: URLRequest(url: url))
            let cacheData = CachedURLResponse(response: response, data: data)
            self.urlCache.storeCachedResponse(cacheData, for: URLRequest(url: url))
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

class FakespotAdView: UIView, Notifiable, ThemeApplicable, UITextViewDelegate {
    private enum UX {
        static let titleFontSize: CGFloat = 15
        static let linkFontSize: CGFloat = 13
        static let priceFontSize: CGFloat = 13
        static let footerFontSize: CGFloat = 13
        static let margins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        static let linkInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        static let titleBottomSpacing: CGFloat = 14
        static let horizontalElementSpacing: CGFloat = 12
        static let verticalElementSpacing: CGFloat = 8
        static let starSize: CGFloat = 20
        static let starMaxSize: CGFloat = 42

        static let productImageCornerRadius: CGFloat = 2
        static let productImageMinSize = CGSize(width: 70, height: 60)
        static let productImageMaxSize = CGSize(width: 206, height: 173)
        static let defaultImageSize = CGSize(width: 24, height: 24)
        static let defaultImageMaxSize = CGSize(width: 70, height: 70)
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var viewModel: FakespotAdViewModel?
    public var ad: ProductAdsResponse? { viewModel?.productAdsData }
    private var previousPreferredContentSizeCategory: UIContentSizeCategory?

    // MARK: Views
    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var imageContainerView: UIView = .build { view in
        view.layer.cornerRadius = UX.productImageCornerRadius
    }

    private var defaultImageView: UIImageView = .build { view in
        view.image = UIImage(named: StandardImageIdentifiers.Large.image)?.withRenderingMode(.alwaysTemplate)
    }

    private lazy var productImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = UX.productImageCornerRadius
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline,
                                                            size: UX.titleFontSize,
                                                            weight: .semibold)
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
    }

    private lazy var footerLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .footnote,
                                                            size: UX.footerFontSize,
                                                            weight: .regular)
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.staticText)
    }

    private lazy var priceLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .footnote,
                                                            size: UX.priceFontSize,
                                                            weight: .semibold)
        label.numberOfLines = 0
    }

    private lazy var productLinkButton: FakespotAdLinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapProductLink), for: .touchUpInside)
    }

    private lazy var gradeReliabilityScoreView = FakespotReliabilityScoreView(grade: .f)
    private lazy var starRatingView: FakespotStarRatingView = .build()
    private lazy var contentView: UIView = .build()
    private lazy var contentContainerView: UIView = .build()

    private lazy var firstRowView: UIView = .build()
    private lazy var secondRowView: UIView = .build()
    private lazy var a11ySizeRatingContainerView: UIView = .build()

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

        priceLabel.text = viewModel.formattedPrice
        priceLabel.accessibilityIdentifier = viewModel.priceA11yId

        starRatingView.rating = productAdsData.adjustedRating
        starRatingView.isAccessibilityElement = true
        let rating = String(format: "%.1f", productAdsData.adjustedRating)
        starRatingView.accessibilityLabel = String(format: .Shopping.AdjustedRatingStarsAccessibilityLabel, rating)
        starRatingView.accessibilityIdentifier = viewModel.starRatingA11yId

        let productLinkButtonViewModel = LinkButtonViewModel(
            title: productAdsData.name,
            a11yIdentifier: viewModel.productTitleA11yId,
            fontSize: UX.linkFontSize,
            contentInsets: UX.linkInsets
        )
        productLinkButton.configure(viewModel: productLinkButtonViewModel)
        gradeReliabilityScoreView.configure(grade: productAdsData.grade)
        defaultImageView.accessibilityIdentifier = viewModel.defaultImageA11yId
        productImageView.accessibilityIdentifier = viewModel.productImageA11yId
        productImageView.isHidden = true

        Task {
            let image = try? await viewModel.loadImage(from: productAdsData.imageUrl)
            productImageView.image = image
            displayProductImage()
        }

        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var starRatingHeightConstraint: NSLayoutConstraint?
    private var productImageHeightConstraint: NSLayoutConstraint?
    private var productImageWidthConstraint: NSLayoutConstraint?
    private var defaultProductImageWidthConstraint: NSLayoutConstraint?

    // MARK: Layout Setup
    private func setupLayout() {
        addSubview(cardContainer)
        addSubview(footerLabel)

        contentView.addSubview(contentContainerView)
        contentContainerView.addSubview(titleLabel)

        imageContainerView.addSubview(defaultImageView)
        imageContainerView.addSubview(productImageView)

        // normal setup
        starRatingHeightConstraint = starRatingView.heightAnchor.constraint(equalToConstant: UX.starSize)
        starRatingHeightConstraint?.isActive = true

        let imageSize = UX.productImageMinSize
        productImageHeightConstraint = imageContainerView.heightAnchor.constraint(equalToConstant: imageSize.height)
        productImageWidthConstraint = imageContainerView.widthAnchor.constraint(equalToConstant: imageSize.width)
        productImageHeightConstraint?.isActive = true
        productImageWidthConstraint?.isActive = true

        defaultProductImageWidthConstraint = defaultImageView.widthAnchor.constraint(
            equalToConstant: UX.defaultImageSize.width
        )
        defaultProductImageWidthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: footerLabel.topAnchor,
                                                  constant: -UX.verticalElementSpacing),

            footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                          constant: UX.margins.left),
            contentContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.margins.top),
            contentContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.margins.right),
            contentContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                         constant: -UX.margins.bottom),

            titleLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

            defaultImageView.heightAnchor.constraint(equalTo: defaultImageView.widthAnchor),
            defaultImageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            defaultImageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),

            productImageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            productImageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            productImageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            productImageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
        ])

        adjustLayout()
    }

    private func adjustLayout() {
        starRatingHeightConstraint?.constant = minSize(minValue: UX.starSize, maxValue: UX.starMaxSize)
        productImageHeightConstraint?.constant = minSize(minValue: UX.productImageMinSize.height,
                                                         maxValue: UX.productImageMaxSize.height)
        productImageWidthConstraint?.constant = minSize(minValue: UX.productImageMinSize.width,
                                                        maxValue: UX.productImageMaxSize.width)
        defaultProductImageWidthConstraint?.constant = minSize(minValue: UX.defaultImageSize.width,
                                                               maxValue: UX.defaultImageMaxSize.width)

        // swiftlint:disable line_length
        let shouldUpdateLayout = previousPreferredContentSizeCategory?.isAccessibilityCategory != UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        // swiftlint:enable line_length

        guard previousPreferredContentSizeCategory == nil || shouldUpdateLayout else { return }

        prepareForLayoutUpdate()

        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            setupLayoutForAccessibilityView()
        } else {
            setupLayoutForDefaultView()
        }

        previousPreferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }

    private func prepareForLayoutUpdate() {
        firstRowView.removeFromSuperview()
        secondRowView.removeFromSuperview()
        imageContainerView.removeFromSuperview()
        a11ySizeRatingContainerView.removeFromSuperview()
        productLinkButton.removeFromSuperview()
        priceLabel.removeFromSuperview()
    }

    private func setupLayoutForDefaultView() {
        firstRowView.addSubview(imageContainerView)
        firstRowView.addSubview(productLinkButton)
        firstRowView.addSubview(gradeReliabilityScoreView)

        secondRowView.addSubview(priceLabel)
        secondRowView.addSubview(starRatingView)

        contentContainerView.addSubview(firstRowView)
        contentContainerView.addSubview(secondRowView)

        NSLayoutConstraint.activate([
            firstRowView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.titleBottomSpacing),
            firstRowView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            firstRowView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

            secondRowView.topAnchor.constraint(equalTo: firstRowView.bottomAnchor,
                                               constant: UX.verticalElementSpacing),
            secondRowView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            secondRowView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            secondRowView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

            imageContainerView.topAnchor.constraint(equalTo: firstRowView.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: firstRowView.leadingAnchor),
            imageContainerView.bottomAnchor.constraint(lessThanOrEqualTo: firstRowView.bottomAnchor),

            productLinkButton.topAnchor.constraint(equalTo: firstRowView.topAnchor),
            productLinkButton.leadingAnchor.constraint(equalTo: imageContainerView.trailingAnchor,
                                                       constant: UX.horizontalElementSpacing),
            productLinkButton.bottomAnchor.constraint(equalTo: firstRowView.bottomAnchor),

            gradeReliabilityScoreView.topAnchor.constraint(equalTo: firstRowView.topAnchor),
            gradeReliabilityScoreView.leadingAnchor.constraint(equalTo: productLinkButton.trailingAnchor,
                                                               constant: UX.horizontalElementSpacing),
            gradeReliabilityScoreView.bottomAnchor.constraint(lessThanOrEqualTo: firstRowView.bottomAnchor),
            gradeReliabilityScoreView.trailingAnchor.constraint(equalTo: firstRowView.trailingAnchor),

            priceLabel.topAnchor.constraint(equalTo: secondRowView.topAnchor),
            priceLabel.leadingAnchor.constraint(equalTo: secondRowView.leadingAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: secondRowView.bottomAnchor),

            starRatingView.topAnchor.constraint(equalTo: secondRowView.topAnchor),
            starRatingView.leadingAnchor.constraint(greaterThanOrEqualTo: priceLabel.trailingAnchor,
                                                    constant: UX.horizontalElementSpacing),
            starRatingView.bottomAnchor.constraint(equalTo: secondRowView.bottomAnchor),
            starRatingView.trailingAnchor.constraint(equalTo: secondRowView.trailingAnchor),
        ])
    }

    private func setupLayoutForAccessibilityView() {
        a11ySizeRatingContainerView.addSubview(starRatingView)
        a11ySizeRatingContainerView.addSubview(gradeReliabilityScoreView)

        contentContainerView.addSubview(imageContainerView)
        contentContainerView.addSubview(a11ySizeRatingContainerView)
        contentContainerView.addSubview(productLinkButton)
        contentContainerView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                    constant: UX.titleBottomSpacing),
            imageContainerView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentContainerView.trailingAnchor),

            a11ySizeRatingContainerView.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor,
                                                             constant: UX.verticalElementSpacing),
            a11ySizeRatingContainerView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            a11ySizeRatingContainerView.trailingAnchor.constraint(lessThanOrEqualTo: contentContainerView.trailingAnchor),

            starRatingView.topAnchor.constraint(greaterThanOrEqualTo: a11ySizeRatingContainerView.topAnchor),
            starRatingView.leadingAnchor.constraint(equalTo: a11ySizeRatingContainerView.leadingAnchor),
            starRatingView.bottomAnchor.constraint(lessThanOrEqualTo: a11ySizeRatingContainerView.bottomAnchor),
            starRatingView.centerYAnchor.constraint(equalTo: a11ySizeRatingContainerView.centerYAnchor),

            gradeReliabilityScoreView.topAnchor.constraint(equalTo: a11ySizeRatingContainerView.topAnchor),
            gradeReliabilityScoreView.leadingAnchor.constraint(equalTo: starRatingView.trailingAnchor,
                                                               constant: UX.horizontalElementSpacing),
            gradeReliabilityScoreView.bottomAnchor.constraint(equalTo: a11ySizeRatingContainerView.bottomAnchor),
            gradeReliabilityScoreView.trailingAnchor.constraint(equalTo: a11ySizeRatingContainerView.trailingAnchor),

            productLinkButton.topAnchor.constraint(equalTo: a11ySizeRatingContainerView.bottomAnchor,
                                                   constant: UX.verticalElementSpacing),
            productLinkButton.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            productLinkButton.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),

            priceLabel.topAnchor.constraint(equalTo: productLinkButton.bottomAnchor,
                                            constant: UX.verticalElementSpacing),
            priceLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            priceLabel.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
        ])
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
        viewModel?.onTapProductLink?()
    }

    // MARK: Theming
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        productLinkButton.applyTheme(theme: theme)
        gradeReliabilityScoreView.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textPrimary
        defaultImageView.tintColor = theme.colors.iconSecondary
        imageContainerView.backgroundColor = theme.colors.layer3
        priceLabel.textColor = theme.colors.textPrimary
        footerLabel.textColor = theme.colors.textSecondary
    }

    private func displayProductImage() {
        guard productImageView.image != nil else { return }

        defaultImageView.isHidden = true
        productImageView.isHidden = false
    }

    private func minSize(minValue: CGFloat, maxValue: CGFloat) -> CGFloat {
        return min(UIFontMetrics.default.scaledValue(for: minValue), maxValue)
    }
}
