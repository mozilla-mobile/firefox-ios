/*
 Ecosia: This file replaces the one contained in Client/Frontend/Home/TopSites/Cell
 It is done so that we will have minimum conflicts when major updates are needed
 */

import Common
import Foundation
import Shared
import SiteImageView
import Storage
import UIKit

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, ReusableCell {
    // MARK: - Variables

    private var homeTopSite: TopSite?

    struct UX {
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 32, height: 32)
        static let imageBackgroundSize = CGSize(width: 52, height: 52)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize = CGSize(width: 12, height: 12)
        static let textSafeSpace: CGFloat = 6
        static let bottomSpace: CGFloat = 8
        static let imageTopSpace: CGFloat = 12
        static let imageBottomSpace: CGFloat = 12
        static let imageLeadingTrailingSpace: CGFloat = 12
        static let titleFontSize: CGFloat = 12
        static let cellCornerRadius: CGFloat = 26
        static let iconCornerRadius: CGFloat = 4
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = UX.cellCornerRadius
    }

    lazy var imageView: FaviconImageView = .build { _ in }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Small.pinBadgeFill)
        imageView.isHidden = true
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1,
                                                                 size: UX.titleFontSize)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.allowsDefaultTighteningForTruncation = true
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 2
        titleLabel.backgroundColor = .clear
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = UX.cellCornerRadius
        selectedOverlay.backgroundColor = UX.overlayColor
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
                                                      cornerRadius: UX.cellCornerRadius).cgPath
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSite,
                   position: Int,
                   theme: Theme,
                   textColor: UIColor?) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel

        let urlRequest = topSite.site.url
        var imageURL: URL?

        if let site = topSite.site as? SponsoredTile {
            imageURL = URL(string: site.imageURL, invalidCharacters: false)
        }
        let viewModel = FaviconImageViewModel(siteURLString: urlRequest,
                                              faviconURL: imageURL,
                                              faviconCornerRadius: UX.iconCornerRadius)
        imageView.setFavicon(viewModel)
        self.textColor = textColor

        configurePinnedSite(topSite)

        applyTheme(theme: theme)
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        rootContainer.addSubview(imageView)
        rootContainer.addSubview(pinImageView)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(rootContainer)
        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            /* Ecosia: Update constraints
            rootContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.imageBackgroundSize.height),
             */
            rootContainer.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),
            rootContainer.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),
            
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
            
            titleLabel.topAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: UX.titleOffset),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -UX.bottomSpace),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.textSafeSpace),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.textSafeSpace),
            titleLabel.heightAnchor.constraint(equalToConstant: 10).priority(.defaultHigh),

            selectedOverlay.topAnchor.constraint(equalTo: rootContainer.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
        ])
    }

    private func configurePinnedSite(_ topSite: TopSite) {
        guard topSite.isPinned else { return }

        pinImageView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSite) {
        guard topSite.isSponsoredTile else { return }
    }

    private func setupShadow(theme: Theme) {
        rootContainer.layer.cornerRadius = UX.cellCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: rootContainer.bounds,
                                                      cornerRadius: UX.cellCornerRadius).cgPath
        rootContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor
        rootContainer.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        rootContainer.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        rootContainer.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }
}

// MARK: ThemeApplicable
extension TopSiteItemCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        pinImageView.tintColor = textColor ?? theme.colors.iconPrimary
        titleLabel.textColor = textColor ?? theme.colors.textPrimary
        selectedOverlay.backgroundColor = theme.colors.layer5Hover.withAlphaComponent(0.25)
        rootContainer.backgroundColor = .legacyTheme.ecosia.secondaryButton
    }
}

// MARK: - Blurrable
extension TopSiteItemCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            // If blur is disabled set background color
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
