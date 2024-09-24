// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

class TabDisplayView: UIView,
                      ThemeApplicable,
                      UICollectionViewDelegate,
                      UICollectionViewDelegateFlowLayout,
                      TabCellDelegate,
                      SwipeAnimatorDelegate,
                      InactiveTabsSectionManagerDelegate {
    struct UX {
        static let cornerRadius: CGFloat = 6.0
    }

    enum TabDisplaySection: Int, CaseIterable {
        case inactiveTabs
        case tabs
    }

    enum SectionTabItem: Hashable {
        case inactiveTab(InactiveTabsModel)
        case tab(TabModel)
    }

    let panelType: TabTrayPanelType
    private(set) var tabsState: TabsPanelState
    private var performingChainedOperations = false
    private var inactiveTabsSectionManager: InactiveTabsSectionManager
    private var tabsSectionManager: TabsSectionManager
    private let windowUUID: WindowUUID
    private let animationQueue: TabTrayAnimationQueue
    var theme: Theme?

    // Using tabUUID as it's a way to identify the Tab object which is hashable
    private var tabsListDataSource: UICollectionViewDiffableDataSource<TabDisplaySection, SectionTabItem>?

    private var shouldHideInactiveTabs: Bool {
        guard !tabsState.isPrivateMode else { return true }

        return tabsState.inactiveTabs.isEmpty
    }

    // Dragging on the collection view is either an 'active drag' where the item is moved, or
    // that the item has been long pressed on (and not moved yet), and this gesture recognizer
    // has been triggered
    var isDragging: Bool {
        return collectionView.hasActiveDrag || isLongPressGestureStarted
    }

    private var isLongPressGestureStarted: Bool {
        var started = false
        collectionView.gestureRecognizers?.forEach { recognizer in
            if let recognizer = recognizer as? UILongPressGestureRecognizer,
               recognizer.state == .began || recognizer.state == .changed {
                started = true
            }
        }
        return started
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: bounds,
                                              collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(cellType: TabCell.self)
        collectionView.register(cellType: InactiveTabsCell.self)
        collectionView.register(
            InactiveTabsHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier)
        collectionView.register(
            InactiveTabsFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: InactiveTabsFooterView.cellIdentifier)

        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.dragInteractionEnabled = true
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.collectionViewLayout = createLayout()
        return collectionView
    }()

    // We now use this to set up the cells instead of cellForItemAt
    private func configureDataSource() {
        // Create the diffable data source and its cell provider.
        tabsListDataSource = UICollectionViewDiffableDataSource<TabDisplaySection, SectionTabItem>(collectionView: collectionView)
        { [weak self] (collectionView, indexPath, sectionItem) -> UICollectionViewCell in
            // `identifier/item` is an instance of `tabModel`. Use it to
            // retrieve the tab from the backing data store.
            guard let self else { return UICollectionViewCell() }

            switch sectionItem {
            case .inactiveTab(let inactiveTab):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: InactiveTabsCell.cellIdentifier,
                    for: indexPath
                ) as? InactiveTabsCell
                else { return UICollectionViewCell() }

                cell.configure(with: inactiveTab)
                if let theme = theme {
                    cell.applyTheme(theme: theme)
                }
                return cell
            case .tab(let tab):
                guard
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: TabCell.cellIdentifier,
                        for: indexPath
                    ) as? TabCell
                else { return UICollectionViewCell() }

                cell.configure(with: tab, theme: theme, delegate: self)
                return cell
            }
        }

        // Configure supplementary view provider for section headers
        tabsListDataSource?.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            let reusableView = UICollectionReusableView()
            // Retrieve the section based on the current indexPath
            let section = self?.getTabDisplay(for: indexPath.section)

            // Only show the header for the Inactive Tabs section
            guard let self, section == .inactiveTabs else {
                return nil  // Return nil for the Tabs section, no header will be displayed
            }

            // Dequeue the header view for the inactive tabs section
            if kind == UICollectionView.elementKindSectionHeader,
               let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: InactiveTabsHeaderView.cellIdentifier,
                for: indexPath) as? InactiveTabsHeaderView {
                headerView.state = tabsState.isInactiveTabsExpanded ? .down : .trailing
                if let theme = theme {
                    headerView.applyTheme(theme: theme)
                }
                headerView.moreButton.isHidden = false
                headerView.moreButton.addTarget(self,
                                                action: #selector(toggleInactiveTab),
                                                for: .touchUpInside)
                headerView.accessibilityLabel = tabsState.isInactiveTabsExpanded ?
                    .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionOpenedAccessibilityTitle :
                    .TabsTray.InactiveTabs.TabsTrayInactiveTabsSectionClosedAccessibilityTitle
                let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                  action: #selector(toggleInactiveTab))
                headerView.addGestureRecognizer(tapGestureRecognizer)
                return headerView
            } else if kind == UICollectionView.elementKindSectionFooter,
                      tabsState.isInactiveTabsExpanded,
                      let footerView = collectionView.dequeueReusableSupplementaryView(
                        ofKind: UICollectionView.elementKindSectionFooter,
                        withReuseIdentifier: InactiveTabsFooterView.cellIdentifier,
                        for: indexPath) as? InactiveTabsFooterView {
                if let theme = theme {
                    footerView.applyTheme(theme: theme)
                }
                footerView.buttonClosure = {
                    let action = TabPanelViewAction(panelType: self.panelType,
                                                    windowUUID: self.windowUUID,
                                                    actionType: TabPanelViewActionType.closeAllInactiveTabs)
                    store.dispatch(action)
                }
                return footerView
            }

            return reusableView
        }
    }

    public init(panelType: TabTrayPanelType,
                state: TabsPanelState,
                windowUUID: WindowUUID,
                animationQueue: TabTrayAnimationQueue = TabTrayAnimationQueueImplementation()) {
        self.panelType = panelType
        self.tabsState = state
        self.inactiveTabsSectionManager = InactiveTabsSectionManager()
        self.tabsSectionManager = TabsSectionManager()
        self.windowUUID = windowUUID
        self.animationQueue = animationQueue
        super.init(frame: .zero)
        self.inactiveTabsSectionManager.delegate = self
        setupLayout()
        configureDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func newState(state: TabsPanelState) {
        tabsState = state
        if state.didRefreshTabs {
            updateCollectionView(state: tabsState)
        }


        if let index = state.scrollToIndex {
            scrollToTab(index)
        }

        if state.didTapAddTab {
//            animationQueue.addAnimation(for: collectionView) { [weak self] in
//                guard let self else { return }

                let action = TabPanelViewAction(panelType: self.panelType,
                                                windowUUID: self.windowUUID,
                                                actionType: TabPanelViewActionType.addNewTab)
                store.dispatch(action)
           // }
        }
    }

    private func updateCollectionView(state: TabsPanelState) {

        // Step 1: Retrieve the current snapshot
       // guard let currentSnapshot = tabsListDataSource?.snapshot() else { return }
         var snapshot = NSDiffableDataSourceSnapshot<TabDisplaySection, SectionTabItem>()

          // Add sections
          snapshot.appendSections([.tabs, .inactiveTabs])

          // Add tabs to the snapshot
          let tabs = state.tabs.map { SectionTabItem.tab($0) }
          snapshot.appendItems(tabs, toSection: .tabs)

          // Add inactive tabs to the snapshot
          let inactiveTabs = state.inactiveTabs.map { SectionTabItem.inactiveTab($0) }
          snapshot.appendItems(inactiveTabs, toSection: .inactiveTabs)

          // Apply the snapshot to the diffable data source
        tabsListDataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func scrollToTab(_ index: Int) {
        let section = shouldHideInactiveTabs ? 0 : 1
        let indexPath = IndexPath(row: index,
                                  section: section)
            collectionView.scrollToItem(at: indexPath,
                                        at: .centeredVertically,
                                        animated: false)
    }

    private func setupLayout() {
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        // swiftlint:disable line_length
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
        // swiftlint:enable line_length
            guard let self else { return nil }

            // If on private mode or regular mode but without inactive
            // tabs we return only the tabs layout
            guard !shouldHideInactiveTabs else {
                return self.tabsSectionManager.layoutSection(layoutEnvironment)
            }

            let section = self.getSectionLayout(sectionIndex)
            switch section {
            case .inactiveTabs:
                return self.inactiveTabsSectionManager.layoutSection(
                    layoutEnvironment,
                    isExpanded: tabsState.isInactiveTabsExpanded)
            case .tabs:
                return self.tabsSectionManager.layoutSection(layoutEnvironment)
            }
        }
        return layout
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
        collectionView.backgroundColor = theme.colors.layer3
    }

    // MARK: - Private helpers
    private func getSectionLayout(_ sectionIndex: Int) -> TabDisplaySection {
        guard let section = TabDisplaySection(rawValue: sectionIndex) else { return .tabs }

        return section
    }

    // SOPHIE - comment out to check what needs to be removed after diffable datasource implementation
    private func getTabDisplay(for section: Int) -> TabDisplaySection {
        guard !shouldHideInactiveTabs else { return .tabs }

        return TabDisplaySection(rawValue: section) ?? .tabs
    }

    func deleteInactiveTab(for index: Int) {
        let inactiveTabs = tabsState.inactiveTabs[index]
        let action = TabPanelViewAction(panelType: panelType,
                                        tabUUID: inactiveTabs.tabUUID,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.closeInactiveTabs)
        store.dispatch(action)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch getTabDisplay(for: indexPath.section) {
        case .inactiveTabs:
            let tabUUID = tabsState.inactiveTabs[indexPath.row].tabUUID
            let action = TabPanelViewAction(panelType: panelType,
                                            tabUUID: tabUUID,
                                            windowUUID: windowUUID,
                                            actionType: TabPanelViewActionType.selectTab)
            store.dispatch(action)
        case .tabs:
            let tabUUID = tabsState.tabs[indexPath.row].tabUUID
            let action = TabPanelViewAction(panelType: panelType,
                                            tabUUID: tabUUID,
                                            windowUUID: windowUUID,
                                            actionType: TabPanelViewActionType.selectTab)
            store.dispatch(action)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard getTabDisplay(for: indexPath.section) == .tabs
        else { return nil }

        let tabVC = TabPeekViewController(tab: tabsState.tabs[indexPath.row], windowUUID: windowUUID)
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: { return tabVC },
                                          actionProvider: tabVC.contextActions)
    }

    @objc
    func toggleInactiveTab() {
        let action = TabPanelViewAction(panelType: panelType,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.toggleInactiveTabs)
        store.dispatch(action)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - TabCellDelegate
    func tabCellDidClose(for tabUUID: TabUUID) {
        animationQueue.addAnimation(for: collectionView) { [weak self] in
            guard let self else { return }
            let action = TabPanelViewAction(panelType: panelType,
                                            tabUUID: tabUUID,
                                            windowUUID: windowUUID,
                                            actionType: TabPanelViewActionType.closeTab)
            store.dispatch(action)
        }
    }

    // MARK: - SwipeAnimatorDelegate
    func swipeAnimator(_ animator: SwipeAnimator) {
        guard let tabCell = animator.animatingView as? TabCell,
              let indexPath = collectionView.indexPath(for: tabCell) else { return }

        let tab = tabsState.tabs[indexPath.item]
        let action = TabPanelViewAction(panelType: panelType,
                                        tabUUID: tab.tabUUID,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.closeTab)
        store.dispatch(action)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement,
                             argument: String.TabTrayClosingTabAccessibilityMessage)
    }

    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool {
        return !isDragging
    }
}

// MARK: - Drag and Drop delegates
extension TabDisplayView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard getTabDisplay(for: indexPath.section) == .tabs else { return [] }

        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = tabsState.tabs[indexPath.row]
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        // Ensure the drag is active and gather the necessary data
        guard collectionView.hasActiveDrag,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let dragItem = coordinator.items.first?.dragItem,
              let tab = dragItem.localObject as? TabModel,
              let sourceIndex = tabsState.tabs.firstIndex(of: tab) else { return }

        // Define the section and source/destination index paths
        let section = destinationIndexPath.section
        let start = IndexPath(row: sourceIndex, section: section)
        let end = IndexPath(row: destinationIndexPath.item, section: section)

        let items = coordinator.items
        if items.count == 1, let item = items.first, let sourceIndexPath = item.sourceIndexPath {
            var destIndexPath = destinationIndexPath
            if destIndexPath.row >= collectionView.numberOfItems(inSection: destIndexPath.section) {
                destIndexPath.row = collectionView.numberOfItems(inSection: destIndexPath.section) - 1
            }

            guard let firstItem = tabsListDataSource?.itemIdentifier(for: sourceIndexPath),
                  let secondItem = tabsListDataSource?.itemIdentifier(for: destIndexPath)
            else { return }

            coordinator.drop(dragItem, toItemAt: destinationIndexPath)
            var currentSnapshot = tabsListDataSource?.snapshot()
            currentSnapshot?.insertItems([firstItem], beforeItem: secondItem)
            currentSnapshot?.deleteItems([secondItem])
            tabsListDataSource?.apply(currentSnapshot!, animatingDifferences: true)
            //           var snapshot = NSDiffableDataSourceSnapshot<TabDisplaySection, SectionTabItem>()
//            snapshot.moveItem(firstItem, beforeItem: secondItem)
//            tabsListDataSource?.apply(snapshot, animatingDifferences: true)

        }

        // Prepare the data for the move action
        let moveTabData = MoveTabData(originIndex: start.row,
                                      destinationIndex: end.row,
                                      isPrivate: tabsState.isPrivateMode)

        let action = TabPanelViewAction(
            panelType: panelType,
            moveTabData: moveTabData,
            windowUUID: windowUUID,
            actionType: TabPanelViewActionType.moveTab
        )

        store.dispatch(action)
    }

    private func updateMovedItemsSnapshot(tempTabs: [TabModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<TabDisplaySection, SectionTabItem>()

          // Add sections
          snapshot.appendSections([.tabs])

          // Add tabs to the snapshot
        let tabs = tempTabs.map { SectionTabItem.tab($0) }
          snapshot.appendItems(tabs, toSection: .tabs)

        // Apply the snapshot to the diffable data source
        tabsListDataSource?.apply(snapshot, animatingDifferences: true)
    }
}
