// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

struct SyncedTabCellViewModel {
    let profile: Profile
    let titleText: String
    let descriptionText: String
    let url: URL
    var syncedDeviceImage: UIImage?
    var heroImage: UIImage?
    var fallbackFaviconImage: UIImage?
    var accessibilityLabel: String {
        return "\(cardTitleText): \(titleText), \(descriptionText)"
    }
    var cardTitleText: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabTitle
    }
    var syncedTabsButtonText: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabShowAllButtonTitle
    }
    var syncedTabOpenActionTitle: String {
        return .FirefoxHomepage.JumpBackIn.SyncedTabOpenTabA11y
    }
}

/// A cell used in FxHomeScreen's Jump Back In section
class SyncedTabCell: BlurrableCollectionViewCell, ReusableCell {

    struct UX {
        static let generalCornerRadius: CGFloat = 12
        static let stackViewShadowRadius: CGFloat = 4
        static let stackViewShadowOffset: CGFloat = 2
        static let heroImageSize = CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 56, height: 56)
        static let syncedDeviceImageSize = CGSize(width: 24, height: 24)
        static let tabStackTopAnchorConstant: CGFloat = 72
        static let tabStackTopAnchorCompactPhoneConstant: CGFloat = 24
    }

    private var syncedDeviceIconFirstBaselineConstraint: NSLayoutConstraint?
    private var syncedDeviceIconCenterConstraint: NSLayoutConstraint?
    private var showAllSyncedTabsAction: (() -> Void)?
    private var tabStackTopConstraint: NSLayoutConstraint!
    private var openSyncedTabAction: (() -> Void)?

    // MARK: - UI Elements
    private let cardTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline, size: 16)
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.cardTitle
    }

    private let syncedTabsButton: UIButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper().preferredFont(withTextStyle: .subheadline, size: 12)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.showAllButton
    }

    // contains tabImageContainer and tabContentContainer
    private let tabStack: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .leading
    }

    // Contains the tabHeroImage and tabFallbackFaviconImage
    private var tabImageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    let tabHeroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .clear
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.heroImage
    }

    // Used as a fallback if hero image isn't set
    let tabFallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = TopSiteItemCell.UX.iconCornerRadius
        imageView.layer.masksToBounds = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.fallbackFavIconImage
    }

    private var tabFallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
    }

    // contains tabItemTitle and syncedDeviceContainer
    private let tabContentContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let tabItemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline)
        label.numberOfLines = 2
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.itemTitle
    }

    // Contains the syncedDeviceImage and syncedDeviceLabel
    private var syncedDeviceContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let syncedDeviceImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.favIconImage
    }

    private let syncedDeviceLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1)
        label.textColor = .label
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.descriptionLabel
    }

    private var syncedTabTapTargetView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.itemCell

        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .DynamicFontChanged,
                                       .WallpaperDidChange])
        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Helpers

    func configure(viewModel: SyncedTabCellViewModel,
                   onTapShowAllAction: (() -> Void)?,
                   onOpenSyncedTabAction: ((URL) -> Void)?) {
        tabItemTitle.text = viewModel.titleText
        syncedDeviceLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        cardTitle.text = viewModel.cardTitleText
        configureImages(viewModel: viewModel)

        let textAttributes: [NSAttributedString.Key: Any] = [ .underlineStyle: NSUnderlineStyle.single.rawValue ]
        let attributeString = NSMutableAttributedString(
            string: viewModel.syncedTabsButtonText,
            attributes: textAttributes
        )

        syncedTabsButton.setAttributedTitle(attributeString, for: .normal)
        syncedTabsButton.addTarget(self, action: #selector(showAllSyncedTabs), for: .touchUpInside)
        showAllSyncedTabsAction = onTapShowAllAction
        openSyncedTabAction = { onOpenSyncedTabAction?(viewModel.url) }

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSyncedTab(_:)))
        syncedTabTapTargetView.addGestureRecognizer(tapRecognizer)
        applyTheme()
        adjustLayout()

        let showAllSyncedTabsA11yAction = UIAccessibilityCustomAction(name: viewModel.syncedTabsButtonText,
                                                                      target: self,
                                                                      selector: #selector(showAllSyncedTabs(_:)))
        let openSyncedTabA11yAction = UIAccessibilityCustomAction(name: viewModel.syncedTabOpenActionTitle,
                                                                  target: self,
                                                                  selector: #selector(didTapSyncedTab(_:)))
        accessibilityCustomActions = [showAllSyncedTabsA11yAction, openSyncedTabA11yAction]
    }

    func getContextualHintAnchor() -> UIView {
        return cardTitle
    }

    @objc func showAllSyncedTabs(_ sender: Any) {
        showAllSyncedTabsAction?()
    }

    @objc func didTapSyncedTab(_ sender: Any) {
        openSyncedTabAction?()
    }

    private func configureImages(viewModel: SyncedTabCellViewModel) {
        if viewModel.heroImage == nil {
            // Sets a small favicon in place of the hero image in case there's no hero image
            tabFallbackFaviconImage.image = viewModel.fallbackFaviconImage

        } else if viewModel.heroImage?.size.width == viewModel.heroImage?.size.height {
            // If hero image is a square use it as a favicon
            tabFallbackFaviconImage.image = viewModel.heroImage

        } else {
            setFallBackFaviconVisibility(isHidden: true)
            tabHeroImage.image = viewModel.heroImage
        }

        syncedDeviceImage.image = viewModel.syncedDeviceImage
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        tabFallbackFaviconBackground.isHidden = isHidden
        tabFallbackFaviconImage.isHidden = isHidden
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tabHeroImage.image = nil
        syncedDeviceImage.image = nil
        tabFallbackFaviconImage.image = nil
        syncedDeviceLabel.text = nil
        tabItemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)
        applyTheme()
    }

    private func setupLayout() {
        setupShadow()

        tabFallbackFaviconBackground.addSubviews(tabFallbackFaviconImage)
        tabImageContainer.addSubviews(tabHeroImage, tabFallbackFaviconBackground)
        syncedDeviceContainer.addSubviews(syncedDeviceImage, syncedDeviceLabel)
        tabContentContainer.addSubviews(tabItemTitle, syncedDeviceContainer)
        tabStack.addArrangedSubview(tabImageContainer)
        tabStack.addArrangedSubview(tabContentContainer)

        contentView.addSubviews(
            cardTitle,
            syncedTabsButton,
            tabStack,
            syncedTabTapTargetView)

        tabStackTopConstraint = tabStack.topAnchor.constraint(
            equalTo: syncedTabsButton.bottomAnchor,
            constant: UX.tabStackTopAnchorConstant)

        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            syncedTabsButton.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 2), // 8 - button top inset
            syncedTabsButton.leadingAnchor.constraint(equalTo: cardTitle.leadingAnchor, constant: 0),
            syncedTabsButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor,
                                                       constant: -16),

            tabStackTopConstraint,
            tabStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tabStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tabStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            tabItemTitle.leadingAnchor.constraint(equalTo: tabContentContainer.leadingAnchor),
            tabItemTitle.trailingAnchor.constraint(equalTo: tabContentContainer.trailingAnchor),
            tabItemTitle.topAnchor.constraint(equalTo: tabContentContainer.topAnchor),

            // Image container, hero image and fallback
            tabImageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            tabImageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            tabHeroImage.topAnchor.constraint(equalTo: tabImageContainer.topAnchor),
            tabHeroImage.leadingAnchor.constraint(equalTo: tabImageContainer.leadingAnchor),
            tabHeroImage.trailingAnchor.constraint(equalTo: tabImageContainer.trailingAnchor),
            tabHeroImage.bottomAnchor.constraint(equalTo: tabImageContainer.bottomAnchor),

            tabFallbackFaviconBackground.centerXAnchor.constraint(equalTo: tabImageContainer.centerXAnchor),
            tabFallbackFaviconBackground.centerYAnchor.constraint(equalTo: tabImageContainer.centerYAnchor),
            tabFallbackFaviconBackground.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            tabFallbackFaviconBackground.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            tabFallbackFaviconImage.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            tabFallbackFaviconImage.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            tabFallbackFaviconImage.centerXAnchor.constraint(equalTo: tabFallbackFaviconBackground.centerXAnchor),
            tabFallbackFaviconImage.centerYAnchor.constraint(equalTo: tabFallbackFaviconBackground.centerYAnchor),

            syncedDeviceImage.topAnchor.constraint(equalTo: syncedDeviceContainer.topAnchor),
            syncedDeviceImage.leadingAnchor.constraint(equalTo: syncedDeviceContainer.leadingAnchor),
            syncedDeviceImage.bottomAnchor.constraint(lessThanOrEqualTo: syncedDeviceContainer.bottomAnchor),

            syncedDeviceLabel.topAnchor.constraint(equalTo: syncedDeviceContainer.firstBaselineAnchor),
            syncedDeviceLabel.leadingAnchor.constraint(equalTo: syncedDeviceImage.trailingAnchor, constant: 8),
            syncedDeviceLabel.trailingAnchor.constraint(equalTo: syncedDeviceContainer.trailingAnchor),
            syncedDeviceLabel.bottomAnchor.constraint(equalTo: syncedDeviceContainer.bottomAnchor),

            // Synced device container, it's image and label
            syncedDeviceContainer.topAnchor.constraint(greaterThanOrEqualTo: tabItemTitle.bottomAnchor, constant: 8),
            syncedDeviceContainer.leadingAnchor.constraint(equalTo: tabContentContainer.leadingAnchor),
            syncedDeviceContainer.trailingAnchor.constraint(equalTo: tabContentContainer.trailingAnchor),
            syncedDeviceContainer.bottomAnchor.constraint(equalTo: tabContentContainer.bottomAnchor),

            syncedDeviceImage.heightAnchor.constraint(equalToConstant: UX.syncedDeviceImageSize.height),
            syncedDeviceImage.widthAnchor.constraint(equalToConstant: UX.syncedDeviceImageSize.width),

            syncedTabTapTargetView.topAnchor.constraint(equalTo: tabStack.topAnchor),
            syncedTabTapTargetView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            syncedTabTapTargetView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            syncedTabTapTargetView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        syncedDeviceIconCenterConstraint = syncedDeviceLabel.centerYAnchor.constraint(equalTo: syncedDeviceImage.centerYAnchor).priority(UILayoutPriority(999))
        syncedDeviceIconFirstBaselineConstraint = syncedDeviceLabel.firstBaselineAnchor.constraint(
            equalTo: syncedDeviceImage.bottomAnchor,
            constant: -UX.syncedDeviceImageSize.height / 2)

        syncedDeviceLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)
        syncedTabsButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            tabStack.axis = .vertical
        } else {
            tabStack.axis = .horizontal
        }

        // Center favicon on smaller font sizes. On bigger font sizes align with first baseline
        syncedDeviceIconCenterConstraint?.isActive = !contentSizeCategory.isAccessibilityCategory
        syncedDeviceIconFirstBaselineConstraint?.isActive = contentSizeCategory.isAccessibilityCategory

        var tabStackTopAnchorConstant = UX.tabStackTopAnchorConstant

        let isPhoneInLandscape = UIDevice.current.userInterfaceIdiom == .phone && UIWindow.isLandscape
        if traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
            tabStackTopAnchorConstant = UX.tabStackTopAnchorCompactPhoneConstant

        }
        tabStackTopConstraint.constant = tabStackTopAnchorConstant

        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = LegacyThemeManager.instance.currentName == .dark ?
            UIColor.Photon.DarkGrey40 : .white
            setupShadow()
        }
    }

    private func setupShadow() {
        contentView.layer.cornerRadius = UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = UX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: UX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12
    }
}

// MARK: - Theme
extension SyncedTabCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            cardTitle.textColor  = UIColor.Photon.LightGrey10
            tabItemTitle.textColor = UIColor.Photon.LightGrey05
            syncedDeviceLabel.textColor = UIColor.Photon.LightGrey40
            tabFallbackFaviconImage.tintColor = UIColor.Photon.LightGrey40
            tabFallbackFaviconBackground.backgroundColor = UIColor.Photon.DarkGrey60
            syncedTabsButton.tintColor = UIColor.Photon.LightGrey40
            syncedDeviceImage.image = syncedDeviceImage.image?.tinted(withColor: UIColor.Photon.LightGrey40)
        } else {
            cardTitle.textColor = .black
            tabItemTitle.textColor = UIColor.Photon.DarkGrey90
            syncedDeviceLabel.textColor = UIColor.Photon.DarkGrey05
            tabFallbackFaviconImage.tintColor = .black
            tabFallbackFaviconBackground.backgroundColor = UIColor.Photon.LightGrey10
            syncedTabsButton.tintColor = .black
            syncedDeviceImage.image = syncedDeviceImage.image?.tinted(withColor: .black)
        }

        tabFallbackFaviconBackground.layer.borderColor = UIColor.theme.homePanel.topSitesBackground.cgColor
    }
}

// MARK: - Notifiable
extension SyncedTabCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged:
                self?.applyTheme()
            case .WallpaperDidChange:
                self?.adjustLayout()
            case .DynamicFontChanged:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
