// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared

struct GridTabTrayControllerUX {
    static let CornerRadius = CGFloat(6.0)
    static let TextBoxHeight = CGFloat(32.0)
    static let NavigationToolbarHeight = CGFloat(44)
    static let FaviconSize = CGFloat(20)
    static let Margin = CGFloat(15)
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let CloseButtonSize = CGFloat(32)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(7)
    static let NumberOfColumnsThin = 1
    static let NumberOfColumnsWide = 3
    static let CompactNumberOfColumnsThin = 2
    static let MenuFixedWidth: CGFloat = 320
}

protocol TabTrayDelegate: AnyObject {
    func tabTrayDidDismiss(_ tabTray: GridTabViewController)
    func tabTrayDidAddTab(_ tabTray: GridTabViewController, tab: Tab)
    func tabTrayDidAddBookmark(_ tab: Tab)
    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListItem?
    func tabTrayOpenRecentlyClosedTab(_ url: URL)
    func tabTrayDidRequestTabsSettings()
}

class GridTabViewController: UIViewController, TabTrayViewDelegate {
    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?
    var tabDisplayManager: TabDisplayManager!
    var tabCellIdentifer: TabDisplayer.TabCellIdentifer = TabCell.cellIdentifier
    static let independentTabsHeaderIdentifier = "IndependentTabs"
    var otherBrowsingModeOffset = CGPoint.zero
    // Backdrop used for displaying greyed background for private tabs
    var webViewContainerBackdrop = UIView()
    var collectionView: UICollectionView!
    var recentlyClosedTabsPanel: RecentlyClosedTabsPanel?
    var notificationCenter: NotificationCenter
    var contextualHintViewController: ContextualHintViewController

    // This is an optional variable used if we wish to focus a tab that is not the
    // currently selected tab. This allows us to force the scroll behaviour to move
    // whereever we need to focus the user's attention.
    var tabToFocus: Tab?

    override var canBecomeFirstResponder: Bool {
        return true
    }

    fileprivate lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.learnMoreButton.addTarget(self, action: #selector(didTapLearnMore), for: .touchUpInside)
        return emptyView
    }()

    fileprivate lazy var tabLayoutDelegate: TabLayoutDelegate = {
        let delegate = TabLayoutDelegate(tabDisplayManager: self.tabDisplayManager, traitCollection: self.traitCollection, scrollView: self.collectionView)
        delegate.tabSelectionDelegate = self
        delegate.tabPeekDelegate = self
        return delegate
    }()

    var numberOfColumns: Int {
        return tabLayoutDelegate.numberOfColumns
    }

    // MARK: - Inits
    init(tabManager: TabManager,
         profile: Profile,
         tabTrayDelegate: TabTrayDelegate? = nil,
         tabToFocus: Tab? = nil,
         notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.tabManager = tabManager
        self.profile = profile
        self.delegate = tabTrayDelegate
        self.tabToFocus = tabToFocus
        self.notificationCenter = notificationCenter

        let contextualViewModel = ContextualHintViewModel(forHintType: .inactiveTabs,
                                                          with: profile)
        self.contextualHintViewController = ContextualHintViewController(with: contextualViewModel)

        super.init(nibName: nil, bundle: nil)
        collectionViewSetup()
    }

    private func collectionViewSetup() {
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(cellType: TabCell.self)
        collectionView.register(cellType: GroupedTabCell.self)
        collectionView.register(cellType: InactiveTabCell.self)
        collectionView.register(
            LabelButtonHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: GridTabViewController.independentTabsHeaderIdentifier)
        tabDisplayManager = TabDisplayManager(collectionView: self.collectionView,
                                              tabManager: self.tabManager,
                                              tabDisplayer: self,
                                              reuseID: TabCell.cellIdentifier,
                                              tabDisplayType: .TabGrid,
                                              profile: profile,
                                              cfrDelegate: self)
        collectionView.dataSource = tabDisplayManager
        collectionView.delegate = tabLayoutDelegate

        tabDisplayManager.tabDisplayCompletionDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tabManager.addDelegate(self)
        view.accessibilityLabel = .TabTrayViewAccessibilityLabel

        webViewContainerBackdrop.alpha = 0

        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag

        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = tabDisplayManager
        collectionView.dropDelegate = tabDisplayManager

        setupView()

        if let tab = tabManager.selectedTab, tab.isPrivate {
            tabDisplayManager.togglePrivateMode(isOn: true, createTabOnEmptyPrivateMode: false)
        }

        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()

        applyTheme()

        setupNotifications(forObserver: self, observing: [
            UIApplication.willResignActiveNotification,
            UIApplication.didBecomeActiveNotification,
            .DisplayThemeChanged
        ])
    }

    private func setupView() {
        // TODO: Remove SNAPKIT - this will require some work as the layouts
        // are using other snapkit constraints and this will require modification
        // in several places.
        [webViewContainerBackdrop, collectionView].forEach { view.addSubview($0) }
        setupConstraints()

        view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(self.collectionView)
        }
    }

    private func setupConstraints() {
        webViewContainerBackdrop.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
        focusItem()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // When the app enters split screen mode we refresh the collection view layout to show the proper grid
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard let flowlayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowlayout.invalidateLayout()
    }

    deinit {
        tabManager.removeDelegate(self.tabDisplayManager)
        tabManager.removeDelegate(self)
        tabDisplayManager = nil
        contextualHintViewController.stopTimer()
        notificationCenter.removeObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scrolling helper methods
    /// The main interface for scrolling to an item, whether that is a group or an individual tab
    ///
    /// This method checks for the existence of a tab to focus on other than the selected tab,
    /// and then, focuses on that tab. The byproduct is that if the tab is in a group, the
    /// user would then be looking at the group. Generally, if focusing on a group and
    /// NOT the selected tab, it is advised to pass in the first tab of that group as
    /// the `tabToFocus` in the initializer
    func focusItem() {
        guard let selectedTab = tabManager.selectedTab else { return }
        if tabToFocus == nil { tabToFocus = selectedTab }
        guard let tabToFocus = tabToFocus else { return }

        if let tabGroups = tabDisplayManager.tabGroups,
           tabGroups.count > 0,
           tabGroups.contains(where: { $0.groupedItems.contains(where: { $0 == tabToFocus }) }) {
            focusGroup(from: tabGroups, with: tabToFocus)

        } else {
            focusTab(tabToFocus)
        }
    }

    func focusGroup(from tabGroups: [ASGroup<Tab>], with tabToFocus: Tab) {
        if let tabIndex = tabDisplayManager.indexOfGroupTab(tab: tabToFocus) {
            let groupName = tabIndex.groupName
            let groupIndex: Int = tabGroups.firstIndex(where: { $0.searchTerm == groupName }) ?? 0
            let offSet = Int(GroupedTabCellProperties.CellUX.defaultCellHeight) * groupIndex
            let rect = CGRect(origin: CGPoint(x: 0, y: offSet), size: CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height))
            DispatchQueue.main.async {
                self.collectionView.scrollRectToVisible(rect, animated: false)
            }
        }
    }

    func focusTab(_ selectedTab: Tab) {
        if let indexOfRegularTab = tabDisplayManager.indexOfRegularTab(tab: selectedTab) {
            let indexPath = IndexPath(item: indexOfRegularTab, section: TabDisplaySection.regularTabs.rawValue)
            guard var rect = self.collectionView.layoutAttributesForItem(at: indexPath)?.frame else { return }
            if indexOfRegularTab >= self.tabDisplayManager.dataStore.count - 2 {
                DispatchQueue.main.async {
                    rect.origin.y += 10
                    self.collectionView.scrollRectToVisible(rect, animated: false)
                }
            } else {
                self.collectionView.scrollToItem(at: indexPath, at: [.centeredVertically, .centeredHorizontally], animated: false)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
    }

    @objc func didTogglePrivateMode() {
        tabManager.willSwitchTabMode(leavingPBM: tabDisplayManager.isPrivate)

        tabDisplayManager.togglePrivateMode(isOn: !tabDisplayManager.isPrivate, createTabOnEmptyPrivateMode: false)

        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()
    }

    fileprivate func privateTabsAreEmpty() -> Bool {
        return tabDisplayManager.isPrivate && tabManager.privateTabs.isEmpty
    }

    func openNewTab(_ request: URLRequest? = nil, isPrivate: Bool) {
        if tabDisplayManager.isDragging {
            return
        }

        // Ensure Firefox home page is refreshed if privacy mode was changed
        if tabManager.selectedTab?.isPrivate != isPrivate {
            let notificationObject = [Tab.privateModeKey: isPrivate]
            NotificationCenter.default.post(name: .TabsPrivacyModeChanged, object: notificationObject)
        }

        tabManager.selectTab(tabManager.addTab(request, isPrivate: isPrivate))
    }
}

extension GridTabViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        NotificationCenter.default.post(name: .UpdateLabelOnTabClosed, object: nil)
    }
    func tabManagerDidAddTabs(_ tabManager: TabManager) {}

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        self.emptyPrivateTabsView.isHidden = !self.privateTabsAreEmpty()
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        // No need to handle removeAll toast in TabTray.
        // When closing all normal tabs we automatically focus a tab and show the BVC. Which will handle the Toast.
        // We don't show the removeAll toast in PBM
    }
}

extension GridTabViewController: TabDisplayer {

    func focusSelectedTab() {
        self.focusItem()
    }

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TabCell else { return cell }
        tabCell.animator?.delegate = self
        tabCell.delegate = self
        let selected = tab == tabManager.selectedTab
        tabCell.configureWith(tab: tab, isSelected: selected)
        return tabCell
    }
}

extension GridTabViewController {

    @objc func didTapLearnMore() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let langID = Locale.preferredLanguages.first {
            let learnMoreRequest = URLRequest(url: "https://support.mozilla.org/1/mobile/\(appVersion ?? "0.0")/iOS/\(langID)/private-browsing-ios".asURL!)
            openNewTab(learnMoreRequest, isPrivate: tabDisplayManager.isPrivate)
        }
    }

    func closeTabsTrayBackground() {
        tabDisplayManager.removeAllTabsFromView()

        tabManager.backgroundRemoveAllTabs(isPrivate: tabDisplayManager.isPrivate) {
            recentlyClosedTabs, isPrivateState, previousTabUUID in

            DispatchQueue.main.async { [unowned self] in
                if isPrivateState {
                    let previousTab = self.tabManager.tabs.filter { $0.tabUUID == previousTabUUID }.first
                    self.tabManager.cleanupClosedTabs(recentlyClosedTabs,
                                                      previous: previousTab,
                                                      isPrivate: isPrivateState)
                } else {
                    self.tabManager.makeToastFromRecentlyClosedUrls(recentlyClosedTabs,
                                                                    isPrivate: isPrivateState,
                                                                    previousTabUUID: previousTabUUID)
                }
                closeTabsTrayHelper()
            }
        }
    }

    func closeTabsTrayHelper() {
        if self.tabDisplayManager.isPrivate {
            self.emptyPrivateTabsView.isHidden = !self.privateTabsAreEmpty()
            if !self.emptyPrivateTabsView.isHidden {
                // Fade in the empty private tabs message. This slow fade allows time for the closing tab animations to complete.
                self.emptyPrivateTabsView.alpha = 0
                UIView.animate(withDuration: 0.5, animations: {
                    self.emptyPrivateTabsView.alpha = 1
                }, completion: nil)
            }
        } else if self.tabManager.normalTabs.count == 1, let tab = self.tabManager.normalTabs.first {
            self.tabManager.selectTab(tab)
            self.dismissTabTray()
            notificationCenter.post(name: .TabsTrayDidClose, object: nil)
        }
    }

    func didTogglePrivateMode(_ togglePrivateModeOn: Bool) {
        if togglePrivateModeOn != tabDisplayManager.isPrivate {
            didTogglePrivateMode()
        }
    }

    func dismissTabTray() {
        self.navigationController?.dismiss(animated: true, completion: nil)
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
    }

}

// MARK: - App Notifications
extension GridTabViewController {
    @objc func appWillResignActiveNotification() {
        if tabDisplayManager.isPrivate {
            webViewContainerBackdrop.alpha = 1
            view.bringSubviewToFront(webViewContainerBackdrop)
            collectionView.alpha = 0
            emptyPrivateTabsView.alpha = 0
        }
    }

    @objc func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.alpha = 1
            self.emptyPrivateTabsView.alpha = 1
        }) { _ in
            self.webViewContainerBackdrop.alpha = 0
            self.view.sendSubviewToBack(self.webViewContainerBackdrop)
        }
    }
}

extension GridTabViewController: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        if let tab = tabDisplayManager.dataStore.at(index) {
            if tab.isFxHomeTab {
                notificationCenter.post(name: .TabsTrayDidSelectHomeTab, object: nil)
            }
            tabManager.selectTab(tab)
            dismissTabTray()
        }
    }
}

// MARK: UIScrollViewAccessibilityDelegate
extension GridTabViewController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
        guard var visibleCells = collectionView.visibleCells as? [TabCell] else { return nil }
        var bounds = collectionView.bounds
        bounds = bounds.offsetBy(dx: collectionView.contentInset.left, dy: collectionView.contentInset.top)
        bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
        bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
        // visible cells do sometimes return also not visible cells when attempting to go past the last cell with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
        visibleCells = visibleCells.filter { !$0.frame.intersection(bounds).isEmpty }

        let cells = visibleCells.map { self.collectionView.indexPath(for: $0)! }
        let indexPaths = cells.sorted { (a: IndexPath, b: IndexPath) -> Bool in
            return a.section < b.section || (a.section == b.section && a.row < b.row)
        }

        guard !indexPaths.isEmpty else {
            return .TabTrayNoTabsAccessibilityHint
        }

        let firstTab = indexPaths.first!.row + 1
        let lastTab = indexPaths.last!.row + 1
        let tabCount = collectionView.numberOfItems(inSection: 1)

        if firstTab == lastTab {
            let format: String = .TabTrayVisibleTabRangeAccessibilityHint
            return String(format: format, NSNumber(value: firstTab as Int), NSNumber(value: tabCount as Int))
        } else {
            let format: String = .TabTrayVisiblePartialRangeAccessibilityHint
            return String(format: format, NSNumber(value: firstTab as Int), NSNumber(value: lastTab as Int), NSNumber(value: tabCount as Int))
        }
    }
}

// MARK: - SwipeAnimatorDelegate
extension GridTabViewController: SwipeAnimatorDelegate {
    func swipeAnimator(_ animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
        guard let tabCell = animator.animatingView as? TabCell, let indexPath = collectionView.indexPath(for: tabCell) else { return }
        if let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            self.removeByButtonOrSwipe(tab: tab, cell: tabCell)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.TabTrayClosingTabAccessibilityMessage)
        }
    }

    // Disable swipe delete while drag reordering
    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool {
        return !tabDisplayManager.isDragging
    }
}

extension GridTabViewController: TabCellDelegate {
    func tabCellDidClose(_ cell: TabCell) {
        if let indexPath = collectionView.indexPath(for: cell), let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            removeByButtonOrSwipe(tab: tab, cell: cell)
        }
    }
}

extension GridTabViewController: TabPeekDelegate {

    func tabPeekDidAddBookmark(_ tab: Tab) {
        delegate?.tabTrayDidAddBookmark(tab)
    }

    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? {
        return delegate?.tabTrayDidAddToReadingList(tab)
    }

    func tabPeekDidCloseTab(_ tab: Tab) {
        // Tab peek is only available on regular tabs
        if let index = tabDisplayManager.dataStore.index(of: tab),
           let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: TabDisplaySection.regularTabs.rawValue)) as? TabCell {

            cell.close()
            NotificationCenter.default.post(name: .UpdateLabelOnTabClosed, object: nil)
        }
    }

    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
}

// MARK: - TabDisplayCompeltionDelegate & RecentlyClosedPanelDelegate
extension GridTabViewController: TabDisplayCompletionDelegate, RecentlyClosedPanelDelegate {
    // RecentlyClosedPanelDelegate
    func openRecentlyClosedSiteInSameTab(_ url: URL) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .inactiveTabTray, value: .openRecentlyClosedTab, extras: nil)
        delegate?.tabTrayOpenRecentlyClosedTab(url)
        dismissTabTray()
    }

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .inactiveTabTray, value: .openRecentlyClosedTab, extras: nil)
        openNewTab(URLRequest(url: url), isPrivate: isPrivate)
        dismissTabTray()
    }

    // TabDisplayCompletionDelegate
    func completedAnimation(for type: TabAnimationType) {
        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()

        switch type {
        case .addTab:
            dismissTabTray()
        case .removedLastTab:
            // when removing the last tab (only in normal mode) we will automatically open a new tab.
            // When that happens focus it by dismissing the tab tray
            notificationCenter.post(name: .TabsTrayDidClose, object: nil)
            if !tabDisplayManager.isPrivate {
                self.dismissTabTray()
            }
        case .removedNonLastTab, .updateTab, .moveTab:
            break
        }
    }
}

extension GridTabViewController {
    func removeByButtonOrSwipe(tab: Tab, cell: TabCell) {
        tabDisplayManager.tabDisplayCompletionDelegate = self
        tabDisplayManager.closeActionPerformed(forCell: cell)
    }
}

// MARK: - Toolbar Actions
extension GridTabViewController {
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIBarButtonItem) {
        switch action {
        case .addTab:
            didTapToolbarAddTab()
        case .deleteTab:
            didTapToolbarDelete(sender)
        }
    }

    func didTapToolbarAddTab() {
        if tabDisplayManager.isDragging {
            return
        }
        openNewTab(isPrivate: tabDisplayManager.isPrivate)
    }

    func didTapToolbarDelete(_ sender: UIBarButtonItem) {
        if tabDisplayManager.isDragging {
            return
        }

        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: .AppMenu.AppMenuCloseAllTabsTitleString,
                                           style: .default,
                                           handler: { _ in self.closeTabsTrayBackground() }),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        controller.addAction(UIAlertAction(title: .TabTrayCloseAllTabsPromptCancel,
                                           style: .cancel,
                                           handler: nil),
                             accessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCancelButton)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true, completion: nil)
    }
}

// MARK: TabLayoutDelegate
private class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    weak var tabPeekDelegate: TabPeekDelegate?
    let scrollView: UIScrollView
    var lastYOffset: CGFloat = 0
    var tabDisplayManager: TabDisplayManager

    var sectionHeaderSize: CGSize {
        CGSize(width: 50, height: 40)
    }

    enum ScrollDirection {
        case up
        case down
    }

    fileprivate var scrollDirection: ScrollDirection = .down
    fileprivate var traitCollection: UITraitCollection
    fileprivate var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return GridTabTrayControllerUX.CompactNumberOfColumnsThin
        } else {
            return GridTabTrayControllerUX.NumberOfColumnsWide
        }
    }

    init(tabDisplayManager: TabDisplayManager, traitCollection: UITraitCollection, scrollView: UIScrollView) {
        self.tabDisplayManager = tabDisplayManager
        self.scrollView = scrollView
        self.traitCollection = traitCollection
        super.init()
    }

    fileprivate func cellHeightForCurrentDevice() -> CGFloat {
        let shortHeight = GridTabTrayControllerUX.TextBoxHeight * 6

        if self.traitCollection.verticalSizeClass == .compact {
            return shortHeight
        } else if self.traitCollection.horizontalSizeClass == .compact {
            return shortHeight
        } else {
            return GridTabTrayControllerUX.TextBoxHeight * 8
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch TabDisplaySection(rawValue: section) {
        case .regularTabs:
            if let groups = tabDisplayManager.tabGroups, !groups.isEmpty {
                return sectionHeaderSize
            }
        default: return .zero
        }

        return .zero
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    @objc func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return GridTabTrayControllerUX.Margin
    }

    @objc func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let margin = GridTabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)
        let calculatedWidth = collectionView.bounds.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right - margin
        let cellWidth = floor(calculatedWidth / CGFloat(numberOfColumns))
        switch TabDisplaySection(rawValue: indexPath.section) {
        case .inactiveTabs:
            return calculateInactiveTabSizeHelper(collectionView)

        case .groupedTabs:
            let width = collectionView.frame.size.width
            if let groupCount = tabDisplayManager.tabGroups?.count, groupCount > 0 {
                let height: CGFloat = GroupedTabCellProperties.CellUX.defaultCellHeight * CGFloat(groupCount)
                return CGSize(width: width >= 0 ? Int(width) : 0, height: Int(height))
            } else {
                return CGSize(width: 0, height: 0)
            }

        case .regularTabs, .none:
            guard tabDisplayManager.filteredTabs.count > 0 else { return CGSize(width: 0, height: 0) }
            return CGSize(width: cellWidth, height: self.cellHeightForCurrentDevice())
        }
    }

    private func calculateInactiveTabSizeHelper(_ collectionView: UICollectionView) -> CGSize {
        guard !tabDisplayManager.isPrivate,
              let inactiveTabViewModel = tabDisplayManager.inactiveViewModel,
              inactiveTabViewModel.activeTabs.count > 0
        else {
            return CGSize(width: 0, height: 0)
        }

        let closeAllButtonHeight = InactiveTabCell.UX.CloseAllTabRowHeight
        let headerHeightWithRoundedCorner = InactiveTabCell.UX.HeaderAndRowHeight + InactiveTabCell.UX.RoundedContainerPaddingClosed
        var totalHeight = headerHeightWithRoundedCorner
        let width: CGFloat = collectionView.frame.size.width - InactiveTabCell.UX.InactiveTabTrayWidthPadding
        let inactiveTabs = inactiveTabViewModel.inactiveTabs

        // Calculate height based on number of tabs in the inactive tab section section
        let calculatedInactiveTabsTotalHeight = (InactiveTabCell.UX.HeaderAndRowHeight * CGFloat(inactiveTabs.count)) +
        InactiveTabCell.UX.RoundedContainerPaddingClosed +
        InactiveTabCell.UX.RoundedContainerAdditionalPaddingOpened + closeAllButtonHeight

        totalHeight = tabDisplayManager.isInactiveViewExpanded ? calculatedInactiveTabsTotalHeight : headerHeightWithRoundedCorner

        if UIDevice.current.userInterfaceIdiom == .pad {
            return CGSize(width: collectionView.frame.size.width/1.5, height: totalHeight)
        } else {
            return CGSize(width: width >= 0 ? width : 0, height: totalHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch TabDisplaySection(rawValue: section) {
        case .regularTabs, .none:
            return UIEdgeInsets(
                top: GridTabTrayControllerUX.Margin,
                left: GridTabTrayControllerUX.Margin + collectionView.safeAreaInsets.left,
                bottom: GridTabTrayControllerUX.Margin,
                right: GridTabTrayControllerUX.Margin + collectionView.safeAreaInsets.right)

        case .inactiveTabs:
            guard !tabDisplayManager.isPrivate,
                  tabDisplayManager.inactiveViewModel?.inactiveTabs.count ?? 0 > 0
            else { return .zero }

            return UIEdgeInsets(equalInset: GridTabTrayControllerUX.Margin)

        case .groupedTabs:
            guard tabDisplayManager.shouldEnableGroupedTabs,
                  tabDisplayManager.tabGroups?.count ?? 0 > 0
            else { return .zero }

            return UIEdgeInsets(equalInset: GridTabTrayControllerUX.Margin)
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return GridTabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard TabDisplaySection(rawValue: indexPath.section) == .regularTabs,
              let tab = tabDisplayManager.dataStore.at(indexPath.row)
        else { return nil }

        let tabVC = TabPeekViewController(tab: tab, delegate: tabPeekDelegate)
        if let browserProfile = tabDisplayManager.profile as? BrowserProfile,
           let pickerDelegate = tabPeekDelegate as? DevicePickerViewControllerDelegate {
            tabVC.setState(withProfile: browserProfile, clientPickerDelegate: pickerDelegate)
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: { return tabVC }, actionProvider: tabVC.contextActions(defaultActions:))
    }
}

// MARK: - DevicePickerViewControllerDelegate
extension GridTabViewController: DevicePickerViewControllerDelegate {
    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        if let item = devicePickerViewController.shareItem {
            _ = self.profile.sendItem(item, toDevices: devices)
        }
        devicePickerViewController.dismiss(animated: true, completion: nil)
    }

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        devicePickerViewController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Presentation Delegates
extension GridTabViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension GridTabViewController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
        dismiss(animated: animated, completion: { self.collectionView.reloadData() })
    }
}

protocol TabCellDelegate: AnyObject {
    func tabCellDidClose(_ cell: TabCell)
}

// MARK: - NotificationThemable
extension GridTabViewController: NotificationThemeable {
    @objc func applyTheme() {
        webViewContainerBackdrop.backgroundColor = UIColor.Photon.Ink90
        collectionView.backgroundColor = UIColor.theme.tabTray.background
    }
}

// MARK: - Notifiable
extension GridTabViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            appWillResignActiveNotification()
        case UIApplication.didBecomeActiveNotification:
            appDidBecomeActiveNotification()
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

protocol InactiveTabsCFRProtocol {
    func setupCFR(with view: UILabel)
    func presentCFR()
}

// MARK: - Contextual Hint
extension GridTabViewController: InactiveTabsCFRProtocol {
    func setupCFR(with view: UILabel) {
        prepareJumpBackInContextualHint(on: view)
    }

    func presentCFR() {
        contextualHintViewController.startTimer()
    }

    func presentCFROnView() {
        present(contextualHintViewController, animated: true, completion: nil)
    }

    private func prepareJumpBackInContextualHint(on title: UILabel) {
        guard contextualHintViewController.shouldPresentHint() else { return }

        contextualHintViewController.configure(
            anchor: title,
            withArrowDirection: .up,
            andDelegate: self, presentedUsing: { self.presentCFROnView() },
            andActionForButton: {
                self.dismissTabTray()
                self.delegate?.tabTrayDidRequestTabsSettings()
            },
            andShouldStartTimerRightAway: false
        )
    }
}
