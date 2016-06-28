//
//  TopTabCell.swift
//  Client
//
//  Created by Tyler Lacroix on 6/27/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import Foundation

class TopTabCell: UICollectionViewCell {
    enum Style {
        case Light
        case Dark
    }
    
    static let Identifier = "TopTabCellIdentifier"
    
    var style: Style = .Light {
        didSet {
            if style != oldValue {
                applyStyle(style)
            }
        }
    }
    
    var seperatorLine: Bool = false {
        didSet {
            if seperatorLine != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    var selectedTab = false {
        didSet {
            bezierView.hidden = !selectedTab
            if style == Style.Light {
                titleText.textColor = selectedTab ? UIColor.darkTextColor() : UIColor.lightTextColor()
            }
            else {
                titleText.textColor = UIColor.lightTextColor()
            }
            favicon.alpha = selectedTab ? 1.0 : 0.6
        }
    }
    
    let titleText: UILabel = {
        let titleText = UILabel()
        titleText.textAlignment = NSTextAlignment.Left
        titleText.userInteractionEnabled = false
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
        closeButton.setImage(UIImage(named: "topTabs-closeTabs"), forState: UIControlState.Normal)
        closeButton.tintColor = UIColor.lightGrayColor()
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)
        return closeButton
    }()
    
    let bezierView: BezierView = {
        let bezierView = BezierView()
        bezierView.fillColor = TopTabsUX.TopTabsBackgroundNormalColor
        return bezierView
    }()
    
    weak var delegate: TopTabCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        closeButton.addTarget(self, action: #selector(TopTabCell.closeTab), forControlEvents: UIControlEvents.TouchUpInside)
        
        contentView.addSubview(self.bezierView)
        contentView.addSubview(self.closeButton)
        contentView.addSubview(self.titleText)
        contentView.addSubview(self.favicon)
        
        bezierView.snp_makeConstraints { make in
            make.centerY.centerX.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(frame.width+TopTabsUX.TopTabsBackgroundPadding)
        }
        favicon.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
            make.leading.equalTo(self).offset(TopTabsUX.TabTitlePadding)
        }
        titleText.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(TopTabsUX.TabTitleWidth)
            make.leading.equalTo(favicon.snp_trailing).offset(TopTabsUX.TabTitlePadding)
        }
        closeButton.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(self.snp_height)
            make.leading.equalTo(titleText.snp_trailing).offset(-5)
        }
        
        self.clipsToBounds = false
        
        backgroundColor = UIColor.clearColor()
        // Default style is light
        applyStyle(style)
    }
    
    private func applyStyle(style: Style) {
        switch style {
        case Style.Light:
            bezierView.fillColor = TopTabsUX.TopTabsBackgroundNormalColor
            titleText.textColor = UIColor.darkTextColor()
        case Style.Dark:
            bezierView.fillColor = TopTabsUX.TopTabsBackgroundPrivateColor
            titleText.textColor = UIColor.lightTextColor()
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
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        guard seperatorLine else {
            return
        }
        let context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context)
        CGContextSetLineCap(context, CGLineCap.Square)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().colorWithAlphaComponent(0.2).CGColor)
        CGContextSetLineWidth(context, 1.0)
        CGContextMoveToPoint(context, 0, TopTabsUX.BackgroundSeparatorLinePadding)
        CGContextAddLineToPoint(context, 0, frame.size.height-TopTabsUX.BackgroundSeparatorLinePadding)
        CGContextStrokePath(context)
        CGContextRestoreGState(context)
    }
}

class BezierView: UIView {
    var fillColor: UIColor?
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        guard let fillColor = self.fillColor else {
            return
        }
        let bezierPath = TopTabsViewController.TopTabsCurve(frame.width, height: frame.height, direction: .Both)
        
        fillColor.setFill()
        bezierPath.fill()
    }
}

class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(TopTabsUX.TabWidth, collectionView.frame.height)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, TopTabsUX.TopTabsBackgroundShadowWidth, 1, TopTabsUX.TopTabsBackgroundShadowWidth)
    }
    
    @objc func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    @objc func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

class TopTabsViewLayout: UICollectionViewFlowLayout {
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        scrollDirection = UICollectionViewScrollDirection.Horizontal
        registerClass(TopTabsBackgroundDecorationView.self, forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier)
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    // MARK: layoutAttributesForElementsInRect
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes = super.layoutAttributesForElementsInRect(rect)!
        
        // Create decoration attributes
        let decorationAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TopTabsBackgroundDecorationView.Identifier, withIndexPath: NSIndexPath(forRow: 0, inSection: 0))
        
        // Make the decoration view span the entire row
        let size = collectionViewContentSize()
        decorationAttributes.frame = CGRectMake(-(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2)/2, 0, size.width+(TopTabsUX.TopTabsBackgroundPadding-TopTabsUX.TopTabsBackgroundShadowWidth*2), size.height)
        
        // Set the zIndex to be behind the item
        decorationAttributes.zIndex = -1
        
        // Add the attribute to the list
        attributes.append(decorationAttributes)
        
        return attributes
    }
}

class TopTabFader: UIView {
    lazy var hMaskLayer: CAGradientLayer = {
        let innerColor: CGColorRef = UIColor(white: 1.0, alpha: 1.0).CGColor
        let outerColor: CGColorRef = UIColor(white: 1.0, alpha: 0.0).CGColor
        let hMaskLayer = CAGradientLayer()
        hMaskLayer.colors = [outerColor, innerColor, innerColor, outerColor]
        hMaskLayer.locations = [0.00, 0.03, 0.97, 1.0]
        hMaskLayer.startPoint = CGPointMake(0, 0.5)
        hMaskLayer.endPoint = CGPointMake(1.0, 0.5)
        hMaskLayer.anchorPoint = CGPointZero
        return hMaskLayer
    }()
    
    init() {
        super.init(frame: CGRectZero)
        layer.mask = hMaskLayer
    }
    
    internal override func layoutSubviews() {
        super.layoutSubviews()
        hMaskLayer.locations = [0.00, 15/frame.width, 1-15/frame.width, 1.0]
        hMaskLayer.frame = CGRectMake(0, 0, frame.width, frame.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopTabsBackgroundDecorationView : UICollectionReusableView {
    static let Identifier = "TopTabsBackgroundDecorationViewIdentifier"
    private lazy var rightCurve = SingleCurveView(right: true)
    private lazy var leftCurve = SingleCurveView(right: false)
    
    lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        centerBackground.backgroundColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
        return centerBackground
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentMode = .Redraw
        
        self.addSubview(rightCurve)
        self.addSubview(leftCurve)
        self.addSubview(centerBackground)
        
        rightCurve.snp_makeConstraints { make in
            make.right.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        leftCurve.snp_makeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        centerBackground.snp_makeConstraints { make in
            make.left.equalTo(leftCurve.snp_right)
            make.right.equalTo(rightCurve.snp_left)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private class SingleCurveView: UIView {
        static let CurveWidth: CGFloat = 50
        var right: Bool = true
        init(right: Bool) {
            self.right = right
            super.init(frame: CGRectZero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawRect(rect: CGRect) {
            super.drawRect(rect)
            
            let fillColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
            
            let bezierPath = TopTabsViewController.TopTabsCurve(frame.width, height: frame.height, direction: right ? .Right : .Left)
            
            fillColor.setFill()
            bezierPath.fill()
        }
    }
}