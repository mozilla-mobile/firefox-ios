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
    static let FaderPading: CGFloat = 10
    static let SeparatorWidth: CGFloat = 1
    static let TabTitleWidth: CGFloat = 110
    static let TabTitlePadding: CGFloat = 10
    static let AnimationSpeed: TimeInterval = 0.1
}

protocol TopTabsDelegate: class {
    func topTabsDidPressTabs()
    func topTabsDidPressNewTab(_ isPrivate: Bool)

    func topTabsDidTogglePrivateMode()
    func topTabsDidChangeTab()
}

protocol TopTabCellDelegate: class {
    func tabCellDidClose(_ cell: TopTabCell)
}

class TopTabsViewController: UIViewController {
    let tabManager: TabManager
    weak var delegate: TopTabsDelegate?
    fileprivate var isPrivate = false
    let faviconNotification = NSNotification.Name(rawValue: FaviconManager.FaviconDidLoad)

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: TopTabsViewLayout())
        collectionView.register(TopTabCell.self, forCellWithReuseIdentifier: TopTabCell.Identifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.clipsToBounds = false
        collectionView.accessibilityIdentifier = "Top Tabs View"
        return collectionView
    }()
    
    fileprivate lazy var tabsButton: TabsButton = {
        let tabsButton = TabsButton.tabTrayButton()
        tabsButton.addTarget(self, action: #selector(TopTabsViewController.tabsTrayTapped), for: UIControlEvents.touchUpInside)
        tabsButton.accessibilityIdentifier = "TopTabsViewController.tabsButton"
        return tabsButton
    }()
    
    fileprivate lazy var newTab: UIButton = {
        let newTab = UIButton.newTabButton()
        newTab.addTarget(self, action: #selector(TopTabsViewController.newTabTapped), for: UIControlEvents.touchUpInside)
        return newTab
    }()
    
    lazy var privateModeButton: PrivateModeButton = {
        let privateModeButton = PrivateModeButton()
        privateModeButton.light = true
        privateModeButton.addTarget(self, action: #selector(TopTabsViewController.togglePrivateModeTapped), for: UIControlEvents.touchUpInside)
        return privateModeButton
    }()
    
    fileprivate lazy var tabLayoutDelegate: TopTabsLayoutDelegate = {
        let delegate = TopTabsLayoutDelegate()
        delegate.tabSelectionDelegate = self
        return delegate
    }()

    fileprivate var tabsToDisplay: [Tab] {
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }

    // Handle animations.
    fileprivate var tabStore: [Tab] = [] //the actual datastore
    fileprivate var pendingUpdatesToTabs: [Tab] = [] //the datastore we are transitioning to
    fileprivate var needReloads: [Tab?] = [] // Tabs that need to be reloaded
    fileprivate var isUpdating = false
    fileprivate var pendingReloadData = false
    fileprivate var oldTabs: [Tab]? // The last state of the tabs before an animation
    fileprivate weak var oldSelectedTab: Tab? // Used to select the right tab when transitioning between private/normal tabs

    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        collectionView.dataSource = self
        collectionView.delegate = tabLayoutDelegate
        NotificationCenter.default.addObserver(self, selector: #selector(TopTabsViewController.reloadFavicons(_:)), name: faviconNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: faviconNotification, object: nil)
        self.tabManager.removeDelegate(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.tabsToDisplay != self.tabStore {
            self.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tabManager.addDelegate(self)
        self.tabStore = self.tabsToDisplay

        let topTabFader = TopTabFader()
        
        view.addSubview(tabsButton)
        view.addSubview(newTab)
        view.addSubview(privateModeButton)
        view.addSubview(topTabFader)
        topTabFader.addSubview(collectionView)
        
        newTab.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        tabsButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.trailing.equalTo(newTab.snp.leading)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        privateModeButton.snp.makeConstraints { make in
            make.centerY.equalTo(view)
            make.leading.equalTo(view)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }
        topTabFader.snp.makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp.trailing).offset(-TopTabsUX.FaderPading)
            make.trailing.equalTo(tabsButton.snp.leading).offset(TopTabsUX.FaderPading)
        }
        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view)
            make.leading.equalTo(privateModeButton.snp.trailing).offset(-TopTabsUX.CollectionViewPadding)
            make.trailing.equalTo(tabsButton.snp.leading).offset(TopTabsUX.CollectionViewPadding)
        }
        
        view.backgroundColor = UIColor.black
        tabsButton.applyTheme(Theme.NormalMode)
        if let currentTab = tabManager.selectedTab {
            applyTheme(currentTab.isPrivate ? Theme.PrivateMode : Theme.NormalMode)
        }
        updateTabCount(tabStore.count)
    }
    
    func switchForegroundStatus(isInForeground reveal: Bool) {
        // Called when the app leaves the foreground to make sure no information is inadvertently revealed
        if let cells = self.collectionView.visibleCells as? [TopTabCell] {
            let alpha: CGFloat = reveal ? 1 : 0
            for cell in cells {
                cell.titleText.alpha = alpha
                cell.favicon.alpha = alpha
            }
        }
    }
    
    func updateTabCount(_ count: Int, animated: Bool = true) {
        self.tabsButton.updateTabCount(count, animated: animated)
    }
    
    func tabsTrayTapped() {
        delegate?.topTabsDidPressTabs()
    }
    
    func newTabTapped() {
        if pendingReloadData {
            return
        }
        self.delegate?.topTabsDidPressNewTab(self.isPrivate)
    }

    func togglePrivateModeTapped() {
        if isUpdating || pendingReloadData {
            return
        }
        let isPrivate = self.isPrivate
        delegate?.topTabsDidTogglePrivateMode()
        self.pendingReloadData = true // Stops animations from happening
        let oldSelectedTab = self.oldSelectedTab
        self.oldSelectedTab = tabManager.selectedTab
        self.privateModeButton.setSelected(!isPrivate, animated: true)

        //if private tabs is empty and we are transitioning to it add a tab
        if tabManager.privateTabs.isEmpty  && !isPrivate {
            tabManager.addTab(isPrivate: true)
        }

        //get the tabs from which we will select which one to nominate for tribute (selection)
        //the isPrivate boolean still hasnt been flipped. (It'll be flipped in the BVC didSelectedTabChange method)
        let tabs = !isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let tab = oldSelectedTab, tabs.index(of: tab) != nil {
            tabManager.selectTab(tab)
        } else {
            tabManager.selectTab(tabs.last)
        }
    }

    func reloadFavicons(_ notification: Notification) {
        // Notifications might be called from a different thread. Make sure animations only happen on the main thread.
        DispatchQueue.main.async {
            if let tab = notification.object as? Tab, self.tabStore.index(of: tab) != nil {
                self.needReloads.append(tab)
                self.performTabUpdates()
            }
        }
    }
    
    func scrollToCurrentTab(_ animated: Bool = true, centerCell: Bool = false) {
        assertIsMainThread("Only animate on the main thread")

        guard let currentTab = tabManager.selectedTab, let index = tabStore.index(of: currentTab), !collectionView.frame.isEmpty else {
            return
        }
        if let frame = collectionView.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.frame {
            if centerCell {
                collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: false)
            } else {
                // Padding is added to ensure the tab is completely visible (none of the tab is under the fader)
                let padFrame = frame.insetBy(dx: -(TopTabsUX.TopTabsBackgroundShadowWidth+TopTabsUX.FaderPading), dy: 0)
                if animated {
                    UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: { 
                        self.collectionView.scrollRectToVisible(padFrame, animated: true)
                    })
                } else {
                    collectionView.scrollRectToVisible(padFrame, animated: false)
                }
            }
        }
    }
}

extension TopTabsViewController: Themeable {
    func applyTheme(_ themeName: String) {
        tabsButton.applyTheme(themeName)
        isPrivate = (themeName == Theme.PrivateMode)
        privateModeButton.styleForMode(privateMode: isPrivate)
        newTab.tintColor = isPrivate ? UIConstants.PrivateModePurple : UIColor.white
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
    func tabCellDidClose(_ cell: TopTabCell) {
        // Trying to remove tabs while animating can lead to crashes as indexes change. If updates are happening don't allow tabs to be removed.
        guard let index = collectionView.indexPath(for: cell)?.item else {
            return
        }
        let tab = tabStore[index]
        if tabsToDisplay.index(of: tab) != nil {
            tabManager.removeTab(tab)
        }
    }
}

extension TopTabsViewController: UICollectionViewDataSource {
    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let tabCell = collectionView.dequeueReusableCell(withReuseIdentifier: TopTabCell.Identifier, for: indexPath) as! TopTabCell
        tabCell.delegate = self
        
        let tab = tabStore[index]
        tabCell.style = tab.isPrivate ? .dark : .light
        tabCell.titleText.text = tab.displayTitle
        
        if tab.displayTitle.isEmpty {
            if tab.webView?.url?.baseDomain?.contains("localhost") ?? true {
                tabCell.titleText.text = AppMenuConfiguration.NewTabTitleString
            } else {
                tabCell.titleText.text = tab.webView?.url?.absoluteDisplayString
            }
            tabCell.accessibilityLabel = tab.url?.aboutComponent ?? ""
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tabCell.titleText.text ?? "")
        } else {
            tabCell.accessibilityLabel = tab.displayTitle
            tabCell.closeButton.accessibilityLabel = String(format: Strings.TopSitesRemoveButtonAccessibilityLabel, tab.displayTitle)
        }

        tabCell.selectedTab = (tab == tabManager.selectedTab)

        if let favIcon = tab.displayFavicon,
           let url = URL(string: favIcon.url) {
            tabCell.favicon.sd_setImage(with: url)
        } else {
            var defaultFavicon = UIImage(named: "defaultFavicon")
            if tab.isPrivate {
                defaultFavicon = defaultFavicon?.withRenderingMode(.alwaysTemplate)
                tabCell.favicon.image = defaultFavicon
                tabCell.favicon.tintColor = UIColor.white
            } else {
                tabCell.favicon.image = defaultFavicon
            }
        }
        
        return tabCell
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabStore.count
    }
}

extension TopTabsViewController: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        let tab = tabStore[index]
        if tabsToDisplay.index(of: tab) != nil {
            tabManager.selectTab(tab)
        }
    }
}

// Collection Diff (animations)
extension TopTabsViewController {

    struct TopTabChangeSet {
        let reloads: Set<IndexPath>
        let inserts: Set<IndexPath>
        let deletes: Set<IndexPath>

        init(reloadArr: [IndexPath], insertArr: [IndexPath], deleteArr: [IndexPath]) {
            reloads = Set(reloadArr)
            inserts = Set(insertArr)
            deletes = Set(deleteArr)
        }

        var all: [Set<IndexPath>] {
            return [inserts, reloads, deletes]
        }

    }

    // create a TopTabChangeSet which is a snapshot of updates to perfrom on a collectionView
    func calculateDiffWith(_ oldTabs: [Tab], to newTabs: [Tab], and reloadTabs: [Tab?]) -> TopTabChangeSet {
        let inserts: [IndexPath] = newTabs.enumerated().flatMap { index, tab in
            if oldTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        let deletes: [IndexPath] = oldTabs.enumerated().flatMap { index, tab in
            if newTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        // Create based on what is visibile but filter out tabs we are about to insert/delete.
        let reloads: [IndexPath] = reloadTabs.flatMap { tab in
            guard let tab = tab, newTabs.index(of: tab) != nil else {
                return nil
            }
            return IndexPath(row: newTabs.index(of: tab)!, section: 0)
            }.filter { return inserts.index(of: $0) == nil && deletes.index(of: $0) == nil }

        return TopTabChangeSet(reloadArr: reloads, insertArr: inserts, deleteArr: deletes)
    }

    func updateTabsFrom(_ oldTabs: [Tab]?, to newTabs: [Tab], on completion: (() -> Void)? = nil) {
        assertIsMainThread("Updates can only be performed from the main thread")
        guard let oldTabs = oldTabs, !self.isUpdating, !self.pendingReloadData else {
            return
        }

        // Lets create our change set
        let update = self.calculateDiffWith(oldTabs, to: newTabs, and: needReloads)
        flushPendingChanges()

        // If there are no changes. We have nothing to do
        if update.all.every({ $0.isEmpty }) {
            completion?()
            return
        }

        // The actual update block. We update the dataStore right before we do the UI updates.
        let updateBlock = {
            self.tabStore = newTabs
            self.collectionView.deleteItems(at: Array(update.deletes))
            self.collectionView.insertItems(at: Array(update.inserts))
            self.collectionView.reloadItems(at: Array(update.reloads))
        }

        //Lets lock any other updates from happening.
        self.isUpdating = true
        self.pendingUpdatesToTabs = newTabs // This var helps other mutations that might happen while updating.

        // The actual update
        UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
            self.collectionView.performBatchUpdates(updateBlock)
        }) { (_) in
            self.isUpdating = false
            self.pendingUpdatesToTabs = []
            // Sometimes there might be a pending reload. Lets do that.
            if self.pendingReloadData {
                return self.reloadData()
            }

            // There can be pending animations. Run update again to clear them.
            let tabs = self.oldTabs ?? self.tabStore
            self.updateTabsFrom(tabs, to: self.tabsToDisplay, on: {
                if !update.inserts.isEmpty || !update.reloads.isEmpty {
                    self.scrollToCurrentTab()
                }
            })
        }
    }

    fileprivate func flushPendingChanges() {
        oldTabs = nil
        needReloads.removeAll()
    }

    fileprivate func reloadData() {
        assertIsMainThread("reloadData must only be called from main thread")

        if self.isUpdating || self.collectionView.frame == CGRect.zero {
            self.pendingReloadData = true
            return
        }

        isUpdating = true
        self.tabStore = self.tabsToDisplay
        self.newTab.isUserInteractionEnabled = false
        self.flushPendingChanges()
        UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.scrollToCurrentTab(true, centerCell: true)
        }, completion: { (_) in
            self.isUpdating = false
            self.pendingReloadData = false
            self.performTabUpdates()
            self.newTab.isUserInteractionEnabled = true
        }) 
    }
}

extension TopTabsViewController: TabManagerDelegate {

    // Because we don't know when we are about to transition to private mode
    // check to make sure that the tab we are trying to add is being added to the right tab group
    fileprivate func tabsMatchDisplayGroup(_ a: Tab?, b: Tab?) -> Bool {
        if let a = a, let b = b, a.isPrivate == b.isPrivate {
            return true
        }
        return false
    }

    func performTabUpdates() {
        guard !isUpdating else {
            return
        }

        let fromTabs = !self.pendingUpdatesToTabs.isEmpty ? self.pendingUpdatesToTabs : self.oldTabs
        self.oldTabs = fromTabs ?? self.tabStore
        if self.pendingReloadData && !isUpdating {
            self.reloadData()
        } else {
            self.updateTabsFrom(self.oldTabs, to: self.tabsToDisplay)
        }
    }

    // This helps make sure animations don't happen before the view is loaded.
    fileprivate var isRestoring: Bool {
        return self.tabManager.isRestoring || self.collectionView.frame == CGRect.zero
    }

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        if isRestoring {
            return
        }
        if !tabsMatchDisplayGroup(selected, b: previous) {
            self.reloadData()
        } else {
            self.needReloads.append(selected)
            self.needReloads.append(previous)
            performTabUpdates()
            delegate?.topTabsDidChangeTab()
        }
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        if isRestoring || (tabManager.selectedTab != nil && !tabsMatchDisplayGroup(tab, b: tabManager.selectedTab)) {
            return
        }
        performTabUpdates()
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        if isRestoring {
            return
        }
        // If we deleted the last private tab. We'll be switching back to normal browsing. Pause updates till then
        if self.tabsToDisplay.isEmpty {
            self.pendingReloadData = true
            return
        }

        // dont want to hold a ref to a deleted tab
        if tab === oldSelectedTab {
            oldSelectedTab = nil
        }

        performTabUpdates()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        self.reloadData()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        self.reloadData()
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        self.reloadData()
    }
}
