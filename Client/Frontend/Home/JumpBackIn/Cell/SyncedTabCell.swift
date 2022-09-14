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
    var shouldAddBlur: Bool
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
class SyncedTabCell: UICollectionViewCell, ReusableCell {

    struct UX {
        static let generalCornerRadius: CGFloat = 12
        static let stackViewShadowRadius: CGFloat = 4
        static let stackViewShadowOffset: CGFloat = 2
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 56, height: 56)
        static let syncedDeviceImageSize = CGSize(width: 24, height: 24)
//        static let itemTitleTopAnchorConstant: CGFloat = 64
        static let itemTitleTopAnchorCompactPhoneConstant: CGFloat = 24
    }

    private var syncedDeviceIconFirstBaselineConstraint: NSLayoutConstraint?
    private var contextualHintViewController: ContextualHintViewController!
    private var syncedDeviceIconCenterConstraint: NSLayoutConstraint?
    private var showAllSyncedTabsAction: (() -> Void)?
    private var itemTitleTopConstraint: NSLayoutConstraint!
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

    private let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .clear
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.heroImage
    }

    private let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline)
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.itemTitle
    }

    // Contains the faviconImage and descriptionLabel
    private var descriptionContainer: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.spacing = 20
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
    }
    
    private var syncInfoContainer: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
//        stackView.spacing = 8
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
    }

    private var syncInfoDescriptionContainer: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
//        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fillEqually
    }

    private let syncedDeviceImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.favIconImage
    }

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1)
        label.textColor = .label
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.descriptionLabel
    }

    // Used as a fallback if hero image isn't set
    private let fallbackFaviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        imageView.layer.cornerRadius = TopSiteItemCell.UX.iconCornerRadius
        imageView.layer.masksToBounds = true
        imageView.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.fallbackFavIconImage
    }

    private var fallbackFaviconBackground: UIView = .build { view in
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
    }

    private var syncDeviceImageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }
    
    private var itemTitleContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // Contains the hero image and fallback favicons
    private var imageContainer: UIView = .build { view in
        view.backgroundColor = .clear
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
                           observing: [.DisplayThemeChanged, .DynamicFontChanged])
        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        contextualHintViewController?.stopTimer()
        notificationCenter.removeObserver(self)
    }

    // MARK: - Helpers

    func configure(viewModel: SyncedTabCellViewModel,
                   onTapShowAllAction: (() -> Void)?,
                   onOpenSyncedTabAction: ((URL) -> Void)?) {
        itemTitle.text = viewModel.titleText
        descriptionLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        cardTitle.text = viewModel.cardTitleText
        configureImages(viewModel: viewModel)

        let contextualHintViewModel = ContextualHintViewModel(
            forHintType: .jumpBackInSyncedTab,
            with: viewModel.profile
        )
        contextualHintViewController = ContextualHintViewController(with: contextualHintViewModel)
        prepareSyncedTabOnJumpBackInContextualHint(with: viewModel.profile)

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
        adjustLayout(shouldAddBlur: viewModel.shouldAddBlur)

        let showAllSyncedTabsA11yAction = UIAccessibilityCustomAction(name: viewModel.syncedTabsButtonText,
                                                                      target: self,
                                                                      selector: #selector(showAllSyncedTabs(_:)))
        let openSyncedTabA11yAction = UIAccessibilityCustomAction(name: viewModel.syncedTabOpenActionTitle,
                                                                  target: self,
                                                                  selector: #selector(didTapSyncedTab(_:)))
        accessibilityCustomActions = [showAllSyncedTabsA11yAction, openSyncedTabA11yAction]
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
            fallbackFaviconImage.image = viewModel.fallbackFaviconImage

        } else if viewModel.heroImage?.size.width == viewModel.heroImage?.size.height {
            // If hero image is a square use it as a favicon
            fallbackFaviconImage.image = viewModel.heroImage

        } else {
            setFallBackFaviconVisibility(isHidden: true)
            heroImage.image = viewModel.heroImage
        }

        syncedDeviceImage.image = viewModel.syncedDeviceImage
    }

    private func setFallBackFaviconVisibility(isHidden: Bool) {
        fallbackFaviconBackground.isHidden = isHidden
        fallbackFaviconImage.isHidden = isHidden
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        heroImage.image = nil
        syncedDeviceImage.image = nil
        fallbackFaviconImage.image = nil
        descriptionLabel.text = nil
        itemTitle.text = nil
        setFallBackFaviconVisibility(isHidden: false)
        applyTheme()

        syncedDeviceImage.isHidden = false
//        tempView.addSubview(syncedDeviceImage)
//        descriptionContainer.addArrangedViewToTop(tempView)
        descriptionContainer.backgroundColor = .cyan
        itemTitle.backgroundColor = .purple
//        syncInfoDescriptionContainer.addArrangedSubview(itemTitle)
        itemTitleContainer.backgroundColor = .systemPink
        syncInfoDescriptionContainer.addArrangedSubview(itemTitleContainer)
        syncInfoDescriptionContainer.backgroundColor = .yellow
        syncInfoDescriptionContainer.addArrangedSubview(descriptionContainer)
        syncInfoContainer.addArrangedSubview(imageContainer)
        syncInfoContainer.addArrangedSubview(syncInfoDescriptionContainer)
        syncInfoContainer.backgroundColor = .orange
    }

    private func setupLayout() {
        setupShadow()

        fallbackFaviconBackground.addSubviews(fallbackFaviconImage)
        imageContainer.addSubviews(heroImage, fallbackFaviconBackground)
        syncDeviceImageContainer.addSubview(syncedDeviceImage)
        itemTitleContainer.addSubview(itemTitle)
        descriptionContainer.addArrangedSubview(syncDeviceImageContainer)
        descriptionContainer.addArrangedSubview(descriptionLabel)
        
//        syncInfoDescriptionContainer.addArrangedSubview(itemTitle)
        syncInfoDescriptionContainer.addArrangedSubview(itemTitleContainer)
        syncInfoDescriptionContainer.backgroundColor = .yellow
        syncInfoDescriptionContainer.addArrangedSubview(descriptionContainer)
        
        syncInfoContainer.addArrangedSubview(imageContainer)
        syncInfoContainer.addArrangedSubview(syncInfoDescriptionContainer)
        
        syncedDeviceImage.backgroundColor = .brown
        descriptionLabel.backgroundColor = .green
        contentView.addSubviews(
            cardTitle,
            syncedTabsButton,
            imageContainer,
            syncedTabTapTargetView,
            syncInfoContainer,
            syncInfoDescriptionContainer)
//
//        itemTitleTopConstraint = itemTitle.topAnchor.constraint(
//            equalTo: syncedTabsButton.bottomAnchor,
//            constant: SyncedTabCell.UX.itemTitleTopAnchorConstant)

        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            syncedTabsButton.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 2), // 8 - button top inset
            syncedTabsButton.leadingAnchor.constraint(equalTo: cardTitle.leadingAnchor, constant: 0),
            syncedTabsButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: 0),

//            itemTitleTopConstraint,
//            itemTitle.leadingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: 16),
//            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Image container, hero image and fallback
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageContainer.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            imageContainer.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),
            imageContainer.topAnchor.constraint(equalTo: topAnchor),
            imageContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            heroImage.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
            heroImage.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),

            fallbackFaviconBackground.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            fallbackFaviconBackground.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),
            fallbackFaviconBackground.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            fallbackFaviconBackground.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            fallbackFaviconImage.heightAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.height),
            fallbackFaviconImage.widthAnchor.constraint(equalToConstant: UX.fallbackFaviconSize.width),
            fallbackFaviconImage.centerXAnchor.constraint(equalTo: fallbackFaviconBackground.centerXAnchor),
            fallbackFaviconImage.centerYAnchor.constraint(equalTo: fallbackFaviconBackground.centerYAnchor),

            
            // Description container, it's image and label
//            descriptionContainer.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
//            descriptionContainer.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
//            descriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            descriptionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            // Sync info description container has title and description container
//            syncInfoDescriptionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            syncInfoDescriptionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            syncInfoDescriptionContainer.topAnchor.constraint(equalTo: syncedTabsButton.bottomAnchor),
//            syncInfoDescriptionContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            // Sync info container has the hero image and sync info description container
            syncInfoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            syncInfoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            syncInfoContainer.topAnchor.constraint(equalTo: syncedTabsButton.bottomAnchor, constant: 24),
            syncInfoContainer.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),



            syncDeviceImageContainer.topAnchor.constraint(equalTo: descriptionContainer.topAnchor),
            syncDeviceImageContainer.bottomAnchor.constraint(equalTo: descriptionContainer.bottomAnchor),
            syncDeviceImageContainer.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor),
            syncDeviceImageContainer.widthAnchor.constraint(equalToConstant: UX.syncedDeviceImageSize.width),
            
            itemTitleContainer.topAnchor.constraint(equalTo: syncInfoDescriptionContainer.topAnchor),
//            tempView2.bottomAnchor.constraint(equalTo: syncInfoDescriptionContainer.bottomAnchor),
            itemTitleContainer.leadingAnchor.constraint(equalTo: syncInfoDescriptionContainer.leadingAnchor),
            itemTitleContainer.trailingAnchor.constraint(equalTo: syncInfoDescriptionContainer.trailingAnchor),
            
            syncedDeviceImage.heightAnchor.constraint(equalToConstant: UX.syncedDeviceImageSize.height),
            syncedDeviceImage.widthAnchor.constraint(equalToConstant: UX.syncedDeviceImageSize.width),
            syncedDeviceImage.topAnchor.constraint(equalTo: syncDeviceImageContainer.topAnchor, constant: 10),
            syncedDeviceImage.leadingAnchor.constraint(equalTo: descriptionContainer.leadingAnchor, constant: 10),

            syncedTabTapTargetView.topAnchor.constraint(equalTo: syncInfoContainer.topAnchor, constant: 0),
            syncedTabTapTargetView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            syncedTabTapTargetView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            syncedTabTapTargetView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            itemTitle.leadingAnchor.constraint(equalTo: itemTitleContainer.leadingAnchor, constant: 10),
            itemTitle.topAnchor.constraint(equalTo: itemTitleContainer.topAnchor, constant: 10)
        ])

        syncedDeviceIconCenterConstraint = descriptionLabel.centerYAnchor.constraint(equalTo: syncedDeviceImage.centerYAnchor).priority(UILayoutPriority(999))
        syncedDeviceIconFirstBaselineConstraint = descriptionLabel.firstBaselineAnchor.constraint(equalTo: syncedDeviceImage.bottomAnchor,
                                                                                         constant: -UX.syncedDeviceImageSize.height / 2)

        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .vertical)
        syncedTabsButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        adjustLayout()
    }

    private func adjustLayout(shouldAddBlur: Bool = false) {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        // Center favicon on smaller font sizes. On bigger font sizes align with first baseline
        syncedDeviceIconCenterConstraint?.isActive = true //!contentSizeCategory.isAccessibilityCategory
        syncedDeviceIconFirstBaselineConstraint?.isActive = false //contentSizeCategory.isAccessibilityCategory
        syncInfoContainer.axis = contentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
        
//        var itemTitleTopAnchorConstant = SyncedTabCell.UX.itemTitleTopAnchorConstant

//        let isPhoneInLandscape = UIDevice.current.userInterfaceIdiom == .phone && UIWindow.isLandscape
//        if traitCollection.horizontalSizeClass == .compact, !isPhoneInLandscape {
//            itemTitleTopAnchorConstant = SyncedTabCell.UX.itemTitleTopAnchorCompactPhoneConstant
//
//        }
//        itemTitleTopConstraint.constant = itemTitleTopAnchorConstant

        // Add blur
        if shouldAddBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
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
            itemTitle.textColor = UIColor.Photon.LightGrey05
            descriptionLabel.textColor = UIColor.Photon.LightGrey40
            fallbackFaviconImage.tintColor = UIColor.Photon.LightGrey40
            fallbackFaviconBackground.backgroundColor = UIColor.Photon.DarkGrey60
            syncedTabsButton.tintColor = UIColor.Photon.LightGrey40
            syncedDeviceImage.image = syncedDeviceImage.image?.tinted(withColor: UIColor.Photon.LightGrey40)
        } else {
            cardTitle.textColor = .black
            itemTitle.textColor = UIColor.Photon.DarkGrey90
            descriptionLabel.textColor = UIColor.Photon.DarkGrey05
            fallbackFaviconImage.tintColor = .black
            fallbackFaviconBackground.backgroundColor = UIColor.Photon.LightGrey10
            syncedTabsButton.tintColor = .black
            syncedDeviceImage.image = syncedDeviceImage.image?.tinted(withColor: .black)
        }

        fallbackFaviconBackground.layer.borderColor = UIColor.theme.homePanel.topSitesBackground.cgColor
    }
}

// MARK: - Notifiable
extension SyncedTabCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}

// MARK: - Contextual Hints related
extension SyncedTabCell: FeatureFlaggable {
    typealias CFRPrefsKeys = PrefsKeys.ContextualHints

    private func prepareSyncedTabOnJumpBackInContextualHint(with profile: Profile) {
        guard contextualHintViewController.shouldPresentHint(),
              featureFlags.isFeatureEnabled(.contextualHintForJumpBackInSyncedTab, checking: .buildOnly)
        else {
            profile.prefs.setBool(false, forKey: CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)
            return
        }

        contextualHintViewController.configure(
            anchor: cardTitle,
            withArrowDirection: .down,
            andDelegate: BrowserViewController.foregroundBVC(),
            presentedUsing: presentContextualHint,
            withActionBeforeAppearing: prepareToPresentHint,
            actionOnDismiss: nil,
            andActionForButton: nil,
            andShouldStartTimerRightAway: true) {
                profile.prefs.setBool(true, forKey: CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue)
            }
    }

    private func presentContextualHint() {
        let bvc = BrowserViewController.foregroundBVC()

        guard bvc.searchController == nil,
              bvc.presentedViewController == nil
        else {
            contextualHintViewController.stopTimer()
            return
        }

        bvc.present(contextualHintViewController, animated: true, completion: nil)

        UIAccessibility.post(notification: .layoutChanged, argument: contextualHintViewController)
    }

    /// We need to leave overlay mode before the hint can show.
    private func prepareToPresentHint() {
        let info: [AnyHashable: Any] = ["contextualHint": ContextualHintType.jumpBackInSyncedTab]
        NotificationCenter.default.post(name: .DidPresentContextualHint, object: self, userInfo: info)
    }

}
