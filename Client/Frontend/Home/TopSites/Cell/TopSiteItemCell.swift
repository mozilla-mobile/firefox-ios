// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import UIKit

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, ReusableCell {

    // MARK: - Variables

    private var homeTopSite: TopSite?

    struct UX {
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 36, height: 36)
        static let imageBackgroundSize = CGSize(width: 60, height: 60)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize: CGSize = CGSize(width: 12, height: 12)
        static let topSpace: CGFloat = 8
        static let textSafeSpace: CGFloat = 8
        static let bottomSpace: CGFloat = 8
        static let imageBottomSpace: CGFloat = 3
        static let titleFontSize: CGFloat = 12
        static let sponsorFontSize: CGFloat = 11
    }

    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .clear
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = HomepageViewModel.UX.generalIconCornerRadius
        imageView.layer.masksToBounds = true
    }

    // Holds the title and the pin image of the top site
    private lazy var titlePinWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.alignment = .center
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
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.pinSmall)
        imageView.isHidden = true
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                        size: UX.titleFontSize)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + HomepageViewModel.UX.shadowRadius
        titleLabel.backgroundColor = .clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
    }

    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption2,
                                                                            size: UX.sponsorFontSize)
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

        imageView.image = nil
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

    func configure(_ topSite: TopSite,
                   favicon: UIImage?,
                   position: Int,
                   theme: Theme) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = topSite.accessibilityLabel

        imageView.image = favicon

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
        rootContainer.addSubview(descriptionWrapper)

        rootContainer.addSubview(imageView)
        rootContainer.addSubview(selectedOverlay)
        contentView.addSubview(rootContainer)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                           constant: UX.topSpace),
            imageView.centerXAnchor.constraint(equalTo: rootContainer.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: UX.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.iconSize.height),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: descriptionWrapper.topAnchor,
                                              constant: -UX.imageBottomSpace),

            descriptionWrapper.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                        constant: UX.textSafeSpace),
            descriptionWrapper.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                         constant: -UX.textSafeSpace),
            descriptionWrapper.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                       constant: -UX.bottomSpace),

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

    private func configurePinnedSite(_ topSite: TopSite) {
        guard topSite.isPinned else { return }

        pinViewHolder.isHidden = false
        pinImageView.isHidden = false
    }

    private func configureSponsoredSite(_ topSite: TopSite) {
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

// MARK: NotificationThemeable
extension TopSiteItemCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        pinImageView.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textPrimary
        sponsoredLabel.textColor = theme.colors.textSecondary
        selectedOverlay.backgroundColor = theme.colors.layer5Hover.withAlphaComponent(0.25)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension TopSiteItemCell: Blurrable {
    func adjustBlur(theme: Theme) {
        rootContainer.setNeedsLayout()
        rootContainer.layoutIfNeeded()

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
