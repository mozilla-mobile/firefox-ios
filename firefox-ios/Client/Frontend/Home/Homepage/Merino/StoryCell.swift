// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import SiteImageView

/// The cell used in homepage stories section
class StoryCell: UICollectionViewCell, ReusableCell, ThemeApplicable, Blurrable, Notifiable {
    struct UX {
        static let cellCornerRadius: CGFloat = 16
        static let thumbnailImageSize = CGSize(width: 62, height: 62)
        static let thumbnailCornerRadius: CGFloat = 12
        static let descriptionVerticalMargin: CGFloat = 8
        static let descriptionLeadingSpacing: CGFloat = 12
        static let descriptionTrailingMargin: CGFloat = 8
        static let descriptionStackViewSpacing: CGFloat = 8
        static let horizontalMargin: CGFloat = 4
    }

    // MARK: - UI Elements
    private var thumbnailImageView: HeroImageView = .build { _ in }

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
    }

    private lazy var sponsoredLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.caption2.scaledFont()
        label.text = .FirefoxHomepage.Pocket.Sponsored
        label.numberOfLines = 1
    }

    private lazy var descriptionStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.descriptionStackViewSpacing
    }

    var notificationCenter: NotificationProtocol
    private var story: MerinoStoryConfiguration?

    // MARK: - Inits

    override init(frame: CGRect) {
        self.notificationCenter = NotificationCenter.default
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell
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

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        accessibilityLabel = nil
        accessibilityHint = nil
    }

    // MARK: - Helpers

    func configure(story: MerinoStoryConfiguration, theme: Theme, position: Int? = nil, totalCount: Int? = nil) {
        self.story = story
        titleLabel.text = story.title
        titleLabel.numberOfLines = getNumberOfLinesForTitle(isSponsoredStory: !story.shouldHideSponsor)
        accessibilityLabel = story.accessibilityLabel
        if let position = position, let totalCount = totalCount {
            accessibilityHint = String(
                format: .FirefoxHomepage.Pocket.PositionAccessibilityHint,
                String(position),
                String(totalCount)
            )
        }

        let heroImageViewModel = HomepageHeroImageViewModel(urlStringRequest: story.imageURL?.absoluteString ?? "",
                                                            generalCornerRadius: UX.thumbnailCornerRadius,
                                                            faviconCornerRadius: UX.thumbnailCornerRadius,
                                                            heroImageSize: UX.thumbnailImageSize)
        thumbnailImageView.setHeroImage(heroImageViewModel)
        sponsoredLabel.isHidden = story.shouldHideSponsor

        applyTheme(theme: theme)
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = UX.cellCornerRadius

        descriptionStackView.addArrangedSubview(titleLabel)
        descriptionStackView.addArrangedSubview(sponsoredLabel)
        contentView.addSubviews(thumbnailImageView, descriptionStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: UX.thumbnailImageSize.width),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: UX.thumbnailImageSize.height),

            descriptionStackView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor,
                                                      constant: UX.descriptionVerticalMargin),
            descriptionStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            descriptionStackView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor,
                                                          constant: UX.descriptionLeadingSpacing),
            descriptionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                           constant: -UX.descriptionTrailingMargin),
            descriptionStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                                         constant: -UX.descriptionVerticalMargin),
        ])
    }

    // Allow full title wrapping when dynamic type > .large, since truncation at larger sizes omits too many words and
    // hurts readability. Otherwise, show 3 lines of content (title + sponsored label)
    private func getNumberOfLinesForTitle(isSponsoredStory: Bool) -> Int {
        if UIApplication.shared.preferredContentSizeCategory > UIContentSizeCategory.large {
            return 0
        } else if isSponsoredStory {
            return 2
        } else {
            return 3
        }
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        sponsoredLabel.textColor = theme.colors.textPrimary

        adjustBlur(theme: theme)
    }

    // MARK: - Blurrable
    func adjustBlur(theme: Theme) {
        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = UX.cellCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }

    // MARK: - Notifiable
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                guard let story = self.story else { return }
                self.titleLabel.numberOfLines = self.getNumberOfLinesForTitle(isSponsoredStory: !story.shouldHideSponsor)
            }
        default: break
        }
    }
}
