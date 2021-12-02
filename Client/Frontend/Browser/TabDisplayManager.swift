// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
    func displayRecentlyClosedTabs()
}

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

enum TabDisplaySection: Int, CaseIterable {
    case groupedTabs
    case regularTabs
    case inactiveTabs

    var title: String? {
        switch self {
        case .regularTabs: return .ASPocketTitle2
        case .inactiveTabs: return .RecentlySavedSectionTitle
        default: return nil
        }
    }

    var image: UIImage? {
        switch self {
        case .regularTabs: return UIImage.templateImageNamed("menu-pocket")
        case .inactiveTabs: return UIImage.templateImageNamed("menu-pocket")
        default: return nil
        }
    }
}

enum TabDisplayType {
    case TabGrid
    case TopTabTray
}

// Regular tab order persistence for TabDisplayManager
struct TabDisplayOrder: Codable {
    static let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
    var regularTabUUID: [String] = []
}

class TabDisplayManager: NSObject, FeatureFlagsProtocol {

    // MARK: - Variables
    var performingChainedOperations = false
    var inactiveViewModel: InactiveTabViewModel?
    var isInactiveViewExpanded: Bool = false
    var dataStore = WeakList<Tab>()
    var operations = [(TabAnimationType, (() -> Void))]()
    weak var tabDisplayCompletionDelegate: TabDisplayCompletionDelegate?
    var tabDisplayType: TabDisplayType = .TabGrid
    fileprivate let tabManager: TabManager
    fileprivate let collectionView: UICollectionView
    fileprivate weak var tabDisplayer: TabDisplayer?
    private let tabReuseIdentifer: String
    var profile: Profile
    private var inactiveNimbusExperimentStatus: Bool = false

    lazy var filteredTabs = [Tab]()
    var tabDisplayOrder: TabDisplayOrder = TabDisplayOrder()

    var shouldEnableGroupedTabs: Bool {
        guard featureFlags.isFeatureActiveForBuild(.groupedTabs),
              featureFlags.userPreferenceFor(.groupedTabs) == UserFeaturePreference.enabled
        else { return false }
        return true
    }

    var shouldEnableInactiveTabs: Bool {
        guard featureFlags.isFeatureActiveForBuild(.inactiveTabs) else { return false }

        return inactiveNimbusExperimentStatus ? inactiveNimbusExperimentStatus : profile.prefs.boolForKey(PrefsKeys.KeyEnableInactiveTabs) ?? false
    }

    var orderedTabs: [Tab] {
        return filteredTabs
    }

    func getRegularOrderedTabs() -> [Tab]? {
        // Get current order
        guard let tabDisplayOrderDecoded = TabDisplayOrder.decode() else { return nil }
        var decodedTabUUID = tabDisplayOrderDecoded.regularTabUUID
        guard decodedTabUUID.count > 0 else { return nil }
        let filteredTabCopy: [Tab] = filteredTabs.map { $0 }
        var filteredTabUUIDs: [String] = filteredTabs.map { $0.tabUUID }
        var regularOrderedTabs: [Tab] = []

        // Remove any stale uuid from tab display order
        decodedTabUUID = decodedTabUUID.filter({ uuid in
            let shouldAdd = filteredTabUUIDs.contains(uuid)
            filteredTabUUIDs.removeAll{ $0 == uuid }
            return shouldAdd
        })

        // Add missing uuid to tab display order from filtered tab
        decodedTabUUID.append(contentsOf: filteredTabUUIDs)

        // Get list of tabs corresponding to the uuids from tab display order
        decodedTabUUID.forEach { tabUUID in
            if let tabIndex = filteredTabCopy.firstIndex (where: { t in
                t.tabUUID == tabUUID
            }) {
                regularOrderedTabs.append(filteredTabCopy[tabIndex])
            }
        }

        return regularOrderedTabs.count > 0 ? regularOrderedTabs : nil
    }

    func saveRegularOrderedTabs(from tabs: [Tab]) {
        let uuids: [String] = tabs.map{ $0.tabUUID }
        tabDisplayOrder.regularTabUUID = uuids
        TabDisplayOrder.encode(tabDisplayOrder: tabDisplayOrder)
    }
    
    var tabGroups: [ASGroup<Tab>]?
    var tabsInAllGroups: [Tab]? {
        (tabGroups?.map{$0.groupedItems}.flatMap{$0})
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

    init(collectionView: UICollectionView, tabManager: TabManager, tabDisplayer: TabDisplayer, reuseID: String, tabDisplayType: TabDisplayType, profile: Profile) {
        self.collectionView = collectionView
        self.tabDisplayer = tabDisplayer
        self.tabManager = tabManager
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        self.tabReuseIdentifer = reuseID
        self.tabDisplayType = tabDisplayType
        self.profile = profile
        super.init()
        self.setupExperiment()
        self.inactiveViewModel = InactiveTabViewModel()
        tabManager.addDelegate(self)
        register(self, forTabEvents: .didLoadFavicon, .didChangeURL, .didSetScreenshot)
        self.dataStore.removeAll()
        getTabsAndUpdateInactiveState { tabGroup, tabsToDisplay in
            guard tabsToDisplay.count > 0 else { return }
            let orderedRegularTabs = tabDisplayType == .TopTabTray ? tabsToDisplay : self.getRegularOrderedTabs() ?? tabsToDisplay
            if self.getRegularOrderedTabs() == nil {
                self.saveRegularOrderedTabs(from: tabsToDisplay)
            }
            orderedRegularTabs.forEach {
                self.dataStore.insert($0)
            }
            self.recordGroupedTabTelemetry()
            self.collectionView.reloadData()
        }
    }

    func setupExperiment() {
        inactiveNimbusExperimentStatus = Experiments.shared.withExperiment(featureId: .inactiveTabs) { branch -> Bool in
                switch branch {
                case .some(NimbusExperimentBranch.InactiveTab.control): return false
                case .some(NimbusExperimentBranch.InactiveTab.treatment): return true
                default: return false
            }
        }
    }

    private func getTabsAndUpdateInactiveState(completion: @escaping ([ASGroup<Tab>]?, [Tab]) -> Void) {
        let allTabs = self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard !self.isPrivate else {
            self.tabGroups = nil
            self.filteredTabs = allTabs
            completion(nil, allTabs)
            return
        }
        guard tabDisplayType == .TabGrid else {
            self.filteredTabs = allTabs
            completion(nil, allTabs)
            return
        }
        guard shouldEnableInactiveTabs else {
            if !self.isPrivate && shouldEnableGroupedTabs {
                SearchTermGroupsManager.getTabGroups(with: profile,
                                              from: tabManager.normalTabs,
                                              using: .orderedAscending) { tabGroups, filteredActiveTabs  in
                    self.tabGroups = tabGroups
                    self.filteredTabs = filteredActiveTabs
                    completion(tabGroups, filteredActiveTabs)
                }
                return
            }
            self.tabGroups = nil
            self.filteredTabs = allTabs
            completion(nil, allTabs)
            return
        }
        guard allTabs.count > 0, let inactiveViewModel = inactiveViewModel else {
            self.tabGroups = nil
            self.filteredTabs = [Tab]()
            completion(nil, [Tab]())
            return
        }
        guard allTabs.count > 1 else {
            self.tabGroups = nil
            self.filteredTabs = allTabs
            completion(nil, allTabs)
            return
        }
        let selectedTab = tabManager.selectedTab
        // Make sure selected tab has latest time
        selectedTab?.lastExecutedTime = Date.now()
        inactiveViewModel.updateInactiveTabs(with: tabManager.selectedTab, tabs: allTabs)
        SearchTermGroupsManager.getTabGroups(with: profile,
                                      from: tabManager.normalTabs,
                                      using: .orderedAscending) { tabGroups, filteredActiveTabs  in
            guard self.shouldEnableGroupedTabs else {
                self.tabGroups = nil
                self.filteredTabs = allTabs
                completion(tabGroups, allTabs)
                return
            }

            self.tabGroups = tabGroups
            self.filteredTabs = filteredActiveTabs
            completion(tabGroups, filteredActiveTabs)
        }
        self.isInactiveViewExpanded = inactiveViewModel.inactiveTabs.count > 0
        let recentlyClosedTabs = inactiveViewModel.recentlyClosedTabs
        if recentlyClosedTabs.count > 0 {
            self.tabManager.removeTabs(recentlyClosedTabs)
            self.tabManager.selectTab(selectedTab)
        }
    }

    private func groupNameForTab(tab: Tab) -> String? {
        guard let groupName = tabGroups?.first(where: { $0.groupedItems.contains(tab) })?.searchTerm else { return nil }
        return groupName
    }

    func indexOfGroupTab(tab: Tab) -> (groupName: String, indexOfTabInGroup: Int)? {
        guard let searchTerm = groupNameForTab(tab: tab),
              let group = tabGroups?.first(where: { $0.searchTerm == searchTerm }),
              let indexOfTabInGroup = group.groupedItems.firstIndex(of: tab) else { return nil }
        return (searchTerm, indexOfTabInGroup)
    }

    func indexOfRegularTab(tab: Tab) -> Int? {
        return filteredTabs.firstIndex(of: tab)
    }

    func togglePrivateMode(isOn: Bool, createTabOnEmptyPrivateMode: Bool) {
        guard isPrivate != isOn else { return }

        isPrivate = isOn
        UserDefaults.standard.set(isPrivate, forKey: "wasLastSessionPrivate")

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .privateBrowsingButton, extras: ["is-private": isOn.description] )

        refreshStore()

        if createTabOnEmptyPrivateMode {
            //if private tabs is empty and we are transitioning to it add a tab
            if tabManager.privateTabs.isEmpty && isPrivate {
                tabManager.addTab(isPrivate: true)
            }
        }
        getTabsAndUpdateInactiveState { tabGroup, tabsToDisplay in
            let tab = mostRecentTab(inTabs: tabsToDisplay) ?? tabsToDisplay.last
            if let tab = tab {
                self.tabManager.selectTab(tab)
            }
        }
    }

    /// Find the previously selected cell, which is still displayed as selected
    /// - Parameters:
    ///   - currentlySelected: The currently selected tab
    ///   - inSection: In which section should this tab be searched
    /// - Returns: The index path of the found previously selected tab
    private func indexOfCellDrawnAsPreviouslySelectedTab(currentlySelected: Tab?, inSection: Int) -> IndexPath? {
        guard let currentlySelected = currentlySelected else { return nil }

        for index in 0..<collectionView.numberOfItems(inSection: inSection) {
            guard let cell = collectionView.cellForItem(at: IndexPath(row: index, section: inSection)) as? TabTrayCell,
                  cell.isSelectedTab,
                  let tab = dataStore.at(index),
                  tab != currentlySelected
            else {
                continue
            }

            return IndexPath(row: index, section: inSection)
        }

        return nil
    }

    func refreshStore(evenIfHidden: Bool = false) {
        operations.removeAll()
        dataStore.removeAll()

        getTabsAndUpdateInactiveState { tabGroup, tabsToDisplay in
            tabsToDisplay.forEach {
                self.dataStore.insert($0)
            }
            self.collectionView.reloadData()
            if evenIfHidden {
                // reloadData() will reset the data for the collection view,
                // but if called when offscreen it will not render properly,
                // unless reloadItems is explicitly called on each item.
                // Avoid calling with evenIfHidden=true, as it can cause a blink effect as the cell is updated.
                // The cause of the blinking effect is unknown (and unusual).
                var indexPaths = [IndexPath]()
                for i in 0..<self.collectionView.numberOfItems(inSection: 0) {
                    indexPaths.append(IndexPath(item: i, section: 0))
                }
                self.collectionView.reloadItems(at: indexPaths)
            }
            self.tabDisplayer?.focusSelectedTab()
        }
    }
    
    func removeGroupTab(with tab:Tab) {
        let groupData = indexOfGroupTab(tab: tab)
        let groupIndexPath = IndexPath(row: 0, section: TabDisplaySection.groupedTabs.rawValue)
        guard let groupName = groupData?.groupName,
              let tabIndexInGroup = groupData?.indexOfTabInGroup,
              let indexOfGroup = tabGroups?.firstIndex(where: { group in
                  group.searchTerm == groupName
              }),
              let groupedCell = self.collectionView.cellForItem(at: groupIndexPath) as? GroupedTabCell else {
            return
        }
        
        // case: Group has less than 3 tabs (refresh all)
        if let count = tabGroups?[indexOfGroup].groupedItems.count, count < 3 {
            refreshStore()
        } else {
            // case: Group has more than 2 tabs, we are good to remove just one tab from group
            tabGroups?[indexOfGroup].groupedItems.remove(at: tabIndexInGroup)
                groupedCell.tabDisplayManagerDelegate = self
                groupedCell.tabGroups = self.tabGroups
                groupedCell.hasExpanded = true
                groupedCell.selectedTab = tabManager.selectedTab
                groupedCell.tableView.reloadRows(at: [IndexPath(row: indexOfGroup, section: 0)], with: .automatic)
                groupedCell.scrollToSelectedGroup()
        }
    }

    // The user has tapped the close button or has swiped away the cell
    func closeActionPerformed(forCell cell: UICollectionViewCell) {
        if isDragging {
            return
        }

        guard let index = collectionView.indexPath(for: cell)?.item, let tab = dataStore.at(index) else {
            return
        }

        getTabsAndUpdateInactiveState { tabGroup, tabsToDisplay in
            if self.isPrivate == false, tabsToDisplay.count + (self.tabsInAllGroups?.count ?? 0) == 1 {
                self.tabManager.removeTabs([tab])
                self.tabManager.selectTab(self.tabManager.addTab())
                return
            }

            self.tabManager.removeTab(tab)
        }
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

    private func recordEventAndBreadcrumb(object: TelemetryWrapper.EventObject, method: TelemetryWrapper.EventMethod) {
        let isTabTray = tabDisplayer as? GridTabViewController != nil
        let eventValue = isTabTray ? TelemetryWrapper.EventValue.tabTray : TelemetryWrapper.EventValue.topTabs
        TelemetryWrapper.recordEvent(category: .action, method: method, object: object, value: eventValue)
    }

    func recordGroupedTabTelemetry() {
        if shouldEnableGroupedTabs, !isPrivate, let tabGroups = tabGroups, tabGroups.count > 0 {
            let groupWithTwoTabs = tabGroups.filter { $0.groupedItems.count == 2 }.count
            let groupsWithTwoMoreTab = tabGroups.filter { $0.groupedItems.count > 2 }.count
            let tabsInAllGroup = tabsInAllGroups?.count ?? 0
            let averageTabsInAllGroups = ceil(Double(tabsInAllGroup / tabGroups.count))
            let groupTabExtras: [String: Int32] = [
                "\(TelemetryWrapper.EventExtraKey.groupsWithTwoTabsOnly)": Int32(groupWithTwoTabs),
                "\(TelemetryWrapper.EventExtraKey.groupsWithTwoMoreTab)": Int32(groupsWithTwoMoreTab),
                "\(TelemetryWrapper.EventExtraKey.totalNumberOfGroups)": Int32(tabGroups.count),
                "\(TelemetryWrapper.EventExtraKey.averageTabsInAllGroups)": Int32(averageTabsInAllGroups),
                "\(TelemetryWrapper.EventExtraKey.totalTabsInAllGroups)": Int32(tabsInAllGroup),
            ]
            TelemetryWrapper.recordEvent(category: .action, method: .view, object: .tabTray, value: .tabGroupWithExtras, extras: groupTabExtras)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension TabDisplayManager: UICollectionViewDataSource {
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tabDisplayType == .TopTabTray {
            return dataStore.count + (tabGroups?.count ?? 0)
        }
        switch TabDisplaySection(rawValue: section) {
        case .groupedTabs:
            return shouldEnableGroupedTabs ? (isPrivate ? 0 : 1) : 0
        case .regularTabs:
            return dataStore.count
        case .inactiveTabs:
            return shouldEnableInactiveTabs ? (isPrivate ? 0 : 1) : 0
        case .none:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let _ = tabGroups {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GridTabViewController.independentTabsHeaderIdentifier, for: indexPath) as! ASHeaderView
            view.remakeConstraint(type: .otherGroupTabs)
            view.title = .TabTrayOtherTabsSectionHeader
            view.titleLabel.font = .systemFont(ofSize: GroupedTabCellProperties.CellUX.titleFontSize, weight: .semibold)
            view.moreButton.isHidden = true
            view.titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.filteredTabs
            
            return view
        }
        return UICollectionReusableView()
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.tabReuseIdentifer, for: indexPath)
        if tabDisplayType == .TopTabTray {
            guard let tab = dataStore.at(indexPath.row) else { return cell }
            cell = tabDisplayer?.cellFactory(for: cell, using: tab) ?? cell
            return cell
        }
        assert(tabDisplayer != nil)
        switch TabDisplaySection(rawValue: indexPath.section) {
        case .groupedTabs:
            if let groupedCell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupedTabCell.Identifier, for: indexPath) as? GroupedTabCell {
                groupedCell.tabDisplayManagerDelegate = self
                groupedCell.tabGroups = self.tabGroups
                groupedCell.hasExpanded = true
                groupedCell.selectedTab = tabManager.selectedTab
                groupedCell.tableView.reloadData()
                groupedCell.scrollToSelectedGroup()
                cell = groupedCell
            }
        case .regularTabs:
            guard let tab = dataStore.at(indexPath.row) else { return cell }
            cell = tabDisplayer?.cellFactory(for: cell, using: tab) ?? cell
        case .inactiveTabs:
            if let inactiveCell = collectionView.dequeueReusableCell(withReuseIdentifier: InactiveTabCell.Identifier, for: indexPath) as? InactiveTabCell {
                inactiveCell.inactiveTabsViewModel = inactiveViewModel
                inactiveCell.hasExpanded = isInactiveViewExpanded
                inactiveCell.delegate = self
                inactiveCell.tableView.reloadData()
                cell = inactiveCell
            }
        case .none:
            return cell
        }
        return cell
    }

    @objc func numberOfSections(in collectionView: UICollectionView) -> Int {
        if tabDisplayType == .TopTabTray { return 1 }
        return  TabDisplaySection.allCases.count
    }
}

// MARK: - GroupedTabDelegate
extension TabDisplayManager: GroupedTabDelegate {
    
    func newSearchFromGroup(searchTerm: String) {
        let bvc = BrowserViewController.foregroundBVC()
        bvc.openSearchNewTab(searchTerm)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .groupedTabPerformSearch)
    }
    
    func closeGroupTab(tab: Tab) {
        if self.isPrivate == false, filteredTabs.count + (tabsInAllGroups?.count ?? 0) == 1 {
            self.tabManager.removeTabs([tab])
            self.tabManager.selectTab(self.tabManager.addTab())
            return
        }

        self.tabManager.removeTab(tab)
        removeGroupTab(with: tab)
    }

    func selectGroupTab(tab: Tab) {
        if let tabTray = tabDisplayer as? GridTabViewController {
            tabManager.selectTab(tab)
            tabTray.dismissTabTray()
        }
    }
}

// MARK: - InactiveTabsDelegate
extension TabDisplayManager: InactiveTabsDelegate {
    func didTapRecentlyClosed() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .inactiveTabTray, value: .openRecentlyClosedList, extras: nil)
        self.tabDisplayCompletionDelegate?.displayRecentlyClosedTabs()
    }

    func didSelectInactiveTab(tab: Tab?) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .inactiveTabTray, value: .openInactiveTab, extras: nil)
        if let tabTray = tabDisplayer as? GridTabViewController {
            tabManager.selectTab(tab)
            tabTray.dismissTabTray()
        }
    }

    func toggleInactiveTabSection(hasExpanded: Bool) {
        let hasExpandedEvent: TelemetryWrapper.EventValue = hasExpanded ? .inactiveTabExpand : .inactiveTabCollapse
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .inactiveTabTray, value: hasExpandedEvent, extras: nil)
        isInactiveViewExpanded = hasExpanded
        let indexPath = IndexPath(row: 0, section: 2)
        collectionView.reloadItems(at: [indexPath])
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true  )
    }
}

// MARK: - TabSelectionDelegate
extension TabDisplayManager: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        guard let tab = dataStore.at(index) else { return }
        getTabsAndUpdateInactiveState { tabGroup, tabsToDisplay in
            if tabsToDisplay.firstIndex(of: tab) != nil {
                self.tabManager.selectTab(tab)
            }
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .tab)
        }
    }
}

// MARK: - UIDropInteractionDelegate
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

// MARK: - UICollectionViewDragDelegate
extension TabDisplayManager: UICollectionViewDragDelegate {
    // This is called when the user has long-pressed on a cell, please note that `collectionView.hasActiveDrag` is not true
    // until the user's finger moves. This problem is mitigated by checking the collectionView for activated long press gesture recognizers.
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {

        let section = TabDisplaySection(rawValue: indexPath.section)
        guard tabDisplayType == .TopTabTray || section == .regularTabs else { return [] }
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

// MARK: - UICollectionViewDropDelegate
extension TabDisplayManager: UICollectionViewDropDelegate {
    private func dragPreviewParameters(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TopTabCell else { return nil }
        let previewParams = UIDragPreviewParameters()

        let path = UIBezierPath(roundedRect: cell.selectedBackground.frame, cornerRadius: TopTabsUX.TabCornerRadius)
        previewParams.visiblePath = path

        return previewParams
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters(collectionView, dragPreviewParametersForItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParameters(collectionView, dragPreviewParametersForItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard collectionView.hasActiveDrag, let destinationIndexPath = coordinator.destinationIndexPath, let dragItem = coordinator.items.first?.dragItem, let tab = dragItem.localObject as? Tab, let sourceIndex = dataStore.index(of: tab) else {
            return
        }

        recordEventAndBreadcrumb(object: .tab, method: .drop)

        coordinator.drop(dragItem, toItemAt: destinationIndexPath)

        self.tabManager.moveTab(isPrivate: self.isPrivate, fromIndex: sourceIndex, toIndex: destinationIndexPath.item)

        if let indexToRemove = filteredTabs.firstIndex(of: tab) {
            filteredTabs.remove(at: indexToRemove)
        }

        filteredTabs.insert(tab, at: destinationIndexPath.item)

        if tabDisplayType == .TabGrid {
            saveRegularOrderedTabs(from: filteredTabs)
        }

        dataStore.removeAll()

        filteredTabs.forEach {
            dataStore.insert($0)
        }

        let section = tabDisplayType == .TopTabTray ? 0 : TabDisplaySection.regularTabs.rawValue
        let start = IndexPath(row: sourceIndex, section: section)
        let end = IndexPath(row: destinationIndexPath.item, section: section)
        updateWith(animationType: .moveTab) { [weak self] in
            self?.collectionView.moveItem(at: start, to: end)
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let forbiddenOperation = UICollectionViewDropProposal(operation: .forbidden)
        guard let indexPath = destinationIndexPath else { return forbiddenOperation }
        let section = TabDisplaySection(rawValue: indexPath.section)
        guard tabDisplayType == .TopTabTray || section == .regularTabs else { return forbiddenOperation }
        guard let localDragSession = session.localDragSession, let item = localDragSession.items.first, let _ = item.localObject as? Tab else {
            return forbiddenOperation
        }

        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}

extension TabDisplayManager: TabEventHandler {

    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }
    
    func tabDidSetScreenshot(_ tab: Tab, hasHomeScreenshot: Bool) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }

    private func updateCellFor(tab: Tab, selectedTabChanged: Bool) {
        let selectedTab = tabManager.selectedTab

        updateWith(animationType: .updateTab) { [weak self] in
            guard let index = self?.dataStore.index(of: tab) else { return }
            let section = self?.tabDisplayType == .TopTabTray ? 0 : TabDisplaySection.regularTabs.rawValue

            var indexPaths = [IndexPath(row: index, section: section)]

            if selectedTabChanged {
                self?.tabDisplayer?.focusSelectedTab()

                // Append the previously selected tab to refresh it's state. Useful when the selected tab has change.
                // This method avoids relying on the state of the "previous" selected tab,
                // instead it iterates the displayed tabs to see which appears selected.
                if let previousSelectedIndexPath = self?.indexOfCellDrawnAsPreviouslySelectedTab(currentlySelected: selectedTab,
                                                                                                 inSection: section) {
                    indexPaths.append(previousSelectedIndexPath)
                }
            }

            for indexPath in indexPaths {
                self?.refreshCell(atIndexPath: indexPath)

                // Due to https://github.com/mozilla-mobile/firefox-ios/issues/9526 - Refresh next cell to avoid two selected cells
                let nextTabIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                self?.refreshCell(atIndexPath: nextTabIndex, forceUpdate: false)
            }
        }
    }

    private func refreshCell(atIndexPath indexPath: IndexPath, forceUpdate: Bool = true) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TabTrayCell, let tab = dataStore.at(indexPath.row) else {
            return
        }

        // Only update from nextTabIndex if needed
        guard forceUpdate || cell.isSelectedTab else { return }

        let isSelected = tab == tabManager.selectedTab
        cell.configureWith(tab: tab, isSelected: isSelected)
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

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {
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

        updateWith(animationType: .addTab) { [unowned self] in
            let indexToPlaceTab = getIndexToPlaceTab(placeNextToParentTab: placeNextToParentTab)
            self.dataStore.insert(tab, at: indexToPlaceTab)
            let section = self.tabDisplayType == .TopTabTray ? 0 : TabDisplaySection.regularTabs.rawValue
            self.collectionView.insertItems(at: [IndexPath(row: indexToPlaceTab, section: section)])
        }
    }

    func getIndexToPlaceTab(placeNextToParentTab: Bool) -> Int {
        // Place new tab at the end by default unless it has been opened from parent tab
        var indexToPlaceTab = dataStore.count > 0 ? dataStore.count : 0

        // Open a link from website next to it
        if placeNextToParentTab, let selectedTabUUID = tabManager.selectedTab?.tabUUID {
            let selectedTabIndex = dataStore.firstIndexDel() { t in
                if let uuid = t.value?.tabUUID {
                    return uuid == selectedTabUUID
                }
                return false
            }

            if let selectedTabIndex = selectedTabIndex {
                indexToPlaceTab = selectedTabIndex + 1
            }
        }
        return indexToPlaceTab
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        if cancelDragAndGestures() {
            refreshStore()
            return
        }

        let type = tabManager.normalTabs.isEmpty ? TabAnimationType.removedLastTab : TabAnimationType.removedNonLastTab

        updateWith(animationType: type) { [weak self] in
            guard let removed = self?.dataStore.remove(tab) else { return }
            let section = self?.tabDisplayType == .TopTabTray ? 0 : TabDisplaySection.regularTabs.rawValue
            self?.collectionView.deleteItems(at: [IndexPath(row: removed, section: section)])
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
        self.collectionView.reloadData()
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

extension TabDisplayOrder {
    static func decode() -> TabDisplayOrder? {
        if let tabDisplayOrder = TabDisplayOrder.defaults.object(forKey: PrefsKeys.KeyTabDisplayOrder) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let order = try jsonDecoder.decode(TabDisplayOrder.self, from: tabDisplayOrder)
                return order
            }
            catch let error as NSError {
                Sentry.shared.send(message: "Error: Unable to decode tab display order", tag: SentryTag.tabDisplayManager, severity: .error, description: error.debugDescription)
            }
        }
        return nil
    }

    static func encode(tabDisplayOrder: TabDisplayOrder?) {
        guard let tabDisplayOrder = tabDisplayOrder, !tabDisplayOrder.regularTabUUID.isEmpty else {
            TabDisplayOrder.defaults.removeObject(forKey: PrefsKeys.KeyTabDisplayOrder)
            return
        }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabDisplayOrder) {
            TabDisplayOrder.defaults.set(encoded, forKey: PrefsKeys.KeyTabDisplayOrder)
        }
    }
}
