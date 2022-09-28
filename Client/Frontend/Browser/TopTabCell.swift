// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class TopTabCell: UICollectionViewCell, NotificationThemeable, TabTrayCell, ReusableCell {

    // MARK: - Properties
    var isSelectedTab = false {
        didSet {
            backgroundColor = .clear
            titleText.textColor = UIColor.theme.topTabs.tabForegroundSelected
            closeButton.tintColor = UIColor.theme.topTabs.closeButtonSelectedTab
            closeButton.backgroundColor = backgroundColor
            closeButton.layer.shadowColor = backgroundColor?.cgColor
            selectedBackground.isHidden = !isSelectedTab
        }
    }

    weak var delegate: TopTabCellDelegate?

    // MARK: - UI Elements
    let selectedBackground: UIView = .build { view in
        view.clipsToBounds = false
        view.backgroundColor = UIColor.theme.topTabs.tabBackgroundSelected
        view.layer.cornerRadius = TopTabsUX.TabCornerRadius
        view.layer.shadowColor = UIColor(rgb: 0x3a3944).cgColor
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.masksToBounds = false
    }

    let titleText: UILabel = .build { label in
        label.textAlignment = .natural
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.lineBreakMode = .byCharWrapping
        label.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        label.semanticContentAttribute = .forceLeftToRight
        label.isAccessibilityElement = false
    }

    let favicon: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = 2.0
        imageView.layer.masksToBounds = true
        imageView.semanticContentAttribute = .forceLeftToRight
    }

    let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.closeTap), for: [])
        button.tintColor = UIColor.Photon.Grey40
        button.imageEdgeInsets = UIEdgeInsets(top: 15,
                                              left: TopTabsUX.TabTitlePadding,
                                              bottom: 15,
                                              right: TopTabsUX.TabTitlePadding)
        button.layer.shadowOpacity = 0.8
        button.layer.masksToBounds = false
        button.layer.shadowOffset = CGSize(width: -TopTabsUX.TabTitlePadding, height: 0)
        button.semanticContentAttribute = .forceLeftToRight
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        closeButton.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        setupLayout()
    }

    func configureWith(tab: Tab, isSelected selected: Bool) {
        isSelectedTab = selected

        titleText.text = tab.getTabTrayTitle()
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true

        closeButton.accessibilityLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel,
                                                self.titleText.text ?? "")

        let hideCloseButton = frame.width < 148 && !selected
        closeButton.isHidden = hideCloseButton

        favicon.image = UIImage(named: ImageIdentifiers.defaultFavicon)
        favicon.tintColor = UIColor.theme.tabTray.faviconTint
        favicon.contentMode = .scaleAspectFit
        favicon.backgroundColor = .clear

        if let favIcon = tab.displayFavicon, let url = URL(string: favIcon.url) {
            ImageLoadingHandler.shared.getImageFromCacheOrDownload(
                with: url,
                limit: ImageLoadingConstants.NoLimitImageSize) { image, error in
                guard error == nil, let image = image else { return }
                self.favicon.image = image
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func closeTab() {
        delegate?.tabCellDidClose(self)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }

    func applyTheme() {
        selectedBackground.backgroundColor = UIColor.theme.topTabs.tabBackgroundSelected
    }

    private func setupLayout() {
        addSubviews(selectedBackground, titleText, closeButton, favicon)

        NSLayoutConstraint.activate([
            selectedBackground.widthAnchor.constraint(equalTo: widthAnchor),
            selectedBackground.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.82),
            selectedBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectedBackground.centerYAnchor.constraint(equalTo: centerYAnchor),

            favicon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: TopTabsUX.TabNudge),
            favicon.widthAnchor.constraint(equalToConstant: GridTabTrayControllerUX.FaviconSize),
            favicon.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.FaviconSize),
            favicon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: TopTabsUX.TabTitlePadding),

            titleText.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleText.heightAnchor.constraint(equalTo: heightAnchor),
            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor, constant: TopTabsUX.TabTitlePadding),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                constant: TopTabsUX.TabTitlePadding),

            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: TopTabsUX.TabNudge),
            closeButton.widthAnchor.constraint(equalTo: heightAnchor, constant: -TopTabsUX.TabTitlePadding),
            closeButton.heightAnchor.constraint(equalTo: heightAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        self.clipsToBounds = false
    }
}
