// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SiteImageView
import Storage
import UIKit

/// The TopSite cell that appears for the homepage rebuild project.
class TopSiteCell: UICollectionViewCell, ReusableCell {
    // MARK: - Variables

    private var homeTopSite: TopSiteState?

    struct UX {
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 36, height: 36)
        static let imageBackgroundSize = CGSize(width: 60, height: 60)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize = CGSize(width: 12, height: 12)
        static let textSafeSpace: CGFloat = 6
        static let bottomSpace: CGFloat = 8
        static let imageTopSpace: CGFloat = 12
        static let imageBottomSpace: CGFloat = 12
        static let imageLeadingTrailingSpace: CGFloat = 12
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    lazy var imageView: FaviconImageView = .build { _ in }

    // Holds the title and the pin image of the top site
    private lazy var titlePinWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillProportionally
    }

    // Holds the titlePinWrapper and the Sponsored text for a sponsored tile
    private lazy var descriptionWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    private lazy var pinViewHolder: UIView = .build { view in
        view.isHidden = true
    }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Small.pinBadgeFill)
        imageView.isHidden = true
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = FXFontStyles.Regular.caption1.scaledFont()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageViewModel.UX.shadowRadius
        titleLabel.backgroundColor = .clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
    }

    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = FXFontStyles.Regular.caption2.scaledFont()
        sponsoredLabel.adjustsFontForContentSizeCategory = true
        sponsoredLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageViewModel.UX.shadowRadius
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    override var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            selectedOverlay.isHidden = !isHighlighted
        }
    }

    private var textColor: UIColor?

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        titleLabel.text = nil
        sponsoredLabel.text = nil
        pinViewHolder.isHidden = true
        pinImageView.isHidden = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedOverlay.isHidden = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        rootContainer.setNeedsLayout()
        rootContainer.layoutIfNeeded()

        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSiteState,
                   position: Int,
                   theme: Theme,
                   textColor: UIColor?) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel

        let siteURLString = topSite.site.url
        var imageResource: SiteResource?

        if let site = topSite.site as? SponsoredTile,
           let url = URL(string: site.imageURL, invalidCharacters: false) {
            imageResource = .remoteURL(url: url)
        } else if let site = topSite.site as? PinnedSite {
            imageResource = site.faviconResource
        } else if let site = topSite.site as? SuggestedSite {
            imageResource = site.faviconResource
        } else if let siteURL = URL(string: siteURLString),
                  let domainNoTLD = siteURL.baseDomain?.split(separator: ".").first,
                  domainNoTLD == "google" {
            // Exception for Google top sites, which all return blurry low quality favicons that on the home screen.
            // Return our bundled G icon for all of the Google Suite.
            // Parse example: "https://drive.google.com/drive/home" > "drive.google.com" > "google"
            imageResource = GoogleTopSiteManager.Constants.faviconResource
        }

        let viewModel = FaviconImageViewModel(siteURLString: siteURLString,
                                              siteResource: imageResource)
        imageView.setFavicon(viewModel)
        self.textColor = textColor

        configurePinnedSite(topSite)
        configureSponsoredSite(topSite)

        applyTheme(theme: theme)
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        titlePinWrapper.addArrangedSubview(pinViewHolder)
        titlePinWrapper.addArrangedSubview(titleLabel)
        pinViewHolder.addSubview(pinImageView)

        descriptionWrapper.addArrangedSubview(titlePinWrapper)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        contentView.addSubview(rootContainer)
        contentView.addSubview(descriptionWrapper)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rootContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.imageBackgroundSize.height),

            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                           constant: UX.imageTopSpace),
            imageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                               constant: UX.imageLeadingTrailingSpace),
            imageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                constant: -UX.imageLeadingTrailingSpace),
            imageView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                              constant: -UX.imageBottomSpace),
            imageView.widthAnchor.constraint(equalToConstant: UX.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.iconSize.height),

            descriptionWrapper.topAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                    constant: UX.textSafeSpace),
            descriptionWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),

            pinViewHolder.bottomAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor,
                                                  constant: UX.pinAlignmentSpacing),
            pinViewHolder.leadingAnchor.constraint(equalTo: pinImageView.leadingAnchor),
            pinViewHolder.trailingAnchor.constraint(equalTo: pinImageView.trailingAnchor,
                                                    constant: UX.titleOffset),
            pinViewHolder.topAnchor.constraint(equalTo: pinImageView.topAnchor),

            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
        ])
    }

    private func configurePinnedSite(_ topSite: TopSiteState) {
        guard topSite.isPinned else { return }

        pinViewHolder.isHidden = false
        pinImageView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSiteState) {
        guard topSite.isSponsoredTile else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
        rootContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootContainer.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }
}

// MARK: ThemeApplicable
extension TopSiteCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        pinImageView.tintColor = textColor ?? theme.colors.iconPrimary
        titleLabel.textColor = textColor ?? theme.colors.textPrimary
        sponsoredLabel.textColor = textColor ?? theme.colors.textSecondary
        selectedOverlay.backgroundColor = theme.colors.layer5Hover.withAlphaComponent(0.25)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension TopSiteCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            rootContainer.layoutIfNeeded()
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            // If blur is disabled set background color
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
