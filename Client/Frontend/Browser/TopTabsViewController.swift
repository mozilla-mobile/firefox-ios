/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

struct TopTabsUX {
    static let TopTabsViewHeight: CGFloat = 40
    static let TopTabsBackgroundNormalColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
    static let TopTabsBackgroundPrivateColor = UIColor(red: 90/255, green: 90/255, blue: 90/255, alpha: 1)
    static let TopTabsBackgroundNormalColorInactive = UIColor(red: 53/255, green: 53/255, blue: 53/255, alpha: 1)
    static let TopTabsBackgroundPadding: CGFloat = 35
    static let TopTabsBackgroundShadowWidth: CGFloat = 35
    static let TabWidth: CGFloat = 180
    static let CollectionViewPadding: CGFloat = 15
    static let FaderPading: CGFloat = 5
    static let BackgroundSeparatorLinePadding: CGFloat = 5
    static let TabTitleWidth: CGFloat = 110
    static let TabTitlePadding: CGFloat = 10
}

protocol TopTabsDelegate: class {
    func topTabsPressTabs()
    func topTabsPressNewTab()
    func topTabsPressPrivateTab()
    func topTabsDidChangeTab()
}

protocol TopTabCellDelegate: class {
    func tabCellDidClose(cell: TopTabCell)
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate!
    var isPrivate = false
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: TopTabsViewLayout())
        collectionView.registerClass(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        
        return collectionView
    }()
    
    private lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton()
        tabsButton.titleLabel.text = "0"
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsClicked), forControlEvents: UIControlEvents.TouchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsView.tabsButton"
        tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the tab toolbar")
        return tabsButton
    }()
    
    private lazy var newTab: UIButton = {
        let newTab = UIButton()
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabClicked), forControlEvents: UIControlEvents.TouchUpInside)
        newTab.setImage(UIImage.templateImageNamed("menu-NewTab-pbm"), forState: .Normal)
        newTab.tintColor = UIColor(white: 0.9, alpha: 1)
        newTab.setImage(UIImage(named: "menu-NewTab-pbm"), forState: .Highlighted)
        newTab.accessibilityLabel = NSLocalizedString("New Tab", comment: "Accessibility label for the New Tab button in the tab toolbar.")
        return newTab
    }()
    
    private lazy var privateTab: UIButton = {
        let privateTab = UIButton()
        privateTab.addTarget(self, action: #selector(TopTabsViewController.privateTabClicked), forControlEvents: UIControlEvents.TouchUpInside)
        privateTab.setImage(UIImage.templateImageNamed("menu-NewPrivateTab-pbm"), forState: .Normal)
        privateTab.tintColor = UIColor(white: 0.9, alpha: 1)
        privateTab.setImage(UIImage(named: "menu-NewPrivateTab-pbm"), forState: .Highlighted)
        privateTab.accessibilityLabel = NSLocalizedString("Private Tab", comment: "Accessibility label for the Private Tab button in the tab toolbar.")
        return privateTab
    }()
    
    private lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.tabSelectionDelegate = self
        return delegate
    }()
    
    private var tabsToDisplay: [Tab] {
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }
    
    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopTabsViewController.reloadFavicons), name: FaviconManager.FaviconDidLoad, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FaviconManager.FaviconDidLoad, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        collectionView.dataSource = self
        collectionView.delegate = tabLayoutDelegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let topTabFader = TopTabFader()
        
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateTab)
        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)
        
        newTab.snp_makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        tabsButton.snp_makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(newTab.snp_leading)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        privateTab.snp_makeConstraints { make in
            make.centerY.equalTo(view)
            make.leading.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        topTabFader.snp_makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateTab.snp_trailing).offset(-TopTabsUX.FaderPading)
            make.trailing.equalTo(tabsButton.snp_leading).offset(TopTabsUX.FaderPading)
        }
        collectionView.snp_makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateTab.snp_trailing).offset(-TopTabsUX.CollectionViewPadding)
            make.trailing.equalTo(tabsButton.snp_leading).offset(TopTabsUX.CollectionViewPadding)
        }
        
        view.backgroundColor = UIColor.blackColor()
        updateTabCount(tabsToDisplay.count)
        tabsButton.applyTheme(Theme.NormalMode)
    }
    
    func updateTabCount(count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    func tabsClicked() {
        delegate.topTabsPressTabs()
    }
    
    override func viewDidAppear(animated: Bool) {
        collectionView.reloadData()
        self.scrollToCurrentTab(false)
        super.viewDidAppear(animated)
    }
    
    func newTabClicked() {
        if let currentTab = tabManager.selectedTab, let index = tabsToDisplay.indexOf(currentTab),
            let cell  = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? TopTabCell {
            cell.selectedTab = false
            if index > 0 {
                cell.seperatorLine = true
            }
        }
        delegate.topTabsPressNewTab()
        collectionView.performBatchUpdates({ _ in
            let count = self.collectionView.numberOfItemsInSection(0)
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: count, inSection: 0)])
            }, completion: { finished in
                if finished {
                    self.scrollToCurrentTab()
                }
        })
    }
    
    func privateTabClicked() {
        delegate.topTabsPressPrivateTab()
        self.collectionView.reloadData()
        scrollToCurrentTab(false)
    }
    
    func closeTab() {
        delegate.topTabsPressTabs()
    }
    
    func reloadFavicons() {
        self.collectionView.reloadData()
    }
    
    func scrollToCurrentTab(animated: Bool = true) {
        guard let currentTab = tabManager.selectedTab, let index = tabsToDisplay.indexOf(currentTab) else {
            return
        }
        guard !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0))?.frame {
            // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
            let padFrame = frame.insetBy(dx: -(TopTabsUX.TopTabsBackgroundShadowWidth+TopTabsUX.FaderPading), dy: 0)
            collectionView.scrollRectToVisible(padFrame, animated: true)
        }
    }
    
}

extension TopTabsViewController: Themeable {
    func applyTheme(themeName: String) {
        tabsButton.applyTheme(themeName)
        if themeName == Theme.PrivateMode {
            isPrivate = true
        }
        else if themeName == Theme.NormalMode {
            isPrivate = false
        }
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(cell: TopTabCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        let tab = tabsToDisplay[indexPath.item]
        if tab == tabManager.selectedTab {
            delegate.topTabsDidChangeTab()
        }
        if tabsToDisplay.count == 1 {
            tabManager.removeTab(tab)
            tabManager.selectTab(tabsToDisplay.first)
            collectionView.reloadData()
        }
        else {
            tabManager.removeTab(tab)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
                }, completion: { finished in
                    if #available(iOS 9, *) {
                        self.collectionView.reloadData()
                    }
            })
        }
    }
}

extension TopTabsViewController: UICollectionViewDataSource {
    @objc func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let tabCell = collectionView.dequeueReusableCellWithReuseIdentifier(TopTabCell.Identifier, forIndexPath: indexPath) as! TopTabCell
        tabCell.delegate = self
        
        let tab = tabsToDisplay[index]
        tabCell.style = tab.isPrivate ? .Dark : .Light
        tabCell.titleText.text = tab.displayTitle
        
        if tab.displayTitle.isEmpty {
            if (tab.url?.baseDomain()?.contains("localhost") ?? false || tab.url == nil) {
                tabCell.titleText.text = Strings.TopTabsNewTabTitle
            }
            else {
                tabCell.titleText.text = tab.displayURL?.absoluteString
            }
        }
        
        tabCell.selectedTab = tab == tabManager.selectedTab
        
        if index > 0 && index < tabsToDisplay.count && tabsToDisplay[index] != tabManager.selectedTab && tabsToDisplay[index-1] != tabManager.selectedTab {
            tabCell.seperatorLine = true
        }
        else {
            tabCell.seperatorLine = false
        }
        
        if !tab.displayTitle.isEmpty {
            tabCell.accessibilityLabel = tab.displayTitle
        } else {
            tabCell.accessibilityLabel = AboutUtils.getAboutComponent(tab.url)
        }
        
        if let favIcon = tab.displayFavicon {
            tabCell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
        } else {
            var defaultFavicon = UIImage(named: "defaultFavicon")
            if tab.isPrivate {
                defaultFavicon = defaultFavicon?.imageWithRenderingMode(.AlwaysTemplate)
                tabCell.favicon.image = defaultFavicon
                tabCell.favicon.tintColor = UIColor.whiteColor()
            } else {
                tabCell.favicon.image = defaultFavicon
            }
        }
        
        return tabCell
    }
    
    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabsToDisplay.count
    }
}

extension TopTabsViewController: TabSelectionDelegate {
    func didSelectTabAtIndex(index: Int) {
        let tab = tabsToDisplay[index]
        tabManager.selectTab(tab)
        collectionView.reloadData()
        collectionView.setNeedsDisplay()
        delegate.topTabsDidChangeTab()
        scrollToCurrentTab()
    }
}

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
    
    let titleText: UILabel
    let favicon: UIImageView = UIImageView()
    let closeButton: UIButton
    let bezierView: BezierView = {
        let bezierView = BezierView()
        bezierView.fillColor = TopTabsUX.TopTabsBackgroundNormalColor
        return bezierView
    }()
    
    weak var delegate: TopTabCellDelegate?
    
    override init(frame: CGRect) {
        self.favicon.layer.cornerRadius = 2.0
        self.favicon.layer.masksToBounds = true
        
        self.titleText = UILabel()
        self.titleText.textAlignment = NSTextAlignment.Left
        self.titleText.userInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        
        self.closeButton = UIButton()
        self.closeButton.setImage(UIImage(named: "topTabs-closeTabs"), forState: UIControlState.Normal)
        self.closeButton.tintColor = UIColor.lightGrayColor()
        self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)
        
        super.init(frame: frame)
        
        self.closeButton.addTarget(self, action: #selector(TopTabCell.closeTab), forControlEvents: UIControlEvents.TouchUpInside)
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
        
        let width = frame.width
        let height = frame.height
        let x1: CGFloat = 32.84
        let x2: CGFloat = 5.1
        let x3: CGFloat = 19.76
        let x4: CGFloat = 58.27
        let x5: CGFloat = -12.15
        
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        bezierPath.moveToPoint(CGPoint(x: width, y: height))
        bezierPath.addCurveToPoint(CGPoint(x: width-x1, y: 0), controlPoint1: CGPoint(x: width-x3, y: height), controlPoint2: CGPoint(x: width-x2, y: 0))
        bezierPath.addCurveToPoint(CGPoint(x: x1, y: 0), controlPoint1: CGPoint(x: width-x4, y: 0), controlPoint2: CGPoint(x: x4, y: 0))
        bezierPath.addCurveToPoint(CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: x2, y: 0), controlPoint2: CGPoint(x: x3, y: height))
        bezierPath.addCurveToPoint(CGPoint(x: width, y: height), controlPoint1: CGPoint(x: x5, y: height), controlPoint2: CGPoint(x: width-x5, y: height))
        bezierPath.closePath()
        bezierPath.miterLimit = 4;
        
        fillColor.setFill()
        bezierPath.fill()
    }
}

extension TopTabsViewController : WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        collectionView.reloadData()
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        collectionView.reloadData()
    }
}

private class TopTabsLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    
    override init() {
        super.init()
    }
    
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

private class TopTabsViewLayout: UICollectionViewFlowLayout {
    override func collectionViewContentSize() -> CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItemsInSection(0)) * (TopTabsUX.TabWidth+1)+TopTabsUX.TopTabsBackgroundShadowWidth*2,
                      height: CGRectGetHeight(collectionView!.bounds))
    }
    
    private override func prepareLayout() {
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
    
    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForDecorationViewOfKind(elementKind, atIndexPath: indexPath)
    }
}

private class TopTabFader: UIView {
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
    
    private override func layoutSubviews() {
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
    private lazy var right = SingleCurveView(right: true)
    private lazy var left = SingleCurveView(right: false)
    
    lazy var centerBackground: UIView = {
        let centerBackground = UIView()
        centerBackground.backgroundColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
        return centerBackground
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(right)
        self.addSubview(left)
        self.addSubview(centerBackground)
        
        right.snp_makeConstraints { make in
            make.right.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        left.snp_makeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(SingleCurveView.CurveWidth)
        }
        centerBackground.snp_makeConstraints { make in
            make.left.equalTo(left.snp_right)
            make.right.equalTo(right.snp_left)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        self.setNeedsDisplay()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
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
            
            let width = frame.width
            let height = frame.height
            let x1: CGFloat = 32.84
            let x2: CGFloat = 5.1
            let x3: CGFloat = 19.76
            let x4: CGFloat = 58.27
            let x5: CGFloat = -12.15
            
            //// Bezier Drawing
            let bezierPath = UIBezierPath()
            bezierPath.moveToPoint(CGPoint(x: width, y: height))
            if right {
                bezierPath.addCurveToPoint(CGPoint(x: width-x1, y: 0), controlPoint1: CGPoint(x: width-x3, y: height), controlPoint2: CGPoint(x: width-x2, y: 0))
                bezierPath.addCurveToPoint(CGPoint(x: 0, y: 0), controlPoint1: CGPoint(x: 0, y: 0), controlPoint2: CGPoint(x: 0, y: 0))
                bezierPath.addCurveToPoint(CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 0, y: height), controlPoint2: CGPoint(x: 0, y: height))
                bezierPath.addCurveToPoint(CGPoint(x: width, y: height), controlPoint1: CGPoint(x: x5, y: height), controlPoint2: CGPoint(x: width-x5, y: height))
            }
            else {
                bezierPath.addCurveToPoint(CGPoint(x: width, y: 0), controlPoint1: CGPoint(x: width, y: 0), controlPoint2: CGPoint(x: width, y: 0))
                bezierPath.addCurveToPoint(CGPoint(x: x1, y: 0), controlPoint1: CGPoint(x: width-x4, y: 0), controlPoint2: CGPoint(x: x4, y: 0))
                bezierPath.addCurveToPoint(CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: x2, y: 0), controlPoint2: CGPoint(x: x3, y: height))
                bezierPath.addCurveToPoint(CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width, y: height), controlPoint2: CGPoint(x: width, y: height))
            }
            
            bezierPath.closePath()
            bezierPath.miterLimit = 4;
            
            fillColor.setFill()
            bezierPath.fill()
        }
    }
}