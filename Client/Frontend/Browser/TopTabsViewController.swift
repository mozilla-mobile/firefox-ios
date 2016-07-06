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
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab()
    func topTabsDidPressPrivateTab()
    func topTabsDidChangeTab()
}

protocol TopTabCellDelegate: class {
    func tabCellDidClose(cell: TopTabCell)
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
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
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), forControlEvents: UIControlEvents.TouchUpInside)
        return tabsButton
    }()
    
    private lazy var newTab: UIButton = {
        let newTab = UIButton.newTabButton()
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), forControlEvents: UIControlEvents.TouchUpInside)
        return newTab
    }()
    
    private lazy var privateTab: UIButton = {
        let privateTab = UIButton.privateModeButton()
        privateTab.addTarget(self, action: #selector(TopTabsViewController.togglePrivateModeTapped), forControlEvents: UIControlEvents.TouchUpInside)
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
        self.tabManager.removeDelegate(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.dataSource = self
        collectionView.delegate = tabLayoutDelegate
        collectionView.reloadData()
        self.scrollToCurrentTab(false, centerCell: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabManager.addDelegate(self)
        
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
        tabsButton.applyTheme(Theme.NormalMode)
        if let currentTab = tabManager.selectedTab {
            applyTheme(currentTab.isPrivate ? Theme.PrivateMode : Theme.NormalMode)
        }
        updateTabCount(tabsToDisplay.count)
    }
    
    func updateTabCount(count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    func tabsTrayTapped() {
        delegate?.topTabsDidPressTabs()
    }
    
    func newTabTapped() {
        if let currentTab = tabManager.selectedTab, let index = tabsToDisplay.indexOf(currentTab),
            let cell  = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) as? TopTabCell {
            cell.selectedTab = false
            if index > 0 {
                cell.seperatorLine = true
            }
        }
        delegate?.topTabsDidPressNewTab()
        collectionView.performBatchUpdates({ _ in
            let count = self.collectionView.numberOfItemsInSection(0)
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: count, inSection: 0)])
            }, completion: { finished in
                if finished {
                    self.scrollToCurrentTab()
                }
        })
    }
    
    func togglePrivateModeTapped() {
        delegate?.topTabsDidPressPrivateTab()
        self.collectionView.reloadData()
        self.scrollToCurrentTab(false, centerCell: true)
    }
    
    func closeTab() {
        delegate?.topTabsDidPressTabs()
    }
    
    func reloadFavicons() {
        self.collectionView.reloadData()
    }
    
    func scrollToCurrentTab(animated: Bool = true, centerCell: Bool = false) {
        guard let currentTab = tabManager.selectedTab, let index = tabsToDisplay.indexOf(currentTab) where !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0))?.frame {
            if centerCell {
                collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
            }
            else {
                // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
                let padFrame = frame.insetBy(dx: -(TopTabsUX.TopTabsBackgroundShadowWidth+TopTabsUX.FaderPading), dy: 0)
                collectionView.scrollRectToVisible(padFrame, animated: animated)
            }
        }
    }
}

extension TopTabsViewController: Themeable {
    func applyTheme(themeName: String) {
        tabsButton.applyTheme(themeName)
        isPrivate = (themeName == Theme.PrivateMode)
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(cell: TopTabCell) {
        guard let indexPath = collectionView.indexPathForCell(cell) else {
            return
        }
        let tab = tabsToDisplay[indexPath.item]
        var selectedTab = false
        if tab == tabManager.selectedTab {
            selectedTab = true
            delegate?.topTabsDidChangeTab()
        }
        if tabsToDisplay.count == 1 {
            tabManager.removeTab(tab)
            tabManager.selectTab(tabsToDisplay.first)
            collectionView.reloadData()
        }
        else {
            var nextTab: Tab
            let currentIndex = indexPath.item
            if tabsToDisplay.count-1 > currentIndex {
                nextTab = tabsToDisplay[currentIndex+1]
            }
            else {
                nextTab = tabsToDisplay[currentIndex-1]
            }
            tabManager.removeTab(tab)
            if selectedTab {
                tabManager.selectTab(nextTab)
            }
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
                }, completion: { finished in
                    self.collectionView.reloadData()
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
            if (tab.url?.baseDomain()?.contains("localhost") ?? true) {
                tabCell.titleText.text = AppMenuConfiguration.NewTabTitleString
            }
            else {
                tabCell.titleText.text = tab.displayURL?.absoluteString
            }
            tabCell.accessibilityLabel = AboutUtils.getAboutComponent(tab.url)
        }
        else {
            tabCell.accessibilityLabel = tab.displayTitle
        }

        tabCell.selectedTab = (tab == tabManager.selectedTab)
        
        if index > 0 && index < tabsToDisplay.count && tabsToDisplay[index] != tabManager.selectedTab && tabsToDisplay[index-1] != tabManager.selectedTab {
            tabCell.seperatorLine = true
        }
        else {
            tabCell.seperatorLine = false
        }
        
        if let favIcon = tab.displayFavicon,
           let url = NSURL(string: favIcon.url) {
            tabCell.favicon.sd_setImageWithURL(url)
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
        delegate?.topTabsDidChangeTab()
        scrollToCurrentTab()
    }
}

extension TopTabsViewController : WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        collectionView.reloadData()
    }
}

extension TopTabsViewController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {}
    func tabManager(tabManager: TabManager, didCreateTab tab: Tab) {}
    func tabManager(tabManager: TabManager, didAddTab tab: Tab) {}
    func tabManager(tabManager: TabManager, didRemoveTab tab: Tab) {}
    func tabManagerDidRestoreTabs(tabManager: TabManager) {}
    func tabManagerDidAddTabs(tabManager: TabManager) {
        collectionView.reloadData()
    }
    func tabManagerDidRemoveAllTabs(tabManager: TabManager, toast:ButtonToast?) {}
}