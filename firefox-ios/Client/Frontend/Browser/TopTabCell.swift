// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SiteImageView

class TopTabCell: UICollectionViewCell, ThemeApplicable, ReusableCell, FeatureFlaggable {
    struct UX {
        // MARK: - Favicon and Title Constants
        static let faviconSize: CGFloat = 20
        static let faviconCornerRadius: CGFloat = 2
        static let tabTitlePadding: CGFloat = 10
        static let tabNudge: CGFloat = 1 // Nudge the favicon and close button by 1px

        // MARK: - Tab Appearance Constants
        static let tabCornerRadius: CGFloat = 8
        static let verticalPadding: CGFloat = 15
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: Float = 0.1
        static let shadowOffsetWidth: CGFloat = 0
        static let shadowOffsetHeight: CGFloat = 2

        // MARK: - Close Button Constants
        static let closeButtonThreshold: CGFloat = 148

        // MARK: - Selected Background Constants
        static let backgroundHeightMultiplier: CGFloat = 0.82
    }

    // MARK: - Properties
    var isSelectedTab = false

    weak var delegate: TopTabCellDelegate?

    // MARK: - UI Elements
    let cellBackground: UIView = .build { view in
        view.clipsToBounds = false
        view.layer.cornerRadius = UX.tabCornerRadius
        view.layer.shadowRadius = UX.shadowRadius
        view.layer.shadowOpacity = UX.shadowOpacity
        view.layer.shadowOffset = CGSize(width: UX.shadowOffsetWidth, height: UX.shadowOffsetHeight)
        view.layer.masksToBounds = false
    }

    let titleText: UILabel = .build { label in
        label.textAlignment = .natural
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byCharWrapping
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.semanticContentAttribute = .forceLeftToRight
        label.isAccessibilityElement = false
    }

    let favicon: FaviconImageView = .build { _ in }

    let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalPadding,
                                                                      leading: UX.tabTitlePadding,
                                                                      bottom: UX.verticalPadding,
                                                                      trailing: UX.tabTitlePadding)
        button.layer.masksToBounds = false
        button.semanticContentAttribute = .forceLeftToRight
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        closeButton.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        setupLayout()
    }

    func configureLegacyCellWith(tab: Tab, isSelected selected: Bool, theme: Theme) {
        isSelectedTab = selected

        titleText.text = tab.getTabTrayTitle()
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        showsLargeContentViewer = true
        largeContentTitle = tab.getTabTrayTitle()
        isAccessibilityElement = true

        closeButton.accessibilityLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel,
                                                self.titleText.text ?? "")
        closeButton.showsLargeContentViewer = true
        closeButton.largeContentTitle = .TopSitesRemoveButtonLargeContentTitle
        closeButton.largeContentImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross)
        closeButton.scalesLargeContentImage = true

        let hideCloseButton = frame.width < UX.closeButtonThreshold && !selected
        closeButton.isHidden = hideCloseButton

        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
        favicon.backgroundColor = .clear

        if let siteURL = tab.url?.absoluteString, !tab.isFxHomeTab {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: siteURL,
                                                     faviconCornerRadius: UX.faviconCornerRadius))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func closeTab() {
        delegate?.tabCellDidClose(self)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }

    func applySelectedStyle(theme: Theme) {
        let colors = theme.colors
        favicon.tintColor = colors.textPrimary
        titleText.textColor = colors.textPrimary
        closeButton.tintColor = colors.textPrimary

        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
        let backgroundColor = isToolbarRefactorEnabled ? colors.actionTabActive : colors.layer2
        cellBackground.backgroundColor = backgroundColor
        cellBackground.layer.shadowColor = colors.shadowDefault.cgColor
        cellBackground.isHidden = false
    }

    func applyUnselectedStyle(theme: Theme) {
        let colors = theme.colors
        favicon.tintColor = colors.textPrimary
        titleText.textColor = colors.textPrimary
        closeButton.tintColor = colors.textPrimary

        let isToolbarRefactorEnabled = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
        cellBackground.backgroundColor = isToolbarRefactorEnabled ? colors.actionTabInactive : .clear
        cellBackground.layer.shadowColor = UIColor.clear.cgColor
        cellBackground.isHidden = isToolbarRefactorEnabled ? false : true
    }

    func applyTheme(theme: Theme) {
        if isSelectedTab {
            applySelectedStyle(theme: theme)
        } else {
            applyUnselectedStyle(theme: theme)
        }
    }

    private func setupLayout() {
        addSubviews(cellBackground, titleText, closeButton, favicon)

        NSLayoutConstraint.activate(
            [
                cellBackground.widthAnchor.constraint(equalTo: widthAnchor),
                cellBackground.heightAnchor.constraint(
                    equalTo: heightAnchor,
                    multiplier: UX.backgroundHeightMultiplier
                ),
                cellBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
                cellBackground.centerYAnchor.constraint(equalTo: centerYAnchor),

                favicon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: UX.tabNudge),
                favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize),
                favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize),
                favicon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.tabTitlePadding),

                titleText.centerYAnchor.constraint(equalTo: centerYAnchor),
                titleText.heightAnchor.constraint(equalTo: heightAnchor),
                titleText.leadingAnchor.constraint(
                    equalTo: favicon.trailingAnchor,
                    constant: UX.tabTitlePadding
                ),
                titleText.trailingAnchor.constraint(
                    equalTo: closeButton.leadingAnchor,
                    constant: UX.tabTitlePadding
                ),

                closeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: UX.tabNudge),
                closeButton.widthAnchor.constraint(equalTo: heightAnchor, constant: -UX.tabTitlePadding),
                closeButton.heightAnchor.constraint(equalTo: heightAnchor),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            ]
        )

        clipsToBounds = false
    }

    func getA11yTitleLabel(tab: Tab) -> String? {
        let baseName = tab.getTabTrayTitle()

        if isSelectedTab, !tab.getTabTrayTitle().isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
