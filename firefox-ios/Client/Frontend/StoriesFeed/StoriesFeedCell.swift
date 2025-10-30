// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SiteImageView

class StoriesFeedCell: UICollectionViewCell,
                       ReusableCell,
                       Notifiable,
                       ThemeApplicable {
    struct UX {
        static let cellCornerRadius: CGFloat = 16
        static let thumbnailSize = CGSize(width: 345, height: 180)
        static let thumbnailHoritonztalInsets: CGFloat = 8
        static let thumbnailCornerRadius: CGFloat = 8
        static let attributionStackViewBottomInset: CGFloat = 16
        static let attributionStackViewSpacing: CGFloat = 8
        static let attributionFaviconSize = CGSize(width: 16, height: 16)
        static let faviconCornerRadius: CGFloat = 0
        static let verticalSpacing: CGFloat = 8
        static let horizontalInsets: CGFloat = 16
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowBlurRadius: CGFloat = 2
        static let shadowOpacity: Float = 1
    }

    // MARK: - Notifiable Properties
    var notificationCenter: NotificationProtocol

    // MARK: - UI Elements
    private var thumbnailImageView: HeroImageView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.callout.scaledFont()
    }

    private lazy var attributionStackView: UIStackView = .build { stackView in
        stackView.spacing = UX.attributionStackViewSpacing
        stackView.alignment = .center
    }

    private lazy var attributionFaviconImageView: FaviconImageView = .build()

    private lazy var attributionTitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    // MARK: Initializers
    override init(frame: CGRect) {
        self.notificationCenter = NotificationCenter.default
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.StoriesFeed.storiesFeedCell
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.cellCornerRadius).cgPath
    }

    // MARK: Public functions
    func configure(story: MerinoStoryConfiguration, theme: Theme, position: Int? = nil, totalCount: Int? = nil) {
        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: story.imageURL?.absoluteString ?? "",
                                                            generalCornerRadius: UX.thumbnailCornerRadius,
                                                            faviconCornerRadius: UX.thumbnailCornerRadius,
                                                            heroImageSize: UX.thumbnailSize)
        thumbnailImageView.setHeroImage(heroImageViewModel)

        titleLabel.text = story.title
        titleLabel.numberOfLines = getNumberOfLinesForTitle()
        accessibilityLabel = story.accessibilityLabel
        if let position = position, let totalCount = totalCount {
            accessibilityHint = String(
                format: .FirefoxHomepage.Pocket.PositionAccessibilityHint,
                String(position),
                String(totalCount)
            )
        }

        // Use provided favicon if given, otherwise fetch favicon from story url
        // Site resource only necessary when fetching a resource directly instead of scraping
        if let url = story.iconURL ?? story.url {
            let siteResource = story.iconURL.map { SiteResource.remoteURL(url: $0) }
            let viewModel = FaviconImageViewModel(
                siteURLString: url.absoluteString,
                siteResource: siteResource,
                faviconCornerRadius: UX.faviconCornerRadius
            )
            attributionFaviconImageView.setFavicon(viewModel)
        }

        attributionTitleLabel.text = story.description

        applyTheme(theme: theme)
    }

    // MARK: - Helpers
    private func setupLayout() {
        contentView.layer.cornerRadius = UX.cellCornerRadius

        attributionStackView.addArrangedSubview(attributionFaviconImageView)
        attributionStackView.addArrangedSubview(attributionTitleLabel)

        contentView.addSubviews(thumbnailImageView, titleLabel, attributionStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.verticalSpacing),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                        constant: UX.thumbnailHoritonztalInsets),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                         constant: -UX.thumbnailHoritonztalInsets),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: UX.thumbnailSize.height),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: UX.verticalSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalInsets),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalInsets),

            attributionStackView.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor,
                                                      constant: UX.verticalSpacing),
            attributionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                          constant: UX.horizontalInsets),
            attributionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.horizontalInsets),
            attributionStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                         constant: -UX.attributionStackViewBottomInset),

            attributionFaviconImageView.heightAnchor.constraint(equalToConstant: UX.attributionFaviconSize.height),
            attributionFaviconImageView.widthAnchor.constraint(equalToConstant: UX.attributionFaviconSize.width),
        ])
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = UX.shadowBlurRadius
        contentView.layer.shadowOffset = UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = UX.shadowOpacity // opacity is handled in color
    }

    // Allow full title wrapping when dynamic type > .large, since truncation at larger sizes omits too many words and
    // hurts readability. Otherwise, show 3 lines of the title
    private func getNumberOfLinesForTitle() -> Int {
        return UIApplication.shared.preferredContentSizeCategory > UIContentSizeCategory.large ? 0 : 3
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        attributionTitleLabel.textColor = theme.colors.textSecondary
        setupShadow(theme: theme)
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.titleLabel.numberOfLines = self.getNumberOfLinesForTitle()
            }
        default: break
        }
    }
}
