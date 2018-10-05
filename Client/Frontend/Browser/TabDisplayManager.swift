/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

@objc protocol TabSelectionDelegate: AnyObject {
    func didSelectTabAtIndex(_ index: Int)
}

protocol TopTabCellDelegate: AnyObject {
    func tabCellDidClose(_ cell: UICollectionViewCell)
}

protocol TabDisplayer: AnyObject {
    typealias TabCellIdentifer = String
    var tabCellIdentifer: TabCellIdentifer { get set }

    func focusSelectedTab()
    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell
}

class TabDisplayManager: NSObject {

    fileprivate let tabManager: TabManager
    var isPrivate = false
    var isDragging = false
    fileprivate let collectionView: UICollectionView
    typealias CompletionBlock = () -> Void

    private var tabObservers: TabObservers!
    fileprivate weak var tabDisplayer: TabDisplayer?
    let tabReuseIdentifer: String

    var searchedTabs: [Tab] = []
    var searchActive: Bool = false

    var tabStore: [Tab] = [] //the actual datastore
    fileprivate var pendingUpdatesToTabs: [Tab] = [] //the datastore we are transitioning to
    fileprivate var needReloads: [Tab?] = [] // Tabs that need to be reloaded
    fileprivate var completionBlocks: [CompletionBlock] = [] //blocks are performed once animations finish
    fileprivate var isUpdating = false
    var pendingReloadData = false
    fileprivate var oldTabs: [Tab]? // The last state of the tabs before an animation
    fileprivate weak var oldSelectedTab: Tab? // Used to select the right tab when transitioning between private/normal tabs

    var tabCount: Int {
        return self.tabStore.count
    }

    private var tabsToDisplay: [Tab] {
        if searchActive {
            // tabs can be deleted while a search is active. Make sure the tab still exists in the tabmanager before displaying
            return searchedTabs.filter({ tabManager.tabs.contains($0) })
        }
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }

    init(collectionView: UICollectionView, tabManager: TabManager, tabDisplayer: TabDisplayer, reuseID: String) {
        self.collectionView = collectionView
        self.tabDisplayer = tabDisplayer
        self.tabManager = tabManager
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        self.tabReuseIdentifer = reuseID
        super.init()

        tabManager.addDelegate(self)
        self.tabObservers = registerFor(.didLoadFavicon, .didChangeURL, queue: .main)
        self.tabStore = self.tabsToDisplay
    }

    // Once we are done with TabManager we need to call removeObservers to avoid a retain cycle with the observers
    func removeObservers() {
        unregister(tabObservers)
        tabObservers = nil
    }

     // Make sure animations don't happen before the view is loaded.
    fileprivate func shouldAnimate(isRestoringTabs: Bool) -> Bool {
        return !isRestoringTabs && collectionView.frame != CGRect.zero
    }

    private func recordEventAndBreadcrumb(object: UnifiedTelemetry.EventObject, method: UnifiedTelemetry.EventMethod) {
        let isTabTray = tabDisplayer as? TabTrayController != nil
        let eventValue = isTabTray ? UnifiedTelemetry.EventValue.tabTray : UnifiedTelemetry.EventValue.topTabs
        UnifiedTelemetry.recordEvent(category: .action, method: method, object: object, value: eventValue)
        Sentry.shared.breadcrumb(category: "Tab Action", message: "object: \(object), action: \(method.rawValue), \(eventValue.rawValue), tab count: \(tabStore.count) ")
    }

    func togglePBM() {
        if isUpdating || pendingReloadData {
            return
        }
        let isPrivate = self.isPrivate
        self.pendingReloadData = true // Stops animations from happening
        let oldSelectedTab = self.oldSelectedTab
        self.oldSelectedTab = tabManager.selectedTab

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
}

extension TabDisplayManager: UICollectionViewDataSource {
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabStore.count
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tab = tabStore[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.tabReuseIdentifer, for: indexPath)
        if let tabCell = tabDisplayer?.cellFactory(for: cell, using: tab) {
            return tabCell
        } else {
            return cell
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderFooter", for: indexPath) as! TopTabsHeaderFooter
        view.arrangeLine(kind)
        return view
    }
}

extension TabDisplayManager: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        let tab = tabStore[index]
        if tabsToDisplay.index(of: tab) != nil {
            tabManager.selectTab(tab)
        }
    }
}

@available(iOS 11.0, *)
extension TabDisplayManager: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        // Prevent tabs from being dragged and dropped onto the "New Tab" button.
        if let localDragSession = session.localDragSession, let item = localDragSession.items.first, let _ = item.localObject as? Tab {
            return false
        }

        return session.canLoadObjects(ofClass: URL.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        recordEventAndBreadcrumb(object: .url, method: .drop)

        _ = session.loadObjects(ofClass: URL.self) { urls in
            guard let url = urls.first else {
                return
            }

            self.tabManager.addTab(URLRequest(url: url), isPrivate: self.isPrivate)
        }
    }
}

@available(iOS 11.0, *)
extension TabDisplayManager: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        isDragging = true
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        isDragging = false
        reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore

        let tab = tabStore[indexPath.item]

        // Get the tab's current URL. If it is `nil`, check the `sessionData` since
        // it may be a tab that has not been restored yet.
        var url = tab.url
        if url == nil, let sessionData = tab.sessionData {
            let urls = sessionData.urls
            let index = sessionData.currentPage + urls.count - 1
            if index < urls.count {
                url = urls[index]
            }
        }

        // Ensure we actually have a URL for the tab being dragged and that the URL is not local.
        // If not, just create an empty `NSItemProvider` so we can create a drag item with the
        // `Tab` so that it can at still be re-ordered.
        var itemProvider: NSItemProvider
        if url != nil, !(url?.isLocal ?? true) {
            itemProvider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
        } else {
            itemProvider = NSItemProvider()
        }

        recordEventAndBreadcrumb(object: .tab, method: .drag)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tab
        return [dragItem]
    }
}

@available(iOS 11.0, *)
extension TabDisplayManager: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath, let dragItem = coordinator.items.first?.dragItem, let tab = dragItem.localObject as? Tab, let sourceIndex = tabStore.index(of: tab) else {
            return
        }

        recordEventAndBreadcrumb(object: .tab, method: .drop)

        coordinator.drop(dragItem, toItemAt: destinationIndexPath)
        isDragging = false

        self.tabManager.moveTab(isPrivate: self.isPrivate, fromIndex: sourceIndex, toIndex: destinationIndexPath.item)
        self.performTabUpdates()
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let localDragSession = session.localDragSession, let item = localDragSession.items.first, let tab = item.localObject as? Tab else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        // If the `isDragging` is not `true` by the time we get here, we've had other
        // add/remove operations happen while the drag was going on. We must return a
        // `.cancel` operation continuously until `isDragging` can be reset.
        guard tabStore.index(of: tab) != nil, isDragging else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TabDisplayManager: TabEventHandler {
    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        assertIsMainThread("UICollectionView changes can only be performed from the main thread")

        if tabStore.index(of: tab) != nil {
            needReloads.append(tab)
            performTabUpdates()
        }
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        assertIsMainThread("UICollectionView changes can only be performed from the main thread")

        if tabStore.index(of: tab) != nil {
            needReloads.append(tab)
            performTabUpdates()
        }
    }
}

// Collection Diff (animations)
extension TabDisplayManager {
    struct TopTabMoveChange: Hashable {
        let from: IndexPath
        let to: IndexPath

        var hashValue: Int {
            return from.hashValue + to.hashValue
        }

        // Consider equality when from/to are equal as well as swapped. This is because
        // moving a tab from index 2 to index 1 will result in TWO changes: 2 -> 1 and 1 -> 2
        // We only need to keep *one* of those two changes when dealing with a move.
        static func ==(lhs: TabDisplayManager.TopTabMoveChange, rhs: TabDisplayManager.TopTabMoveChange) -> Bool {
            return (lhs.from == rhs.from && lhs.to == rhs.to) || (lhs.from == rhs.to && lhs.to == rhs.from)
        }
    }

    struct TopTabChangeSet {
        let reloads: Set<IndexPath>
        let inserts: Set<IndexPath>
        let deletes: Set<IndexPath>
        let moves: Set<TopTabMoveChange>

        init(reloadArr: [IndexPath], insertArr: [IndexPath], deleteArr: [IndexPath], moveArr: [TopTabMoveChange]) {
            reloads = Set(reloadArr)
            inserts = Set(insertArr)
            deletes = Set(deleteArr)
            moves = Set(moveArr)
        }

        var isEmpty: Bool {
            return reloads.isEmpty && inserts.isEmpty && deletes.isEmpty && moves.isEmpty
        }
    }

    // create a TopTabChangeSet which is a snapshot of updates to perfrom on a collectionView
    func calculateDiffWith(_ oldTabs: [Tab], to newTabs: [Tab], and reloadTabs: [Tab?]) -> TopTabChangeSet {
        let inserts: [IndexPath] = newTabs.enumerated().compactMap { index, tab in
            if oldTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        let deletes: [IndexPath] = oldTabs.enumerated().compactMap { index, tab in
            if newTabs.index(of: tab) == nil {
                return IndexPath(row: index, section: 0)
            }
            return nil
        }

        let moves: [TopTabMoveChange] = newTabs.enumerated().compactMap { newIndex, tab in
            if let oldIndex = oldTabs.index(of: tab), oldIndex != newIndex {
                return TopTabMoveChange(from: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
            }
            return nil
        }

        // Create based on what is visibile but filter out tabs we are about to insert/delete.
        let reloads: [IndexPath] = reloadTabs.compactMap { tab in
            guard let tab = tab, newTabs.index(of: tab) != nil else {
                return nil
            }
            return IndexPath(row: newTabs.index(of: tab)!, section: 0)
            }.filter { return inserts.index(of: $0) == nil && deletes.index(of: $0) == nil }

        Sentry.shared.breadcrumb(category: "Tab Diff", message: "reloads: \(reloads.count), inserts: \(inserts.count), deletes: \(deletes.count), moves: \(moves.count)")

        return TopTabChangeSet(reloadArr: reloads, insertArr: inserts, deleteArr: deletes, moveArr: moves)
    }

    func updateTabsFrom(_ oldTabs: [Tab]?, to newTabs: [Tab], on completion: (() -> Void)? = nil) {
        assertIsMainThread("Updates can only be performed from the main thread")
        guard let oldTabs = oldTabs, !self.isUpdating, !self.pendingReloadData, !self.isDragging else {
            return
        }

        // Lets create our change set
        let update = self.calculateDiffWith(oldTabs, to: newTabs, and: needReloads)
        flushPendingChanges()

        // If there are no changes. We have nothing to do
        if update.isEmpty {
            completion?()
            return
        }

        // The actual update block. We update the dataStore right before we do the UI updates.
        let updateBlock = {
            self.tabStore = newTabs

            // Only consider moves if no other operations are pending.
            if update.deletes.count == 0, update.inserts.count == 0 {
                for move in update.moves {
                    self.collectionView.moveItem(at: move.from, to: move.to)
                }
            } else {
                self.collectionView.deleteItems(at: Array(update.deletes))
                self.collectionView.insertItems(at: Array(update.inserts))
            }
            self.collectionView.reloadItems(at: Array(update.reloads))
        }

        //Lets lock any other updates from happening.
        self.isUpdating = true
        self.isDragging = false
        self.pendingUpdatesToTabs = newTabs // This var helps other mutations that might happen while updating.

        let onComplete: () -> Void = {
            completion?()
            self.isUpdating = false
            self.pendingUpdatesToTabs = []
            // run completion blocks
            // Sometimes there might be a pending reload. Lets do that.
            if self.pendingReloadData {
                return self.reloadData()
            }

            // There can be pending animations. Run update again to clear them.
            let tabs = self.oldTabs ?? self.tabStore
            self.updateTabsFrom(tabs, to: self.tabsToDisplay, on: {
                if !update.inserts.isEmpty || !update.reloads.isEmpty {
                    self.tabDisplayer?.focusSelectedTab()
                }
            })
        }

        // The actual update. Only animate the changes if no tabs have moved
        // as a result of drag-and-drop.
        if update.moves.count == 0, tabDisplayer is TopTabsViewController {
            UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
                self.collectionView.performBatchUpdates(updateBlock)
            }) { (_) in
                onComplete()
            }
        } else {
            self.collectionView.performBatchUpdates(updateBlock) { _ in
                onComplete()
            }
        }
    }

    fileprivate func flushPendingChanges() {
        oldTabs = nil
        needReloads.removeAll()
    }

    func reloadData(_ completionBlock: CompletionBlock? = nil) {
        assertIsMainThread("reloadData must only be called from main thread")
        if let block = completionBlock {
            completionBlocks.append(block)
        }

        if self.isUpdating || self.collectionView.superview == nil {
            self.pendingReloadData = true
            return
        }

        isUpdating = true
        isDragging = false
        self.tabStore = self.tabsToDisplay
        self.flushPendingChanges()
        UIView.animate(withDuration: TopTabsUX.AnimationSpeed, animations: {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            self.tabDisplayer?.focusSelectedTab()
        }, completion: { (_) in
            self.isUpdating = false
            self.pendingReloadData = false
            self.performTabUpdates()
        })
    }
}

extension TabDisplayManager: TabManagerDelegate {

    // Because we don't know when we are about to transition to private mode
    // check to make sure that the tab we are trying to add is being added to the right tab group
    fileprivate func tabsMatchDisplayGroup(_ a: Tab?, b: Tab?) -> Bool {
        if let a = a, let b = b, a.isPrivate == b.isPrivate {
            return true
        }
        return false
    }

    func performTabUpdates(_ completionBlock: CompletionBlock? = nil) {
        if let block = completionBlock {
            completionBlocks.append(block)
        }
        guard !isUpdating else {
            return
        }

        let fromTabs = !self.pendingUpdatesToTabs.isEmpty ? self.pendingUpdatesToTabs : self.oldTabs
        self.oldTabs = fromTabs ?? self.tabStore
        if self.pendingReloadData && !isUpdating {
            self.reloadData()
        } else {
            self.updateTabsFrom(self.oldTabs, to: self.tabsToDisplay) {
                for block in self.completionBlocks {
                    block()
                }
                self.completionBlocks.removeAll()
            }
        }
    }

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        if !shouldAnimate(isRestoringTabs: isRestoring) {
            return
        }
        if !tabsMatchDisplayGroup(selected, b: previous) {
            self.reloadData()
        } else {
            self.needReloads.append(selected)
            self.needReloads.append(previous)
            performTabUpdates()
        }
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {
        if !shouldAnimate(isRestoringTabs: isRestoring) || (tabManager.selectedTab != nil && !tabsMatchDisplayGroup(tab, b: tabManager.selectedTab)) {
            return
        }
        performTabUpdates()
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
        // We need to store the earliest oldTabs. So if one already exists use that.
        self.oldTabs = self.oldTabs ?? tabStore
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        recordEventAndBreadcrumb(object: .tab, method: .delete)
        if !shouldAnimate(isRestoringTabs: isRestoring) {
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
        recordEventAndBreadcrumb(object: .tab, method: .add)
        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        recordEventAndBreadcrumb(object: .tab, method: .deleteAll)
        self.reloadData()
    }
}
