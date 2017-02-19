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
            bezierView.isHidden = !selectedTab
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
    
    fileprivate let bezierView: BezierView = {
        let bezierView = BezierView()
        bezierView.fillColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
        return bezierView
    }()
    
    weak var delegate: TopTabCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        closeButton.addTarget(self, action: #selector(TopTabCell.closeTab), for: UIControlEvents.touchUpInside)
        
        contentView.addSubview(self.bezierView)
        contentView.addSubview(self.closeButton)
        contentView.addSubview(self.titleText)
        contentView.addSubview(self.favicon)

        // The tab needs to be slightly bigger in order for the background view not to appear underneath
        // https://bugzilla.mozilla.org/show_bug.cgi?id=1320135
        let bezierOffset: CGFloat = 3
        bezierView.snp.makeConstraints { make in
            make.centerY.centerX.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(frame.width + TopTabsUX.TopTabsBackgroundPadding + bezierOffset)
        }
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
        
        backgroundColor = UIColor.clear
        // Default style is light
        applyStyle(style)
    }
    
    fileprivate func applyStyle(_ style: Style) {
        switch style {
        case Style.light:
            bezierView.fillColor = TopTabsUX.TopTabsBackgroundNormalColor
            titleText.textColor = UIColor.darkText
        case Style.dark:
            bezierView.fillColor = TopTabsUX.TopTabsBackgroundPrivateColor
            titleText.textColor = UIColor.lightText
        }
        bezierView.setNeedsDisplay()
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

private class BezierView: UIView {
    var fillColor: UIColor?
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let fillColor = self.fillColor else {
            return
        }
        let bezierPath = UIBezierPath.topTabsCurve(frame.width, height: frame.height, direction: .both)
        
        fillColor.setFill()
        bezierPath.fill()
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
    fileprivate lazy var rightCurve = SingleCurveView(right: true)
    fileprivate lazy var leftCurve = SingleCurveView(right: false)
    
    fileprivate var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive {
        didSet {
            centerBackground.backgroundColor = themeColor
            for curve in [rightCurve, leftCurve] {
                curve.themeColor = themeColor
                curve.setNeedsDisplay()
            }
        }
    }
    
    lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        return centerBackground
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .redraw
        
        self.addSubview(rightCurve)
        self.addSubview(leftCurve)
        self.addSubview(centerBackground)
        
        rightCurve.snp.makeConstraints { make in
            make.right.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        leftCurve.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        centerBackground.snp.makeConstraints { make in
            make.left.equalTo(leftCurve.snp.right)
            make.right.equalTo(rightCurve.snp.left)
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
    
    fileprivate class SingleCurveView: UIView {
        static let CurveWidth: CGFloat = 50
        fileprivate var themeColor: UIColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
        var right: Bool = true
        init(right: Bool) {
            self.right = right
            super.init(frame: CGRect.zero)
            self.backgroundColor = UIColor.clear
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            let bezierPath = UIBezierPath.topTabsCurve(frame.width, height: frame.height, direction: right ? .right : .left)
            themeColor.setFill()
            bezierPath.fill()
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

enum TopTabsCurveDirection {
    case right
    case left
    case both
}

extension UIBezierPath {
    static func topTabsCurve(_ width: CGFloat, height: CGFloat, direction: TopTabsCurveDirection) -> UIBezierPath {
        let x1: CGFloat = 32.84
        let x2: CGFloat = 5.1
        let x3: CGFloat = 19.76
        let x4: CGFloat = 58.27
        let x5: CGFloat = -12.15
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width, y: height))
        switch direction {
        case .right:
            bezierPath.addCurve(to: CGPoint(x: width-x1, y: 0), controlPoint1: CGPoint(x: width-x3, y: height), controlPoint2: CGPoint(x: width-x2, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 0, y: 0), controlPoint1: CGPoint(x: 0, y: 0), controlPoint2: CGPoint(x: 0, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 0, y: height), controlPoint2: CGPoint(x: 0, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: x5, y: height), controlPoint2: CGPoint(x: width-x5, y: height))
        case .left:
            bezierPath.addCurve(to: CGPoint(x: width, y: 0), controlPoint1: CGPoint(x: width, y: 0), controlPoint2: CGPoint(x: width, y: 0))
            bezierPath.addCurve(to: CGPoint(x: x1, y: 0), controlPoint1: CGPoint(x: width-x4, y: 0), controlPoint2: CGPoint(x: x4, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: x2, y: 0), controlPoint2: CGPoint(x: x3, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width, y: height), controlPoint2: CGPoint(x: width, y: height))
        case .both:
            bezierPath.addCurve(to: CGPoint(x: width-x1, y: 0), controlPoint1: CGPoint(x: width-x3, y: height), controlPoint2: CGPoint(x: width-x2, y: 0))
            bezierPath.addCurve(to: CGPoint(x: x1, y: 0), controlPoint1: CGPoint(x: width-x4, y: 0), controlPoint2: CGPoint(x: x4, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: x2, y: 0), controlPoint2: CGPoint(x: x3, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: x5, y: height), controlPoint2: CGPoint(x: width-x5, y: height))
        }
        bezierPath.close()
        bezierPath.miterLimit = 4
        return bezierPath
    }
}
