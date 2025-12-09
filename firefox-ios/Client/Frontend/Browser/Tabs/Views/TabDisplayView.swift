// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

protocol TabDisplayViewDragAndDropInteraction: AnyObject {
    @MainActor
    func dragAndDropStarted()
    @MainActor
    func dragAndDropEnded()
}

/// NOTE: ⚠️ CRITICAL: `TabTitleSupplementaryView` Creation.
/// The app was crashing with `NSInternalInconsistencyException` when `TabTitleSupplementaryView`
/// was successfully created but then returned `nil` due to missing tab data: https://mozilla-hub.atlassian.net/browse/FXIOS-13374.
/// This violated `UICollectionViewDiffableDataSource`'s requirement that `supplementaryViewProvider` must always
/// return a valid view.
///
/// IMPORTANT: Returning `nil` is acceptable when cell creation fails, but we must avoid the pattern
/// of successfully creating our designated cell only to return `nil` based on subsequent conditions.
///
/// Always return a valid view once creation succeeds, or fail early during creation.
final class TabDisplayView: UIView,
                      ThemeApplicable,
                      UICollectionViewDelegate,
                      UICollectionViewDelegateFlowLayout,
                      TabCellDelegate,
                      SwipeAnimatorDelegate,
                      FeatureFlaggable,
                      InsetUpdatable {
    struct UX {
        static let cornerRadius: CGFloat = 6.0
    }

    let panelType: TabTrayPanelType
    private(set) var tabsState: TabsPanelState
    private var performingChainedOperations = false
    private var tabsSectionManager: TabsSectionManager
    private let windowUUID: WindowUUID
    var theme: Theme?
    weak var dragAndDropDelegate: TabDisplayViewDragAndDropInteraction?

    lazy var dataSource =
    TabDisplayDiffableDataSource(
        collectionView: collectionView,
        cellProvider: { [weak self] (collectionView, indexPath, sectionItem) ->
            UICollectionViewCell in
            guard let self else { return UICollectionViewCell() }

            switch sectionItem {
            case .tab(let tab):
                if isTabTrayUIExperimentsEnabled {
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: ExperimentTabCell.cellIdentifier,
                        for: indexPath
                    ) as? ExperimentTabCell else { return UICollectionViewCell() }

                    let a11yId = "\(AccessibilityIdentifiers.TabTray.tabCell)_\(indexPath.section)_\(indexPath.row)"
                    cell.configure(with: tab, theme: theme, delegate: self, a11yId: a11yId)
                    return cell
                } else {
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: TabCell.cellIdentifier,
                        for: indexPath
                    ) as? TabCell else { return UICollectionViewCell() }

                    let a11yId = "\(AccessibilityIdentifiers.TabTray.tabCell)_\(indexPath.section)_\(indexPath.row)"
                    cell.configure(with: tab, theme: theme, delegate: self, a11yId: a11yId)
                    return cell
                }
            }
        })

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
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
        if isTabTrayUIExperimentsEnabled {
            collectionView.register(cellType: ExperimentTabCell.self)
            collectionView.register(
                TabTitleSupplementaryView.self,
                forSupplementaryViewOfKind: TabTitleSupplementaryView.cellIdentifier,
                withReuseIdentifier: TabTitleSupplementaryView.cellIdentifier
            )
        } else {
            collectionView.register(cellType: TabCell.self)
        }

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
        self.tabsSectionManager = TabsSectionManager()
        self.windowUUID = windowUUID
        super.init(frame: .zero)
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

        dataSource.updateSnapshot(state: tabsState)

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
        let indexPath = IndexPath(row: scrollState.toIndex, section: 0)
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
        dataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            // swiftlint:enable line_length
            return self?.getSupplementary(collectionView: collectionView, kind: kind, indexPath: indexPath)
        }
    }

    private func getSupplementary(collectionView: UICollectionView,
                                  kind: String,
                                  indexPath: IndexPath) -> UICollectionReusableView? {
        switch kind {
        case TabTitleSupplementaryView.cellIdentifier:
            guard let titleView = collectionView.dequeueReusableSupplementaryView(
                ofKind: TabTitleSupplementaryView.cellIdentifier,
                withReuseIdentifier: TabTitleSupplementaryView.cellIdentifier,
                for: indexPath
            ) as? TabTitleSupplementaryView else { return nil }

            if let tab = tabsState.tabs[safe: indexPath.row] {
                titleView.configure(with: tab, theme: theme)
            }
            return titleView

        default:
            assertionFailure("This is a developer error")
            return nil
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
            if isTabTrayUIExperimentsEnabled {
                return self.tabsSectionManager.experimentLayoutSection(layoutEnvironment)
            } else {
                return self.tabsSectionManager.layoutSection(layoutEnvironment)
            }
        }
        return layout
    }

    func applyTheme(theme: Theme) {
        self.theme = theme
        collectionView.backgroundColor = theme.colors.layer3
        collectionView.visibleCells.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
        collectionView.visibleSupplementaryViews(ofKind: TabTitleSupplementaryView.cellIdentifier)
            .compactMap { $0 as? TabTitleSupplementaryView }
            .forEach { $0.applyTheme(theme: theme) }
    }

    private func getSection(for sectionIndex: Int) -> TabDisplayViewSection {
        let snapshot = dataSource.snapshot()
        guard
            sectionIndex >= 0,
            sectionIndex < snapshot.sectionIdentifiers.count
        else { return TabDisplayViewSection.tabs }

        return snapshot.sectionIdentifiers[sectionIndex]
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedItem = dataSource.itemIdentifier(for: indexPath) {
            switch selectedItem {
            case .tab(let tabModel):
                let tabUUID = tabModel.tabUUID
                let action = TabPanelViewAction(panelType: panelType,
                                                tabUUID: tabUUID,
                                                selectedTabIndex: indexPath.item,
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

    // MARK: - TabCellDelegate
    func tabCellDidClose(for tabUUID: TabUUID) {
        if !isDragging {
            let action = TabPanelViewAction(panelType: panelType,
                                            tabUUID: tabUUID,
                                            windowUUID: windowUUID,
                                            actionType: TabPanelViewActionType.closeTab)
            store.dispatch(action)
        }
    }

    // MARK: - SwipeAnimatorDelegate
    func swipeAnimator(_ animator: SwipeAnimator) {
        guard let tabCell = animator.animatingView as? UICollectionViewCell,
              let indexPath = collectionView.indexPath(for: tabCell) else { return }

        let tab = tabsState.tabs[indexPath.item]
        let action = TabPanelViewAction(panelType: panelType,
                                        tabUUID: tab.tabUUID,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.closeTab)
        store.dispatch(action)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement,
                             argument: String.TabsTray.TabTrayClosingTabAccessibilityMessage)
    }

    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool {
        return !isDragging
    }

    // MARK: - InsetUpdatable

    func updateInsets(top: CGFloat, bottom: CGFloat) {
        collectionView.contentInset.top = top
        collectionView.contentInset.bottom = bottom
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

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        dragAndDropDelegate?.dragAndDropStarted()
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        dragAndDropDelegate?.dragAndDropEnded()
    }
}
