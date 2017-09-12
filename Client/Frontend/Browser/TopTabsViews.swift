/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TopTabsSeparatorUX {
    static let Identifier = "Separator"
    static let Color = UIColor.white.withAlphaComponent(0.2)
    static let Width: CGFloat = 1
}
class TopTabsSeparator: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = TopTabsSeparatorUX.Color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabCell: UICollectionViewCell {
    enum Style {
        case light
        case dark
    }
    
    static let Identifier = "TopTabCellIdentifier"
    
    var style: Style = .light {
        didSet {
            if style != oldValue {
                applyStyle(style)
            }
        }
    }
    
    var selectedTab = false {
        didSet {
            if style == Style.light {
                titleText.textColor = UIColor.darkText
            } else {
                titleText.textColor = UIColor.lightText
            }
            favicon.alpha = selectedTab ? 1.0 : 0.6
        }
    }
    
    let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = NSTextAlignment.left
        titleText.isUserInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        return titleText
    }()
    
    let favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        return favicon
    }()
    
    let closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "topTabs-closeTabs"), for: UIControlState())
        closeButton.tintColor = UIColor.lightGray

        closeButton.imageEdgeInsets = UIEdgeInsets(equalInset: TabTrayControllerUX.CloseButtonEdgeInset)
        return closeButton
    }()
    
    weak var delegate: TopTabCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        closeButton.addTarget(self, action: #selector(TopTabCell.closeTab), for: UIControlEvents.touchUpInside)
        
        contentView.addSubview(self.closeButton)
        contentView.addSubview(self.titleText)
        contentView.addSubview(self.favicon)

        // The tab needs to be slightly bigger in order for the background view not to appear underneath
        // https://bugzilla.mozilla.org/show_bug.cgi?id=1320135
        let bezierOffset: CGFloat = 3
        favicon.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
            make.leading.equalTo(self).offset(TopTabsUX.TabTitlePadding)
        }
        titleText.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(TopTabsUX.TabTitleWidth)
            make.leading.equalTo(favicon.snp.trailing).offset(TopTabsUX.TabTitlePadding)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(self.snp.height)
            make.leading.equalTo(titleText.snp.trailing).offset(-5)
        }
        
        self.clipsToBounds = false
        
        applyStyle(style)
    }
    
    fileprivate func applyStyle(_ style: Style) {
        switch style {
        case Style.light:
            titleText.textColor = UIColor.darkText
            backgroundColor = UIConstants.AppBackgroundColor
        case Style.dark:
            titleText.textColor = UIColor.lightText
            backgroundColor = UIColor(rgb: 0x4A4A4F)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
    }
    
    func closeTab() {
        delegate?.tabCellDidClose(self)
    }
}

class TopTabFader: UIView {
    lazy var hMaskLayer: CAGradientLayer = {
        let innerColor: CGColor = UIColor(white: 1.0, alpha: 1.0).cgColor
        let outerColor: CGColor = UIColor(white: 1.0, alpha: 0.0).cgColor
        let hMaskLayer = CAGradientLayer()
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        hMaskLayer.locations = [0.00, 0.03, 0.97, 1.0]
        hMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        hMaskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        hMaskLayer.anchorPoint = CGPoint.zero
        return hMaskLayer
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        layer.mask = hMaskLayer
    }
    
    internal override func layoutSubviews() {
        super.layoutSubviews()

        let widthA = NSNumber(value: Float(CGFloat(15.0) / frame.width))
        let widthB = NSNumber(value: Float(1 - CGFloat(15) / frame.width))

        hMaskLayer.locations = [0.00, widthA, widthB, 1.0]
        hMaskLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabsBackgroundDecorationView: UICollectionReusableView {
    static let Identifier = "TopTabsBackgroundDecorationViewIdentifier"

    fileprivate var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive {
        didSet {
            centerBackground.backgroundColor = themeColor
        }
    }
    
    lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        return centerBackground
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .redraw
        self.addSubview(centerBackground)

        centerBackground.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let decorationAttributes = layoutAttributes as? TopTabsViewLayoutAttributes, let themeColor = decorationAttributes.themeColor {
            self.themeColor = themeColor
        }
    }
}

class TopTabsViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var themeColor: UIColor?
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TopTabsViewLayoutAttributes else {
            return false
        }
        if object.themeColor != self.themeColor {
            return false
        }
        return super.isEqual(object)
    }
}
