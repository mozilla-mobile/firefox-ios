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
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize = CGSize(width: 16, height: 16)
        static let textSafeSpace: CGFloat = 6
        static let faviconCornerRadius: CGFloat = 16
        static let faviconTransparentBackgroundInset: CGFloat = 8
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
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

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Small.pinBadgeFill)
        imageView.isHidden = true
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
    private var pinHeightConstraint: NSLayoutConstraint?
    private var pinWidthConstraint: NSLayoutConstraint?
    private var pinImageTrailingToTextConstraint: NSLayoutConstraint?
    private var smallContentConstraints: [NSLayoutConstraint] = []
    private var largeContentConstraints: [NSLayoutConstraint] = []
    private var imageViewConstraints: [NSLayoutConstraint] = []

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
        pinImageView.isHidden = true
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
        updateDynamicConstraints()

        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.faviconCornerRadius).cgPath

        alignPinWithText()
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSiteConfiguration,
                   position: Int,
                   theme: Theme,
                   textColor: UIColor?) {
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

    func updateDynamicConstraints() {
        NSLayoutConstraint.deactivate(smallContentConstraints)
        NSLayoutConstraint.deactivate(largeContentConstraints)

        if UIApplication.shared.preferredContentSizeCategory <= .extraLarge || pinImageView.isHidden {
            NSLayoutConstraint.activate(smallContentConstraints)
        } else {
            NSLayoutConstraint.activate(largeContentConstraints)
        }

        // Scales the pin icon with dynamic type, using a minimum height of UX.pinIconSize
        let dynamicWidth = max(UIFontMetrics.default.scaledValue(for: UX.pinIconSize.width), UX.pinIconSize.width)
        let dynamicHeight = max(UIFontMetrics.default.scaledValue(for: UX.pinIconSize.height), UX.pinIconSize.height)
        pinWidthConstraint?.constant = dynamicWidth
        pinHeightConstraint?.constant = dynamicHeight

        layoutIfNeeded()
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        descriptionWrapper.addArrangedSubview(titleLabel)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        contentView.addSubview(rootContainer)
        contentView.addSubview(descriptionWrapper)
        contentView.addSubview(pinImageView)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            rootContainer.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),

            descriptionWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            descriptionWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
        ])

        imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
        ]
        NSLayoutConstraint.activate(imageViewConstraints)

        // Constraints used for changing the layout based on dynamic type
        // When preferredContentSizeCategory is > extraLarge, place the pin icon above the title (largeContentConstraints)
        // When preferredContentSizeCategory is <= extraLarge, place the pin icon in front of (smallContentConstraints)
        let trailingConstraint = pinImageView.trailingAnchor.constraint(equalTo: contentView.leadingAnchor)
        pinImageTrailingToTextConstraint = trailingConstraint

        smallContentConstraints = [
            pinImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            pinImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            pinImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            trailingConstraint,
            descriptionWrapper.topAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                    constant: UX.textSafeSpace),
        ]

        largeContentConstraints = [
            pinImageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            pinImageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            pinImageView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            pinImageView.topAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: UX.textSafeSpace),
            descriptionWrapper.topAnchor.constraint(equalTo: pinImageView.bottomAnchor)
        ]

        let bottomConstraint = descriptionWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        bottomConstraint.isActive = true
        pinHeightConstraint = pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height)
        pinHeightConstraint?.isActive = true
        pinWidthConstraint = pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width)
        pinWidthConstraint?.isActive = true

        updateDynamicConstraints()
    }

    private func alignPinWithText() {
        guard !pinImageView.isHidden else { return }

        // Aligns pinImageView with the leading edge of the visible text in titleLabel instead of the label
        // This ensures correct positioning when the text is center-aligned
        // Uses async update to account for dynamic type and text alignment changes.
        DispatchQueue.main.async {
            let labelBounds = self.titleLabel.bounds
            let textRect = self.titleLabel.textRect(forBounds: labelBounds,
                                                    limitedToNumberOfLines: self.titleLabel.numberOfLines
            )
            let textStartInContentView = self.titleLabel.convert(textRect.origin, to: self.contentView).x
            self.pinImageTrailingToTextConstraint?.constant = textStartInContentView - UX.pinAlignmentSpacing
        }
    }

    private func configurePinnedSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isPinned else { return }

        pinImageView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSiteConfiguration) {
        guard topSite.isSponsored else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }

    // Add insets to favicons with transparent backgrounds
    private func configureFaviconWithTransparency() {
        let transparencyThreshold: CGFloat = 10
        guard let image = imageView.image,
              let percentTransparent = image.percentTransparent,
              percentTransparent > transparencyThreshold else { return }

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
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            // If blur is disabled set background color
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
