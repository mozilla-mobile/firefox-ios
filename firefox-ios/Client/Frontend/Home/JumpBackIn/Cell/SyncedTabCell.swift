// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView
import Common

struct SyncedTabCellViewModel {
    let profile: Profile
    let titleText: String
    let descriptionText: String
    let url: URL
    var syncedDeviceImage: UIImage?
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
        static let heroImageSize = CGSize(width: 108, height: 80)
        static let syncedDeviceImageSize = CGSize(width: 24, height: 24)
        static let tabStackTopAnchorConstant: CGFloat = 72
        static let tabStackTopAnchorCompactPhoneConstant: CGFloat = 24
    }

    private var syncedDeviceIconFirstBaselineConstraint: NSLayoutConstraint?
    private var syncedDeviceIconCenterConstraint: NSLayoutConstraint?
    private var showAllSyncedTabsAction: (() -> Void)?
    private var tabStackTopConstraint: NSLayoutConstraint?
    private var openSyncedTabAction: (() -> Void)?

    // MARK: - UI Elements
    private var tabHeroImage: HeroImageView = .build { _ in }

    private let cardTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SyncedTab.cardTitle
    }

    private let syncedTabsButton: UIButton = .build { button in
        button.titleLabel?.font = FXFontStyles.Regular.subheadline.scaledFont()
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

    // Contains the tabHeroImage
    private var tabImageContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // contains tabItemTitle and syncedDeviceContainer
    private let tabContentContainer: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let tabItemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
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
        label.font = FXFontStyles.Regular.caption1.scaledFont()
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
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Helpers

    func configure(viewModel: SyncedTabCellViewModel,
                   theme: Theme,
                   onTapShowAllAction: (() -> Void)?,
                   onOpenSyncedTabAction: ((URL) -> Void)?) {
        tabItemTitle.text = viewModel.titleText
        syncedDeviceLabel.text = viewModel.descriptionText
        accessibilityLabel = viewModel.accessibilityLabel
        cardTitle.text = viewModel.cardTitleText

        syncedDeviceImage.image = viewModel.syncedDeviceImage

        let heroViewModel = HomepageHeroImageViewModel(urlStringRequest: viewModel.url.absoluteString,
                                                       heroImageSize: UX.heroImageSize)
        tabHeroImage.setHeroImage(heroViewModel)

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
        adjustLayout()
        applyTheme(theme: theme)

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

    @objc
    func showAllSyncedTabs(_ sender: Any) {
        showAllSyncedTabsAction?()
    }

    @objc
    func didTapSyncedTab(_ sender: Any) {
        openSyncedTabAction?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        syncedDeviceLabel.text = nil
        tabItemTitle.text = nil
    }

    private func setupLayout() {
        tabImageContainer.addSubviews(tabHeroImage)
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
        tabStackTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cardTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            syncedTabsButton.topAnchor.constraint(equalTo: cardTitle.bottomAnchor, constant: 2), // 8 - button top inset
            syncedTabsButton.leadingAnchor.constraint(equalTo: cardTitle.leadingAnchor, constant: 0),
            syncedTabsButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor,
                                                       constant: -16),
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
            syncedTabTapTargetView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            tabContentContainer.heightAnchor.constraint(greaterThanOrEqualTo: tabImageContainer.heightAnchor)
        ])

        syncedDeviceIconCenterConstraint = syncedDeviceLabel.centerYAnchor.constraint(
            equalTo: syncedDeviceImage.centerYAnchor
        ).priority(UILayoutPriority(999))
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
        tabStackTopConstraint?.constant = tabStackTopAnchorConstant
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        contentView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
    }
}

// MARK: - ThemeApplicable
extension SyncedTabCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        cardTitle.textColor  = theme.colors.textPrimary
        tabItemTitle.textColor = theme.colors.textPrimary
        syncedDeviceLabel.textColor = theme.colors.textSecondary
        syncedTabsButton.tintColor = theme.colors.iconPrimary
        syncedDeviceImage.image = syncedDeviceImage.image?.tinted(withColor: theme.colors.iconSecondary)

        let heroImageColors = HeroImageViewColor(faviconTintColor: theme.colors.iconPrimary,
                                                 faviconBackgroundColor: theme.colors.layer1,
                                                 faviconBorderColor: theme.colors.layer1)
        tabHeroImage.updateHeroImageTheme(with: heroImageColors)

        adjustBlur(theme: theme)
    }
}

// MARK: - Blurrable
extension SyncedTabCell: Blurrable {
    func adjustBlur(theme: Theme) {
        // Add blur
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}

// MARK: - Notifiable
extension SyncedTabCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DynamicFontChanged:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
