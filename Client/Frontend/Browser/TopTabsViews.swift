// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class TopTabCell: UICollectionViewCell, NotificationThemeable, TabTrayCell {

    static let Identifier = "TopTabCellIdentifier"
    static let ShadowOffsetSize: CGFloat = 2 //The shadow is used to hide the tab separator

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

    let selectedBackground: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.backgroundColor = UIColor.theme.topTabs.tabBackgroundSelected
        view.layer.cornerRadius = TopTabsUX.TabCornerRadius
        view.layer.shadowColor = UIColor(rgb: 0x3a3944).cgColor
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.masksToBounds = false

        return view
    }()

    let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = .left
        titleText.isUserInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.lineBreakMode = .byCharWrapping
        titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        titleText.semanticContentAttribute = .forceLeftToRight
        titleText.isAccessibilityElement = false
        return titleText
    }()

    let favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        favicon.semanticContentAttribute = .forceLeftToRight
        return favicon
    }()

    let closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage.templateImageNamed("menu-CloseTabs"), for: [])
        closeButton.tintColor = UIColor.Photon.Grey40
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 15, left: TopTabsUX.TabTitlePadding, bottom: 15, right: TopTabsUX.TabTitlePadding)
        closeButton.layer.shadowOpacity = 0.8
        closeButton.layer.masksToBounds = false
        closeButton.layer.shadowOffset = CGSize(width: -TopTabsUX.TabTitlePadding, height: 0)
        closeButton.semanticContentAttribute = .forceLeftToRight
        return closeButton
    }()

    weak var delegate: TopTabCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        closeButton.addTarget(self, action: #selector(closeTab), for: .touchUpInside)
        [selectedBackground, titleText, closeButton, favicon].forEach(addSubview)

        selectedBackground.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.height.equalTo(self).multipliedBy(0.82)
            make.center.equalTo(self)
        }

        favicon.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(TopTabsUX.TabNudge)
            make.size.equalTo(GridTabTrayControllerUX.FaviconSize)
            make.leading.equalTo(self).offset(TopTabsUX.TabTitlePadding)
        }
        titleText.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(closeButton.snp.leading).offset(TopTabsUX.TabTitlePadding)
            make.leading.equalTo(favicon.snp.trailing).offset(TopTabsUX.TabTitlePadding)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(TopTabsUX.TabNudge)
            make.height.equalTo(self)
            make.width.equalTo(self.snp.height).offset(-TopTabsUX.TabTitlePadding)
            make.trailing.equalTo(self.snp.trailing)
        }

        self.clipsToBounds = false
    }

    func configureWith(tab: Tab, isSelected selected: Bool) {
        isSelectedTab = selected

        titleText.text = getTabTrayTitle(tab: tab)
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true

        closeButton.accessibilityLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel, self.titleText.text ?? "")

        let hideCloseButton = frame.width < 148 && !selected
        closeButton.isHidden = hideCloseButton

        if let favIcon = tab.displayFavicon, let url = URL(string: favIcon.url) {
            favicon.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultFavicon"), options: [], completed: nil)
        } else {
            favicon.image = UIImage(named: "defaultFavicon")
            favicon.tintColor = UIColor.theme.tabTray.faviconTint
            favicon.contentMode = .scaleAspectFit
            favicon.backgroundColor = .clear
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
}

class TopTabFader: UIView {
    
    enum ActiveSide {
        case left
        case right
        case both
        case none
    }
    
    private var activeSide: ActiveSide = .both
    
    private lazy var hMaskLayer: CAGradientLayer = {
        let hMaskLayer = CAGradientLayer()
        let innerColor = UIColor.Photon.White100.cgColor
        let outerColor = UIColor(white: 1, alpha: 0.0).cgColor
        
        hMaskLayer.anchorPoint = .zero
        hMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        hMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        return hMaskLayer
    }()

    init() {
        super.init(frame: .zero)
        layer.mask = hMaskLayer
    }
    
    func setFader(forSides side: ActiveSide) {
        if activeSide != side {
            self.activeSide = side
            setNeedsLayout()
        }
    }
    
    internal override func layoutSubviews() {
        super.layoutSubviews()

        let widthA = NSNumber(value: Float(CGFloat(8) / frame.width))
        let widthB = NSNumber(value: Float(1 - CGFloat(8) / frame.width))

        // decide on which side the fader should be applied
        switch activeSide {
        case .left:
            hMaskLayer.locations = [0.00, widthA, 1.0, 1.0]
            
        case .right:
            hMaskLayer.locations = [0.00, 0.00, widthB, 1.0]
            
        case .both:
            hMaskLayer.locations = [0.00, widthA, widthB, 1.0]
            
        case .none:
            hMaskLayer.locations = [0.00, 0.00, 1.0, 1.0]
        }
        
        hMaskLayer.frame = CGRect(width: frame.width, height: frame.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabsViewLayoutAttributes: UICollectionViewLayoutAttributes {

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TopTabsViewLayoutAttributes else {
            return false
        }
        return super.isEqual(object)
    }
}
