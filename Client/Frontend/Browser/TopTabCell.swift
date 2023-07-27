// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import SiteImageView

class TopTabCell: UICollectionViewCell, ThemeApplicable, TabTrayCell, ReusableCell {
    struct UX {
        static let faviconSize: CGFloat = 20
        static let faviconCornerRadius: CGFloat = 2
        static let tabCornerRadius: CGFloat = 8
        static let tabNudge: CGFloat = 1 // Nudge the favicon and close button by 1px
        static let tabTitlePadding: CGFloat = 10
    }

    // MARK: - Properties
    var isSelectedTab = false

    weak var delegate: TopTabCellDelegate?

    // MARK: - UI Elements
    let selectedBackground: UIView = .build { view in
        view.clipsToBounds = false
        view.layer.cornerRadius = UX.tabCornerRadius
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.masksToBounds = false
    }

    let titleText: UILabel = .build { label in
        label.textAlignment = .natural
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byCharWrapping
        label.font = LegacyDynamicFontHelper.defaultHelper.DefaultSmallFont
        label.semanticContentAttribute = .forceLeftToRight
        label.isAccessibilityElement = false
    }

    let favicon: FaviconImageView = .build { _ in }

    let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.imageEdgeInsets = UIEdgeInsets(top: 15,
                                              left: UX.tabTitlePadding,
                                              bottom: 15,
                                              right: UX.tabTitlePadding)
        button.layer.masksToBounds = false
        button.semanticContentAttribute = .forceLeftToRight
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        closeButton.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        setupLayout()
    }

    func configureWith(tab: Tab, isSelected selected: Bool, theme: Theme) {
        isSelectedTab = selected

        titleText.text = tab.getTabTrayTitle()
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true

        closeButton.accessibilityLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel,
                                                self.titleText.text ?? "")

        let hideCloseButton = frame.width < 148 && !selected
        closeButton.isHidden = hideCloseButton

        favicon.image = UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate)
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
        favicon.tintColor = theme.colors.textPrimary
        titleText.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textPrimary

        selectedBackground.backgroundColor = theme.colors.layer2
        selectedBackground.layer.shadowColor = theme.colors.shadowDefault.cgColor
        selectedBackground.isHidden = false
    }

    func applyUnselectedStyle(theme: Theme) {
        favicon.tintColor = theme.colors.textPrimary
        titleText.textColor = theme.colors.textPrimary
        closeButton.tintColor = theme.colors.textPrimary

        selectedBackground.backgroundColor = .clear
        selectedBackground.layer.shadowColor = UIColor.clear.cgColor
        selectedBackground.isHidden = true
    }

    func applyTheme(theme: Theme) {
        if isSelectedTab {
            applySelectedStyle(theme: theme)
        } else {
            applyUnselectedStyle(theme: theme)
        }
    }

    private func setupLayout() {
        addSubviews(selectedBackground, titleText, closeButton, favicon)

        NSLayoutConstraint.activate([
            selectedBackground.widthAnchor.constraint(equalTo: widthAnchor),
            selectedBackground.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.82),
            selectedBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectedBackground.centerYAnchor.constraint(equalTo: centerYAnchor),

            favicon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: UX.tabNudge),
            favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            favicon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.tabTitlePadding),

            titleText.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleText.heightAnchor.constraint(equalTo: heightAnchor),
            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor, constant: UX.tabTitlePadding),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                constant: UX.tabTitlePadding),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: UX.tabNudge),
            closeButton.widthAnchor.constraint(equalTo: heightAnchor, constant: -UX.tabTitlePadding),
            closeButton.heightAnchor.constraint(equalTo: heightAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        clipsToBounds = false
    }
}
