/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

extension UIGestureRecognizer {
    func cancel() {
        if isEnabled {
            isEnabled = false
            isEnabled = true
        }
    }
}

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
    fileprivate let collectionView: UICollectionView
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

    // Sigh. Dragging on the collection view is either an 'active drag' where the item is moved, or
    // that the item has been long pressed on (and not moved yet), and this gesture recognizer has been triggered
    var isDragging: Bool {
        return collectionView.hasActiveDrag || isLongPressGestureStarted
    }

    fileprivate var isLongPressGestureStarted: Bool {
        var started = false
        collectionView.gestureRecognizers?.forEach { recognizer in
            if let _ = recognizer as? UILongPressGestureRecognizer, recognizer.state == .began || recognizer.state == .changed {
                started = true
            }
        }
        return started
    }

    @discardableResult
    fileprivate func cancelDragAndGestures() -> Bool {
        let isActive = collectionView.hasActiveDrag || isLongPressGestureStarted
        collectionView.cancelInteractiveMovement()

        // Long-pressing a cell to initiate dragging, but not actually moving the cell, will not trigger the collectionView's internal 'interactive movement' vars/funcs, and cancelInteractiveMovement() will not work. The gesture recognizer needs to be cancelled in this case.
        collectionView.gestureRecognizers?.forEach { $0.cancel() }

        return isActive
    }

    init(collectionView: UICollectionView, tabManager: TabManager, tabDisplayer: TabDisplayer, reuseID: String) {
        self.collectionView = collectionView
        self.tabDisplayer = tabDisplayer
        self.tabManager = tabManager
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        self.tabReuseIdentifer = reuseID
        super.init()

        tabManager.addDelegate(self)
        register(self, forTabEvents: .didLoadFavicon, .didChangeURL)

        tabsToDisplay.forEach {
            self.dataStore.insert($0)
        }
        collectionView.reloadData()
    }

    func togglePrivateMode(isOn: Bool, createTabOnEmptyPrivateMode: Bool) {
        guard isPrivate != isOn else { return }

        isPrivate = isOn
        UserDefaults.standard.set(isPrivate, forKey: "wasLastSessionPrivate")

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .privateBrowsingButton, extras: ["is-private": isOn.description] )

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

    // The collection is showing this Tab as selected
    func indexOfCellDrawnAsPreviouslySelectedTab(currentlySelected: Tab) -> IndexPath? {
        for i in 0..<collectionView.numberOfItems(inSection: 0) {
            if let cell = collectionView.cellForItem(at: IndexPath(row: i, section: 0)) as? TopTabCell, cell.selectedTab {
                if let tab = dataStore.at(i), tab != currentlySelected {
                    return IndexPath(row: i, section: 0)
                } else {
                    return nil
                }
            }
        }
        return nil
    }
    
    func searchTabsAnimated() {
        let isUnchanged = (tabsToDisplay.count == dataStore.count) && tabsToDisplay.zip(dataStore).reduce(true) { $0 && $1.0 === $1.1 }
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

        tabDisplayer?.focusSelectedTab()
    }

    // The user has tapped the close button or has swiped away the cell
    func closeActionPerformed(forCell cell: UICollectionViewCell) {
        if isDragging {
            return
        }

        guard let index = collectionView.indexPath(for: cell)?.item, let tab = dataStore.at(index) else {
            return
        }
        tabManager.removeTabAndUpdateSelectedIndex(tab)
    }

    private func recordEventAndBreadcrumb(object: TelemetryWrapper.EventObject, method: TelemetryWrapper.EventMethod) {
        let isTabTray = tabDisplayer as? TabTrayControllerV1 != nil
        let eventValue = isTabTray ? TelemetryWrapper.EventValue.tabTray : TelemetryWrapper.EventValue.topTabs
        TelemetryWrapper.recordEvent(category: .action, method: method, object: object, value: eventValue)
    }

    // When using 'Close All', hide all the tabs so they don't animate their deletion individually
    func hideDisplayedTabs( completion: @escaping () -> Void) {
        let cells = collectionView.visibleCells

        UIView.animate(withDuration: 0.2,
                       animations: {
                            cells.forEach {
                                $0.alpha = 0
                            }
                        }, completion: { _ in
                            cells.forEach {
                                $0.alpha = 1
                                $0.isHidden = true
                            }
                            completion()
                        })
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
        if tabsToDisplay.firstIndex(of: tab) != nil {
            tabManager.selectTab(tab)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .tab)
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

extension TabDisplayManager: UICollectionViewDragDelegate {
    // This is called when the user has long-pressed on a cell, please note that `collectionView.hasActiveDrag` is not true
    // until the user's finger moves. This problem is mitigated by checking the collectionView for activated long press gesture recognizers.
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

        // Don't store the URL in the item as dragging a tab near the screen edge will prompt to open Safari with the URL
        let itemProvider = NSItemProvider()

        recordEventAndBreadcrumb(object: .tab, method: .drag)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tab
        return [dragItem]
    }
}

@available(iOS 11.0, *)
extension TabDisplayManager: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard collectionView.hasActiveDrag, let destinationIndexPath = coordinator.destinationIndexPath, let dragItem = coordinator.items.first?.dragItem, let tab = dragItem.localObject as? Tab, let sourceIndex = dataStore.index(of: tab) else {
            return
        }

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
        guard let localDragSession = session.localDragSession, let item = localDragSession.items.first, let _ = item.localObject as? Tab else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TabDisplayManager: TabEventHandler {
    private func updateCellFor(tab: Tab, selectedTabChanged: Bool) {
        let selectedTab = tabManager.selectedTab

        updateWith(animationType: .updateTab) { [weak self] in
            guard let index = self?.dataStore.index(of: tab) else { return }

            var items = [IndexPath]()
            items.append(IndexPath(row: index, section: 0))

            if selectedTabChanged {
                self?.tabDisplayer?.focusSelectedTab()

                // Check if the selected tab has changed. This method avoids relying on the state of the "previous" selected tab,
                // instead it iterates the displayed tabs to see which appears selected.
                // See also `didSelectedTabChange` for more info on why this is a good approach.
                if let selectedTab = selectedTab, let previousSelectedIndex = self?.indexOfCellDrawnAsPreviouslySelectedTab(currentlySelected: selectedTab) {
                    items.append(previousSelectedIndex)
                }
            }

            for item in items {
                if let cell = self?.collectionView.cellForItem(at: item), let tab = self?.dataStore.at(item.row) {
                    let isSelected = (item.row == index && tab == self?.tabManager.selectedTab)
                    if let tabCell = cell as? TabCell {
                        tabCell.configureWith(tab: tab, is: isSelected)
                    } else if let tabCell = cell as? TopTabCell {
                        tabCell.configureWith(tab: tab, isSelected: isSelected)
                    }
                }
            }
        }
    }

    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }
}

extension TabDisplayManager: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        cancelDragAndGestures()

        if let selected = selected {
            // A tab can be re-selected during deletion
            let changed = selected != previous
            updateCellFor(tab: selected, selectedTabChanged: changed)
        }

        // Rather than using 'previous' Tab to deselect, just check if the selected tab is different, and update the required cells.
        // The refreshStore() cancels pending operations are reloads data, so we don't want functions that rely on
        // any assumption of previous state of the view. Passing a previous tab (and relying on that to redraw the previous tab as unselected) would be making this assumption about the state of the view.
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {
        if isRestoring {
            return
        }

        if cancelDragAndGestures() {
            refreshStore()
            return
        }

        if tab.isPrivate != self.isPrivate {
            return
        }

        updateWith(animationType: .addTab) { [weak self] in
            if let me = self, let index = me.tabsToDisplay.firstIndex(of: tab) {
                me.dataStore.insert(tab, at: index)
                me.collectionView.insertItems(at: [IndexPath(row: index, section: 0)])
            }
        }
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        if cancelDragAndGestures() {
            refreshStore()
            return
        }

        let type = tabManager.normalTabs.isEmpty ? TabAnimationType.removedLastTab : TabAnimationType.removedNonLastTab

        updateWith(animationType: type) { [weak self] in
            guard let removed = self?.dataStore.remove(tab) else { return }
            self?.collectionView.deleteItems(at: [IndexPath(row: removed, section: 0)])
        }
    }

    /* Function to take operations off the queue recursively, and perform them (i.e. performBatchUpdates) in sequence.
     If this func is called while it (or performBatchUpdates) is running, it returns immediately.

     The `refreshStore()` function will clear the queue and reload data, and the view will instantly match the tab manager.
     Therefore, don't put operations on the queue that depend on previous operations on the queue. In these cases, just check
     the current state on-demand in the operation (for example, don't assume that a previous tab is selected because that was the previous operation in queue).
     
     For app events where each operation should be animated for the user to see, performedChainedOperations() is the one to use,
     and for bulk updates where it is ok to just redraw the entire view with the latest state, use `refreshStore()`.
     */
    private func performChainedOperations() {
        guard !performingChainedOperations, let (type, operation) = operations.popLast() else {
            return
        }
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

    private func updateWith(animationType: TabAnimationType, operation: (() -> Void)?) {
        if let op = operation {
            operations.insert((animationType, op), at: 0)
        }

        performChainedOperations()
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        cancelDragAndGestures()
        refreshStore()

        // Need scrollToCurrentTab and not focusTab; these exact params needed to focus (without using async dispatch).
        (tabDisplayer as? TopTabsViewController)?.scrollToCurrentTab(false, centerCell: true)
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        cancelDragAndGestures()
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        cancelDragAndGestures()
    }
}
