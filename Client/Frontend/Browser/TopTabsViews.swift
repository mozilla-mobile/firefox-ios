/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct TopTabsSeparatorUX {
    static let Identifier = "Separator"
    static let Color = UIColor(rgb: 0x3c3c3d)
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
            backgroundColor = selectedTab ? UIColor(rgb:0xf9f9fa) : UIColor(rgb: 0x272727)
            titleText.textColor = selectedTab ? UIColor(rgb:0x0c0c0d) : UIColor(rgb: 0xb1b1b3)
            highlightLine.isHidden = !selectedTab
            closeButton.tintColor = selectedTab ? UIColor(rgb: 0x272727) : UIColor(rgb: 0xb1b1b3)
            closeButton.backgroundColor = backgroundColor
            closeButton.layer.shadowColor = backgroundColor?.cgColor
            if style == .dark && selectedTab {
                backgroundColor =  UIColor(rgb: 0x4A4A4F)
                titleText.textColor = UIColor(rgb: 0xf9f9fa)
                closeButton.tintColor = UIColor(rgb: 0xf9f9fa)
                closeButton.backgroundColor = backgroundColor
                closeButton.layer.shadowColor = backgroundColor?.cgColor
            }

        }
    }
    
    let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = NSTextAlignment.left
        titleText.isUserInteractionEnabled = false
        titleText.numberOfLines = 1
        titleText.lineBreakMode = .byCharWrapping
        titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
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
        closeButton.setImage(UIImage.templateImageNamed("menu-CloseTabs"), for: UIControlState())
        closeButton.tintColor = UIColor(rgb: 0xb1b1b3)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        closeButton.layer.shadowOpacity = 0.8
        closeButton.layer.masksToBounds = false
        closeButton.layer.shadowOffset = CGSize(width: -10, height: 0)

        return closeButton
    }()

    let highlightLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor(rgb:0x0066DC)
        line.isHidden = true
        return line
    }()

//    let titleFadeView: UIView = {
//        let view
//    }

    weak var delegate: TopTabCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        closeButton.addTarget(self, action: #selector(TopTabCell.closeTab), for: UIControlEvents.touchUpInside)

        contentView.addSubview(titleText)
        contentView.addSubview(closeButton)
        contentView.addSubview(favicon)
        contentView.addSubview(highlightLine)

        favicon.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(1)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
            make.leading.equalTo(self).offset(TopTabsUX.TabTitlePadding)
        }
        titleText.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.trailing.equalTo(closeButton.snp.leading).offset(10)
            make.leading.equalTo(favicon.snp.trailing).offset(TopTabsUX.TabTitlePadding)
        }
        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self).offset(1)
            make.height.equalTo(self)
            make.width.equalTo(self.snp.height).offset(-10)
            make.trailing.equalTo(self.snp.trailing)
        }
        highlightLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(3)
        }
        
        self.clipsToBounds = false
        
        applyStyle(style)
    }
    
    fileprivate func applyStyle(_ style: Style) {
        switch style {
        case Style.light:
            titleText.textColor = UIColor.darkText
            backgroundColor = UIConstants.AppBackgroundColor
            highlightLine.backgroundColor = UIColor(rgb:0x0066DC)
        case Style.dark:
            titleText.textColor = UIColor.lightText
            backgroundColor = UIColor(rgb: 0x4A4A4F)
            highlightLine.backgroundColor = UIColor(rgb: 0x9400ff)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func closeTab() {
        delegate?.tabCellDidClose(self)
    }
}

class TopTabFader: UIView {
    lazy var hMaskLayer: CAGradientLayer = {
        let innerColor: CGColor = UIColor(white: 1, alpha: 1).cgColor
        let outerColor: CGColor = UIColor(white: 1, alpha: 0).cgColor
        let hMaskLayer = CAGradientLayer()
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        hMaskLayer.locations = [0.00, 0.005, 0.995, 1.0]
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

    fileprivate var themeColor: UIColor = UIColor(rgb: 0x272727) {
        didSet {
            centerBackground.backgroundColor = UIColor(rgb: 0x272727)
        }
    }
    
    lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        return centerBackground
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .redraw
        self.backgroundColor = UIColor(rgb: 0x272727)
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
