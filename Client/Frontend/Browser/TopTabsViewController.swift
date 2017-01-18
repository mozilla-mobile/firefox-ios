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
    static let TopTabsBackgroundNormalColorInactive = UIColor(red: 178/255, green: 178/255, blue: 178/255, alpha: 1)
    static let TopTabsBackgroundPrivateColorInactive = UIColor(red: 53/255, green: 53/255, blue: 53/255, alpha: 1)
    static let PrivateModeToolbarTintColor = UIColor(red: 124 / 255, green: 124 / 255, blue: 124 / 255, alpha: 1)
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
    func topTabsDidPressNewTab(isPrivate: Bool)

    func topTabsDidPressPrivateModeButton()
    func topTabsDidChangeTab()
}

protocol TopTabCellDelegate: class {
    func tabCellDidClose(cell: TopTabCell)
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
    private var isPrivate = false

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: TopTabsViewLayout())
        collectionView.registerClass(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        return collectionView
    }()
    
    private lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), forControlEvents: UIControlEvents.TouchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsViewController.tabsButton"
        return tabsButton
    }()
    
    private lazy var newTab: UIButton = {
        let newTab = UIButton.newTabButton()
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), forControlEvents: UIControlEvents.TouchUpInside)
        return newTab
    }()
    
    lazy var privateModeButton: PrivateModeButton = {
        let privateModeButton = PrivateModeButton()
        privateModeButton.light = true
        privateModeButton.addTarget(self, action: #selector(TopTabsViewController.togglePrivateModeTapped), forControlEvents: UIControlEvents.TouchUpInside)
        return privateModeButton
    }()
    
    private lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.tabSelectionDelegate = self
        return delegate
    }()

    private var tabsToDisplay: [Tab] {
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }

    // Used for diffing collection view updates (animations)
    private var isUpdating = false
    private var pendingReloadData = false
    private var _oldTabs: [Tab] = []
    private weak var _oldSelectedTab: Tab?
    private var inserts: [NSIndexPath] = []
    private var pendingUpdates: [tableUpdate] = []


    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopTabsViewController.reloadFavicons(_:)), name: FaviconManager.FaviconDidLoad, object: nil)
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
        self.scrollToCurrentTab(false, centerCell: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabManager.addDelegate(self)

        let topTabFader = TopTabFader()
        
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateModeButton)
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
        privateModeButton.snp_makeConstraints { make in
            make.centerY.equalTo(view)
            make.leading.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        topTabFader.snp_makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp_trailing).offset(-TopTabsUX.FaderPading)
            make.trailing.equalTo(tabsButton.snp_leading).offset(TopTabsUX.FaderPading)
        }
        collectionView.snp_makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp_trailing).offset(-TopTabsUX.CollectionViewPadding)
            make.trailing.equalTo(tabsButton.snp_leading).offset(TopTabsUX.CollectionViewPadding)
        }
        
        view.backgroundColor = UIColor.blackColor()
        tabsButton.applyTheme(Theme.NormalMode)
        if let currentTab = tabManager.selectedTab {
            applyTheme(currentTab.isPrivate ? Theme.PrivateMode : Theme.NormalMode)
        }
        updateTabCount(tabsToDisplay.count)
    }
    
    func switchForegroundStatus(isInForeground reveal: Bool) {
        // Called when the app leaves the foreground to make sure no information is inadvertently revealed
        if let cells = self.collectionView.visibleCells() as? [TopTabCell] {
            let alpha: CGFloat = reveal ? 1 : 0
            for cell in cells {
                cell.titleText.alpha = alpha
                cell.favicon.alpha = alpha
            }
        }
    }
    
    func updateTabCount(count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    func tabsTrayTapped() {
        delegate?.topTabsDidPressTabs()
    }
    
    func newTabTapped() {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.topTabsDidPressNewTab(self.isPrivate)
        }
    }

    func togglePrivateModeTapped() {
        if isUpdating || pendingReloadData {
            return
        }
        delegate?.topTabsDidPressPrivateModeButton()
        self.pendingReloadData = true
        let oldSelectedTab = self._oldSelectedTab
        self._oldSelectedTab = tabManager.selectedTab
        self.privateModeButton.setSelected(isPrivate, animated: true)

        //if private tabs is empty and we are transitioning to it add a tab
        if tabManager.privateTabs.isEmpty  && !isPrivate {
            tabManager.addTab(isPrivate: true)
        }

        //get the tabs from which we will select which one to nominate for tribute (selection)
        //the isPrivate boolean still hasnt been flipped. (It'll be flipped in the BVC didSelectedTabChange method)
        let tabs = !isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let tab = oldSelectedTab where tabs.indexOf(tab) != nil {
            tabManager.selectTab(tab)
        } else {
            tabManager.selectTab(tabs.last)
        }
    }

    func reloadFavicons(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()) {
            if let tab = notification.object as? Tab {
                self.updateTabsFrom(self.tabsToDisplay, to: self.tabsToDisplay, reloadTabs: [tab])
            }
        }
    }
    
    func scrollToCurrentTab(animated: Bool = true, centerCell: Bool = false) {
        assertIsMainThread("Only animate on the main thread")

        guard let currentTab = tabManager.selectedTab, let index = tabsToDisplay.indexOf(currentTab) where !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0))?.frame {
            if centerCell {
                collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
            } else {
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
        privateModeButton.styleForMode(privateMode: isPrivate)
        newTab.tintColor = isPrivate ? UIConstants.PrivateModePurple : UIColor.whiteColor()
        if let layout = collectionView.collectionViewLayout as? TopTabsViewLayout {
            if isPrivate {
                layout.themeColor = TopTabsUX.TopTabsBackgroundPrivateColorInactive
            } else {
                layout.themeColor = TopTabsUX.TopTabsBackgroundNormalColorInactive
            }
        }
    }
}

extension TopTabsViewController: TopTabCellDelegate {
    func tabCellDidClose(cell: TopTabCell) {
        guard let index = collectionView.indexPathForCell(cell)?.item else {
            return
        }
        let tab = tabsToDisplay[index]
        tabManager.removeTab(tab)
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
            if (tab.webView?.URL?.baseDomain?.contains("localhost") ?? true) {
                tabCell.titleText.text = AppMenuConfiguration.NewTabTitleString
            } else {
                tabCell.titleText.text = tab.webView?.URL?.absoluteDisplayString
            }
            tabCell.accessibilityLabel = tab.url?.aboutComponent ?? ""
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tabCell.titleText.text ?? "")
        } else {
            tabCell.accessibilityLabel = tab.displayTitle
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tab.displayTitle)
        }

        tabCell.selectedTab = (tab == tabManager.selectedTab)

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
    }
}

// Collection Diff (animations)
extension TopTabsViewController {

    struct tableUpdate {
        let reloads: Set<NSIndexPath>
        let inserts: Set<NSIndexPath>
        let deletes: Set<NSIndexPath>

        init(updates: [tableUpdate]) {
            reloads = Set(updates.flatMap { $0.reloads })
            inserts = Set(updates.flatMap { $0.inserts })
            deletes = Set(updates.flatMap { $0.deletes })
        }

        init(reloadArr: [NSIndexPath], insertArr: [NSIndexPath], deleteArr: [NSIndexPath]) {
            reloads = Set(reloadArr)
            inserts = Set(insertArr)
            deletes = Set(deleteArr)
        }

        func isEmpty() -> Bool {
            return inserts.isEmpty && reloads.isEmpty && deletes.isEmpty
        }
    }

    // create a tableUpdate which is a snapshot of updates to perfrom on a collectionView
    func calculateDiffWith(oldTabs: [Tab], to newTabs: [Tab], and reloadTabs: [Tab?]) -> tableUpdate {
        let reloads: [NSIndexPath] = reloadTabs.flatMap { tab in
            guard let tab = tab where newTabs.indexOf(tab) != nil else {
                return nil
            }
            return NSIndexPath(forRow: newTabs.indexOf(tab)!, inSection: 0)
        }

        let inserts: [NSIndexPath] = newTabs.enumerate().flatMap { index, tab in
            if oldTabs.indexOf(tab) == nil {
                return NSIndexPath(forRow: index, inSection: 0)
            }
            return nil
        }

        let deletes: [NSIndexPath] = oldTabs.enumerate().flatMap { index, tab in
            if newTabs.indexOf(tab) == nil {
                return NSIndexPath(forRow: index, inSection: 0)
            }
            return nil
        }
        return tableUpdate(reloadArr: reloads, insertArr: inserts, deleteArr: deletes)
    }

    func updateTabsFrom(oldTabs: [Tab], to newTabs: [Tab], reloadTabs: [Tab?]) {
        assertIsMainThread("Updates can only be performed from the main thread")

        self.pendingUpdates.append(self.calculateDiffWith(oldTabs, to: newTabs, and: reloadTabs))
        if self.isUpdating || self.pendingReloadData {
            return
        }

        self.isUpdating = true
        let updates = self.pendingUpdates
        self.flushPendingChanges()
        let update = tableUpdate(updates: updates)

        performUpdateWithChanges(update) { (_) in
            // This handles the edge case where, during the animation we've toggled private mode
            // Because we dont have a proper way of knowing when this transition is about to happen we have to do this check here
            print("number of items in datastore AFTER UPDATE \(self.tabsToDisplay.count)")
            if  !self.tabsMatchDisplayGroup(newTabs.first, b: self.tabsToDisplay.first) || self.pendingReloadData {
                self.reloadData()
            } else if self.pendingUpdates.isEmpty && !self.isUpdating && !update.inserts.isEmpty {
                self.scrollToCurrentTab()
            }
        }
    }

    func performUpdateWithChanges(update: tableUpdate, completion: (Bool)-> Void) {
        //Speed up the animation a bit to make it feel snappier
        let newUpdates = update.reloads.filter { self.tabsToDisplay.count  > $0.row }
        UIView.animateWithDuration(0.1) {
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItemsAtIndexPaths(Array(update.deletes))
                self.collectionView.reloadItemsAtIndexPaths(Array(newUpdates))
                self.collectionView.insertItemsAtIndexPaths(Array(update.inserts))
                self.isUpdating = false
                }, completion: completion)
        }
    }

    private func flushPendingChanges() {
        _oldTabs.removeAll()
        pendingUpdates.removeAll()
    }

    private func reloadData() {
        assertIsMainThread("reloadData must only be called from main thread")

        if self.isUpdating {
            self.pendingReloadData = true
            return
        }

        isUpdating = true
        self.newTab.userInteractionEnabled = false
        UIView.animateWithDuration(0.2, animations: {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.scrollToCurrentTab(true, centerCell: true)
        }) { (_) in
            self.flushPendingChanges()
            self.isUpdating = false
            self.pendingReloadData = false
            self.newTab.userInteractionEnabled = true
        }
    }
}

extension TopTabsViewController: TabManagerDelegate {

    // Because we don't know when we are about to transition to private mode
    // check to make sure that the tab we are trying to add is being added to the right tab group
    private func tabsMatchDisplayGroup(a: Tab?, b: Tab?) -> Bool {
        if let a = a, let b = b where a.isPrivate == b.isPrivate {
            return true
        }
        return false
    }

    // This helps make sure animations don't happen before the view is loaded.
    private var isRestoring: Bool {
        return self.tabManager.isRestoring || self.collectionView.frame == CGRect.zero
    }

    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        if isRestoring {
            return
        }

        if !tabsMatchDisplayGroup(selected, b: previous) {
            self.reloadData()
        } else {
            print("about to update \(#function)")
            self.updateTabsFrom(self.tabsToDisplay, to: self.tabsToDisplay, reloadTabs: [selected, previous])
            delegate?.topTabsDidChangeTab()
        }
    }

    func tabManager(tabManager: TabManager, willAddTab tab: Tab) {
        self._oldTabs = tabsToDisplay
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Tab) {
        if isRestoring || (tabManager.selectedTab != nil && !tabsMatchDisplayGroup(tab, b: tabManager.selectedTab)) {
            return
        }

        let oldTabs = _oldTabs
        _oldTabs = []

        print("about to update \(#function)")
        self.updateTabsFrom(oldTabs, to: self.tabsToDisplay, reloadTabs: [self.tabManager.selectedTab])
    }

    func tabManager(tabManager: TabManager, willRemoveTab tab: Tab) {
        self._oldTabs = tabsToDisplay
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Tab) {
        if isRestoring {
            return
        }
        let oldTabs = _oldTabs
        if tab === _oldSelectedTab {
            _oldSelectedTab = nil
        }
        _oldTabs = []
        self.updateTabsFrom(oldTabs, to: self.tabsToDisplay, reloadTabs: [])
    }

    func tabManagerDidRestoreTabs(tabManager: TabManager) {
        self.collectionView.reloadData()
    }

    func tabManagerDidAddTabs(tabManager: TabManager) {}
    func tabManagerDidRemoveAllTabs(tabManager: TabManager, toast: ButtonToast?) {}
}
