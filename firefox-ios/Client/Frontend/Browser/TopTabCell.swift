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
        static let tabTitlePaddingVersion: CGFloat = 14

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

    private var windowUUID: WindowUUID?

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
        button.configuration = .plain()
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
        windowUUID = tab.windowUUID

        titleText.text = tab.getTabTrayTitle()
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        showsLargeContentViewer = true
        largeContentTitle = tab.getTabTrayTitle()
        isAccessibilityElement = true

        closeButton.accessibilityLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel,
                                                self.titleText.text ?? "")
        closeButton.showsLargeContentViewer = true
        closeButton.largeContentTitle = .TopSitesRemoveButtonLargeContentTitle
        closeButton.configuration?.image = UIImage.templateImageNamed(StandardImageIdentifiers.Medium.cross)
        closeButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalPadding,
                                                                           leading: UX.tabTitlePaddingVersion,
                                                                           bottom: UX.verticalPadding,
                                                                           trailing: UX.tabTitlePaddingVersion)
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

        let backgroundColor = colors.actionTabActive
        cellBackground.backgroundColor = backgroundColor
        cellBackground.layer.shadowColor = colors.shadowDefault.cgColor
        cellBackground.isHidden = false
    }

    func applyUnselectedStyle(theme: Theme) {
        let colors = theme.colors
        favicon.tintColor = colors.textPrimary
        titleText.textColor = colors.textPrimary
        closeButton.tintColor = colors.textPrimary

        cellBackground.backgroundColor = .clear
        cellBackground.layer.shadowColor = UIColor.clear.cgColor
        cellBackground.isHidden = false
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

                favicon.centerYAnchor.constraint(equalTo: centerYAnchor),
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

                closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                closeButton.widthAnchor.constraint(equalTo: heightAnchor, constant: -UX.tabTitlePadding),
                closeButton.heightAnchor.constraint(equalTo: heightAnchor, constant: -UX.tabTitlePadding),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            ]
        )

        clipsToBounds = false
    }

    func getA11yTitleLabel(tab: Tab) -> String? {
        let baseName = tab.getTabTrayTitle()

        if isSelectedTab, !tab.getTabTrayTitle().isEmpty {
            return baseName + ". " + String.TabsTray.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabsTray.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
