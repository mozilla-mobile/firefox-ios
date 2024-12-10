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

    let panelType: TabTrayPanelType
    private(set) var tabsState: TabsPanelState
    private var performingChainedOperations = false
    private var inactiveTabsSectionManager: InactiveTabsSectionManager
    private var tabsSectionManager: TabsSectionManager
    private let windowUUID: WindowUUID
    var theme: Theme?

    private var dataSource: TabDisplayDiffableDataSource?

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
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.collectionView
        return collectionView
    }()

    public init(panelType: TabTrayPanelType,
                state: TabsPanelState,
                windowUUID: WindowUUID) {
        self.panelType = panelType
        self.tabsState = state
        self.inactiveTabsSectionManager = InactiveTabsSectionManager()
        self.tabsSectionManager = TabsSectionManager()
        self.windowUUID = windowUUID
        super.init(frame: .zero)
        self.inactiveTabsSectionManager.delegate = self
        setupLayout()
        configureDataSource()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func newState(state: TabsPanelState) {
        // We only want to respond to `TabsPanelState` for the current `panelType` (e.g. don't scroll the regular tabs for
        // a private tabs scroll)
        switch panelType {
        case .tabs:
            guard !state.isPrivateMode else { return }
        case .privateTabs:
            guard state.isPrivateMode else { return }
        case .syncedTabs:
            // This view does not handle synced tabs
            return
        }

        tabsState = state

        dataSource?.updateSnapshot(state: tabsState)

        if let scrollState = state.scrollState {
            scrollToTab(scrollState)
        }

        if state.didTapAddTab {
            let action = TabPanelViewAction(panelType: self.panelType,
                                            windowUUID: self.windowUUID,
                                            actionType: TabPanelViewActionType.addNewTab)
            store.dispatch(action)
        }
    }

    private func scrollToTab(_ scrollState: TabsPanelState.ScrollState) {
        let section: Int = scrollState.isInactiveTabSection ? 0 : 1
        let indexPath = IndexPath(row: scrollState.toIndex, section: section)
        // Piping this into main thread let the collection view finish its layout process
        DispatchQueue.main.async {
            guard !self.collectionView.indexPathsForFullyVisibleItems.contains(indexPath) else { return }
            guard self.collectionView.isValid(indexPath: indexPath) else { return }
            self.collectionView.scrollToItem(at: indexPath,
                                             at: .centeredVertically,
                                             animated: scrollState.withAnimation)
        }
    }

    private func configureDataSource() {
        // swiftlint:disable line_length
        dataSource = TabDisplayDiffableDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, sectionItem) ->
            UICollectionViewCell in
            // swiftlint:enable line_length
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

                let a11yId = "\(AccessibilityIdentifiers.TabTray.tabCell)_\(indexPath.section)_\(indexPath.row)"
                cell.configure(with: tab, theme: theme, delegate: self, a11yId: a11yId)
                return cell
            }
        }

        // swiftlint:disable line_length
        dataSource?.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            // swiftlint:enable line_length
            let reusableView = UICollectionReusableView()
            let section = self?.getSection(for: indexPath.section)

            guard let self, section != .tabs else { return nil }

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

            let section = getSection(for: sectionIndex)
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

    private func getSection(for sectionIndex: Int) -> TabDisplayViewSection {
        guard
            let snapshot = dataSource?.snapshot(),
            sectionIndex >= 0,
            sectionIndex < snapshot.sectionIdentifiers.count
        else { return TabDisplayViewSection.tabs }

        return snapshot.sectionIdentifiers[sectionIndex]
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
        if let selectedItem = dataSource?.itemIdentifier(for: indexPath) {
            switch selectedItem {
            case .inactiveTab(let inactiveTabsModel):
                let tabUUID = inactiveTabsModel.tabUUID
                let action = TabPanelViewAction(panelType: panelType,
                                                tabUUID: tabUUID,
                                                windowUUID: windowUUID,
                                                actionType: TabPanelViewActionType.selectTab)
                store.dispatch(action)
            case .tab(let tabModel):
                let tabUUID = tabModel.tabUUID
                let action = TabPanelViewAction(panelType: panelType,
                                                tabUUID: tabUUID,
                                                windowUUID: windowUUID,
                                                actionType: TabPanelViewActionType.selectTab)
                store.dispatch(action)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard getSection(for: indexPath.section) == .tabs
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
    }

    // MARK: - TabCellDelegate
    func tabCellDidClose(for tabUUID: TabUUID) {
        let action = TabPanelViewAction(panelType: panelType,
                                        tabUUID: tabUUID,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.closeTab)
        store.dispatch(action)
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
        guard getSection(for: indexPath.section) == .tabs else { return [] }

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
        guard collectionView.hasActiveDrag,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let dragItem = coordinator.items.first?.dragItem,
              let tab = dragItem.localObject as? TabModel,
              let sourceIndex = tabsState.tabs.firstIndex(of: tab)
        else { return }

        let section = destinationIndexPath.section
        let start = IndexPath(row: sourceIndex, section: section)
        let end = IndexPath(row: destinationIndexPath.item, section: section)

        coordinator.drop(dragItem, toItemAt: destinationIndexPath)

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
}
