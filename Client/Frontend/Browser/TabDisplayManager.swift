/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

// MARK: Delegate for animation completion notifications.
enum TabAnimationType {
    case addTab
    case removedNonLastTab
    case removedLastTab
    case updateTab
    case moveTab
}

protocol TabDisplayCompletionDelegate: AnyObject {
    func completedAnimation(for: TabAnimationType)
}

// MARK: -

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
    var performingChainedOperations = false

    var dataStore = WeakList<Tab>()
    var operations = [(TabAnimationType, (() -> Void))]()
    weak var tabDisplayCompletionDelegate: TabDisplayCompletionDelegate?

    fileprivate let tabManager: TabManager

    // Instead of using UICollectionView.hasActiveDrag, manage the 'drag is active' flag ourselves in order to cancel the drag. UICollectionView has no drag cancellation support.
    // ANY tab manager operation that arrives should set this to false, effectively cancelling the drag.
    var isDragging = false
    fileprivate let collectionView: UICollectionView

    private var tabObservers: TabObservers!
    fileprivate weak var tabDisplayer: TabDisplayer?
    private let tabReuseIdentifer: String

    var searchedTabs: [Tab]?
    var searchActive: Bool {
        return searchedTabs != nil
    }

    private var tabsToDisplay: [Tab] {
        if let searchedTabs = searchedTabs {
            // tabs can be deleted while a search is active. Make sure the tab still exists in the tabmanager before displaying
            return searchedTabs.filter({ tabManager.tabs.contains($0) })
        }
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }

    private(set) var isPrivate = false

    init(collectionView: UICollectionView, tabManager: TabManager, tabDisplayer: TabDisplayer, reuseID: String) {
        self.collectionView = collectionView
        self.tabDisplayer = tabDisplayer
        self.tabManager = tabManager
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        self.tabReuseIdentifer = reuseID
        super.init()

        tabManager.addDelegate(self)
        self.tabObservers = registerFor(.didLoadFavicon, .didChangeURL, queue: .main)

        tabsToDisplay.forEach {
            self.dataStore.insert($0)
        }
        collectionView.reloadData()
    }

    func togglePrivateMode(isOn: Bool, createTabOnEmptyPrivateMode: Bool) {
        isPrivate = isOn

        searchedTabs = nil
        refreshStore()

        if createTabOnEmptyPrivateMode {
            //if private tabs is empty and we are transitioning to it add a tab
            if tabManager.privateTabs.isEmpty && isPrivate {
                tabManager.addTab(isPrivate: true)
            }
        }
        
        let tab = mostRecentTab(inTabs: tabsToDisplay) ?? tabsToDisplay.last
        if let tab = tab {
            tabManager.selectTab(tab)
        }
    }
    
    func searchTabsAnimated() {
        let isUnchanged = tabsToDisplay.zip(dataStore).reduce(true) { $0 && $1.0 === $1.1 }
        if !tabsToDisplay.isEmpty && isUnchanged {
            return
        }

        operations.removeAll()
        dataStore.removeAll()
        tabsToDisplay.forEach {
            self.dataStore.insert($0)
        }

        // animates the changes
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    func refreshStore(evenIfHidden: Bool = false) {
        operations.removeAll()
        dataStore.removeAll()
        tabsToDisplay.forEach {
            self.dataStore.insert($0)
        }
        collectionView.reloadData()

        if evenIfHidden {
            // reloadData() will reset the data for the collection view,
            // but if called when offscreen it will not render properly,
            // unless reloadItems is explicitly called on each item.
            // Avoid calling with evenIfHidden=true, as it can cause a blink effect as the cell is updated.
            // The cause of the blinking effect is unknown (and unusual).
            var indexPaths = [IndexPath]()
            for i in 0..<collectionView.numberOfItems(inSection: 0) {
                indexPaths.append(IndexPath(item: i, section: 0))
            }
            collectionView.reloadItems(at: indexPaths)
        }

    }

    func close(cell: UICollectionViewCell) {
        guard let index = collectionView.indexPath(for: cell)?.item, let tab = dataStore.at(index) else {
            return
        }
        tabManager.removeTabAndUpdateSelectedIndex(tab)
    }

    // Once we are done with TabManager we need to call removeObservers to avoid a retain cycle with the observers
    func removeObservers() {
        unregister(tabObservers)
        tabObservers = nil
    }

    private func recordEventAndBreadcrumb(object: UnifiedTelemetry.EventObject, method: UnifiedTelemetry.EventMethod) {
        let isTabTray = tabDisplayer as? TabTrayController != nil
        let eventValue = isTabTray ? UnifiedTelemetry.EventValue.tabTray : UnifiedTelemetry.EventValue.topTabs
        UnifiedTelemetry.recordEvent(category: .action, method: method, object: object, value: eventValue)
    }
}

extension TabDisplayManager: UICollectionViewDataSource {
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataStore.count
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tab = dataStore.at(indexPath.row)!
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.tabReuseIdentifer, for: indexPath)
        assert(tabDisplayer != nil)
        if let tabCell = tabDisplayer?.cellFactory(for: cell, using: tab) {
            return tabCell
        } else {
            return cell
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderFooter", for: indexPath) as? TopTabsHeaderFooter else { return UICollectionReusableView() }
        view.arrangeLine(kind)
        return view
    }
}

extension TabDisplayManager: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        guard let tab = dataStore.at(index) else { return }
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
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        guard let tab = dataStore.at(indexPath.item) else { return [] }

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
        guard isDragging, let destinationIndexPath = coordinator.destinationIndexPath, let dragItem = coordinator.items.first?.dragItem, let tab = dragItem.localObject as? Tab, let sourceIndex = dataStore.index(of: tab) else {
            return
        }
        isDragging = false

        recordEventAndBreadcrumb(object: .tab, method: .drop)

        coordinator.drop(dragItem, toItemAt: destinationIndexPath)

        self.tabManager.moveTab(isPrivate: self.isPrivate, fromIndex: sourceIndex, toIndex: destinationIndexPath.item)

        _ = dataStore.remove(tab)
        dataStore.insert(tab, at: destinationIndexPath.item)

        let start = IndexPath(row: sourceIndex, section: 0)
        let end = IndexPath(row: destinationIndexPath.item, section: 0)
        updateWith(animationType: .moveTab) { [weak self] in
            self?.collectionView.moveItem(at: start, to: end)
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let localDragSession = session.localDragSession, let item = localDragSession.items.first, let tab = item.localObject as? Tab else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        // If the `isDragging` is not `true` by the time we get here, we've had other
        // add/remove operations happen while the drag was going on. We must return a
        // `.cancel` operation continuously until `isDragging` can be reset.
        guard dataStore.index(of: tab) != nil, isDragging else {
            return UICollectionViewDropProposal(operation: .cancel)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TabDisplayManager: TabEventHandler {
    private func updateCellFor(tab: Tab) {
        guard let index = dataStore.index(of: tab) else { return }

        updateWith(animationType: .updateTab) { [weak self] in
            self?.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }

    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        updateCellFor(tab: tab)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        updateCellFor(tab: tab)
    }
}

extension TabDisplayManager: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        isDragging = false

        if let selected = selected {
            updateCellFor(tab: selected)
        }
        if let previous = previous {
            updateCellFor(tab: previous)
        }
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
        isDragging = false
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {
        if isRestoring {
            return
        }

        updateWith(animationType: .addTab) { [weak self] in
            if let me = self {
                me.dataStore.insert(tab)
                me.collectionView.insertItems(at: [IndexPath(row: me.dataStore.count - 1, section: 0)])
            }
        }
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
        isDragging = false
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        let type = tabManager.normalTabs.isEmpty ? TabAnimationType.removedLastTab : TabAnimationType.removedNonLastTab

        updateWith(animationType: type) { [weak self] in
            guard let removed = self?.dataStore.remove(tab) else { return }
            self?.collectionView.deleteItems(at: [IndexPath(row: removed, section: 0)])
        }
    }

    private func performChainedOperations() {
        if performingChainedOperations {
            return
        }

        if let (type, operation) = operations.popLast() {
            performingChainedOperations = true
            collectionView.performBatchUpdates({ [weak self] in
                // Baseline animation speed is 1.0, which is too slow, this (odd) code sets it to 3x
                self?.collectionView.forFirstBaselineLayout.layer.speed = 3.0
                operation()
                }, completion: { [weak self] (done) in
                    self?.performingChainedOperations = false
                    self?.tabDisplayCompletionDelegate?.completedAnimation(for: type)
                    self?.performChainedOperations()
            })
        }
    }

    private func updateWith(animationType: TabAnimationType, operation: (() -> Void)?) {
        if let op = operation {
            operations.insert((animationType, op), at: 0)
        }

        performChainedOperations()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        isDragging = false
        refreshStore()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        isDragging = false
        refreshStore()
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        isDragging = false
        refreshStore()
    }
}

