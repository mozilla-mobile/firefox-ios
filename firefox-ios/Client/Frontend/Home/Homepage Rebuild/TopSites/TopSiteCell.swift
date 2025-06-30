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

    private var homeTopSite: TopSiteConfiguration?

    struct UX {
        static let imageBackgroundSize = CGSize(width: 60, height: 60)
        static let pinIconSize = CGSize(width: 12, height: 12)
        static let pinBackgroundSize = CGSize(width: 16, height: 16)
        static let pinBackgroundCornerRadius: CGFloat = pinBackgroundSize.width / 2
        static let pinBackgroundShadowOffset = CGSize(width: 1, height: 1)
        static let pinBackgroundShadowOpacity: Float = 1.0
        static let pinBackgroundShadowRadius: CGFloat = 4.0
        static let textSafeSpace: CGFloat = 6
        static let faviconCornerRadius: CGFloat = 16
        static let faviconTransparentBackgroundInset: CGFloat = 8
        static let transparencyThreshold: CGFloat = 15
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = UX.faviconCornerRadius
    }

    private lazy var imageView: FaviconImageView = {
        let imageView = FaviconImageView {
            self.configureFaviconWithTransparency()
        }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var descriptionWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    private lazy var pinImageBackgroundView: UIView = .build { view in
        view.backgroundColor = LightTheme().colors.layer2
        view.layer.cornerRadius = UX.pinBackgroundCornerRadius
        view.isHidden = true
    }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.pinFill)
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = FXFontStyles.Bold.caption1.scaledFont()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageViewModel.UX.shadowRadius
        titleLabel.backgroundColor = .clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
    }

    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = FXFontStyles.Regular.caption1.scaledFont()
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
    private var imageViewConstraints: [NSLayoutConstraint] = []
    private var theme: Theme?

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
        pinImageBackgroundView.isHidden = true
        imageViewConstraints.forEach { $0.constant = 0 }
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
                                                      cornerRadius: UX.faviconCornerRadius).cgPath

        pinImageBackgroundView.layer.shadowPath = UIBezierPath(roundedRect: pinImageBackgroundView.bounds,
                                                               cornerRadius: UX.pinBackgroundCornerRadius).cgPath
        pinImageBackgroundView.layer.shadowColor = theme?.colors.shadowStrong.cgColor
        pinImageBackgroundView.layer.shadowOpacity = UX.pinBackgroundShadowOpacity
        pinImageBackgroundView.layer.shadowOffset = UX.pinBackgroundShadowOffset
        pinImageBackgroundView.layer.shadowRadius = UX.pinBackgroundShadowRadius
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSiteConfiguration,
                   position: Int,
                   theme: Theme,
                   textColor: UIColor?) {
        self.theme = theme
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel
        accessibilityTraits = .link

        let siteURLString = topSite.site.url
        var imageResource: SiteResource?

        switch topSite.type {
        case .sponsoredSite(let siteInfo):
            if let url = URL(string: siteInfo.imageURL) {
                imageResource = .remoteURL(url: url)
            }
        case .pinnedSite, .suggestedSite:
            imageResource = topSite.site.faviconResource
        default:
            break
        }

        if imageResource == nil,
           let siteURL = URL(string: siteURLString),
           let domainNoTLD = siteURL.baseDomain?.split(separator: ".").first,
           domainNoTLD == "google" {
            // Exception for Google top sites, which all return blurry low quality favicons that on the home screen.
            // Return our bundled G icon for all of the Google Suite.
            // Parse example: "https://drive.google.com/drive/home" > "drive.google.com" > "google"
            imageResource = GoogleTopSiteManager.Constants.faviconResource
        }

        let viewModel = FaviconImageViewModel(siteURLString: siteURLString,
                                              siteResource: imageResource,
                                              faviconCornerRadius: UX.faviconCornerRadius)
        imageView.setFavicon(viewModel)
        self.textColor = textColor

        configurePinnedSite(topSite)
        configureSponsoredSite(topSite)
        configureFaviconWithTransparency()

        applyTheme(theme: theme)
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        pinImageBackgroundView.addSubview(pinImageView)

        descriptionWrapper.addArrangedSubview(titleLabel)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        rootContainer.addSubview(pinImageBackgroundView)
        contentView.addSubview(rootContainer)
        contentView.addSubview(descriptionWrapper)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rootContainer.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),

            descriptionWrapper.topAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: UX.textSafeSpace),
            descriptionWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            descriptionWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),

            pinImageView.centerXAnchor.constraint(equalTo: pinImageBackgroundView.centerXAnchor),
            pinImageView.centerYAnchor.constraint(equalTo: pinImageBackgroundView.centerYAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),

            pinImageBackgroundView.topAnchor.constraint(equalTo: rootContainer.topAnchor, constant: -4),
            pinImageBackgroundView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: -4),
            pinImageBackgroundView.widthAnchor.constraint(equalToConstant: UX.pinBackgroundSize.width),
            pinImageBackgroundView.heightAnchor.constraint(equalToConstant: UX.pinBackgroundSize.height),
        ])

        imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
        ]
        NSLayoutConstraint.activate(imageViewConstraints)
    }

    private func configurePinnedSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isPinned else { return }

        pinImageBackgroundView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isSponsored else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }

    // Add insets to favicons with transparent backgrounds
    private func configureFaviconWithTransparency() {
        guard let image = imageView.image,
              let percentTransparent = image.percentTransparent,
              percentTransparent > UX.transparencyThreshold else { return }

        self.imageViewConstraints.forEach { constraint in
            if constraint.firstAttribute == .trailing || constraint.firstAttribute == .bottom {
                constraint.constant = -UX.faviconTransparentBackgroundInset
            } else {
                constraint.constant = UX.faviconTransparentBackgroundInset
            }
            // Inner corner radius = outer corner radius - inset
            self.imageView.layer.cornerRadius = UX.faviconCornerRadius - UX.faviconTransparentBackgroundInset
        }
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.cornerRadius = UX.faviconCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.faviconCornerRadius).cgPath
        rootContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
        rootContainer.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }
}

// MARK: ThemeApplicable
extension TopSiteCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        titleLabel.textColor = textColor ?? theme.colors.textPrimary
        sponsoredLabel.textColor = textColor ?? theme.colors.textPrimary
        selectedOverlay.backgroundColor = theme.colors.layer5Hover.withAlphaComponent(0.25)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension TopSiteCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            rootContainer.layoutIfNeeded()
            rootContainer.addBlurEffect(using: .systemThickMaterial)
        } else {
            // If blur is disabled set background color
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
