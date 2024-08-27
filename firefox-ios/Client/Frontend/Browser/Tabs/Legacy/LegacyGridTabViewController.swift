// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared
import Common

protocol TabTrayDelegate: AnyObject {
    func tabTrayDidDismiss(_ tabTray: LegacyGridTabViewController)
    func tabTrayDidAddTab(_ tabTray: LegacyGridTabViewController, tab: Tab)
    func tabTrayDidAddBookmark(_ tab: Tab)
    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListItem?
    func tabTrayOpenRecentlyClosedTab(_ url: URL)
    func tabTrayDidRequestTabsSettings()
    func tabTrayDidCloseLastTab(toast: ButtonToast)
}

class LegacyGridTabViewController: UIViewController,
                                   TabTrayViewDelegate,
                                   Themeable,
                                   EmptyPrivateTabsViewDelegate {
    struct UX {
        static let cornerRadius: CGFloat = 6
        static let textBoxHeight: CGFloat = 32
        static let faviconSize: CGFloat = 20
        static let margin: CGFloat = 15
        static let toolbarButtonOffset: CGFloat = 10
        static let closeButtonSize: CGFloat = 32
        static let closeButtonMargin: CGFloat = 6
        static let closeButtonEdgeInset: CGFloat = 7
        static let numberOfColumnsThin = 1
        static let numberOfColumnsWide = 3
        static let compactNumberOfColumnsThin = 2
        static let menuFixedWidth: CGFloat = 320
        static let undoToastDelay = DispatchTimeInterval.seconds(0)
        static let undoToastDuration = DispatchTimeInterval.seconds(3)
    }

    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?
    var tabDisplayManager: LegacyTabDisplayManager!
    var tabCellIdentifier: TabDisplayerDelegate.TabCellIdentifier = LegacyTabCell.cellIdentifier
    static let independentTabsHeaderIdentifier = "IndependentTabs"
    var otherBrowsingModeOffset = CGPoint.zero
    // Backdrop used for displaying greyed background for private tabs
    var backgroundPrivacyOverlay = UIView()
    var collectionView: UICollectionView!
    var notificationCenter: NotificationProtocol
    var contextualHintViewController: ContextualHintViewController
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var shownToast: Toast?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var toolbarHeight: CGFloat {
        return !shouldUseiPadSetup() ? view.safeAreaInsets.bottom : 0
    }

    // This is an optional variable used if we wish to focus a tab that is not the
    // currently selected tab. This allows us to force the scroll behaviour to move
    // wherever we need to focus the user's attention.
    var tabToFocus: Tab?

    private var privateTabsAreEmpty: Bool {
        return tabDisplayManager.isPrivate && tabManager.privateTabs.isEmpty
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.delegate = self
        return emptyView
    }()

    private lazy var tabLayoutDelegate: LegacyTabLayoutDelegate = {
        let delegate = LegacyTabLayoutDelegate(tabDisplayManager: self.tabDisplayManager,
                                               traitCollection: self.traitCollection)
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
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.tabManager = tabManager
        self.windowUUID = tabManager.windowUUID
        self.profile = profile
        self.delegate = tabTrayDelegate
        self.tabToFocus = tabToFocus
        self.notificationCenter = notificationCenter

        let contextualViewProvider = ContextualHintViewProvider(forHintType: .inactiveTabs,
                                                                with: profile)
        self.contextualHintViewController = ContextualHintViewController(with: contextualViewProvider,
                                                                         windowUUID: tabManager.windowUUID)
        self.themeManager = themeManager

        super.init(nibName: nil, bundle: nil)
        collectionViewSetup()
    }

    private func collectionViewSetup() {
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(cellType: LegacyTabCell.self)
        collectionView.register(cellType: LegacyInactiveTabCell.self)
        collectionView.register(
            LabelButtonHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: LegacyGridTabViewController.independentTabsHeaderIdentifier)
        tabDisplayManager = LegacyTabDisplayManager(collectionView: collectionView,
                                                    tabManager: tabManager,
                                                    tabDisplayer: self,
                                                    reuseID: LegacyTabCell.cellIdentifier,
                                                    tabDisplayType: .TabGrid,
                                                    profile: profile,
                                                    cfrDelegate: self,
                                                    theme: currentTheme())
        collectionView.dataSource = tabDisplayManager
        collectionView.delegate = tabLayoutDelegate

        tabDisplayManager.tabDisplayCompletionDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityLabel = .TabTrayViewAccessibilityLabel

        backgroundPrivacyOverlay.alpha = 0

        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag

        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = tabDisplayManager
        collectionView.dropDelegate = tabDisplayManager

        setupView()

        if let tab = tabManager.selectedTab, tab.isPrivate {
            tabDisplayManager.togglePrivateMode(isOn: true, createTabOnEmptyPrivateMode: false)
        }

        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty

        listenForThemeChange(view)
        applyTheme()

        setupNotifications(forObserver: self, observing: [
            UIApplication.willResignActiveNotification,
            UIApplication.didBecomeActiveNotification
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.focusItem()
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    private func setupView() {
        // TODO: Remove SNAPKIT - this will require some work as the layouts
        // are using other snapkit constraints and this will require modification
        // in several places.
        [backgroundPrivacyOverlay, collectionView].forEach { view.addSubview($0) }
        setupConstraints()

        view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(self.collectionView)
        }
    }

    private func setupConstraints() {
        backgroundPrivacyOverlay.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // When the app enters split screen mode we refresh the collection view layout to show the proper grid
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.invalidateLayout()
    }

    private func tabManagerTeardown() {
        tabManager.removeDelegate(tabDisplayManager)
        tabDisplayManager = nil
        contextualHintViewController.stopTimer()
        notificationCenter.removeObserver(self)
    }

    deinit {
        tabManagerTeardown()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scrolling helper methods
    /// The main interface for scrolling to an item, whether that is a group or an individual tab
    ///
    /// This method checks for the existence of a tab to focus on other than the selected tab,
    /// and then focuses on that tab.
    func focusItem() {
        guard let selectedTab = tabManager.selectedTab else { return }
        if tabToFocus == nil { tabToFocus = selectedTab }

        guard let tabToFocus = tabToFocus else { return }
        focusTab(tabToFocus)
    }

    func focusTab(_ selectedTab: Tab) {
        if let indexOfRegularTab = tabDisplayManager.indexOfRegularTab(tab: selectedTab) {
            let indexPath = IndexPath(item: indexOfRegularTab, section: TabDisplaySection.regularTabs.rawValue)
            guard var rect = self.collectionView.layoutAttributesForItem(at: indexPath)?.frame else { return }
            if indexOfRegularTab >= self.tabDisplayManager.dataStore.count - 2 {
                rect.origin.y += 10
                self.collectionView.scrollRectToVisible(rect, animated: false)
            } else {
                self.collectionView.scrollToItem(at: indexPath,
                                                 at: [.centeredVertically, .centeredHorizontally],
                                                 animated: false)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
    }

    @objc
    func didTogglePrivateMode() {
        tabManager.willSwitchTabMode(leavingPBM: tabDisplayManager.isPrivate)

        tabDisplayManager.togglePrivateMode(
            isOn: !tabDisplayManager.isPrivate,
            createTabOnEmptyPrivateMode: false
        )

        emptyPrivateTabsView.alpha = 0.0
        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty
        if privateTabsAreEmpty {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.emptyPrivateTabsView.alpha = 1.0
            }
        }
    }

    func openNewTab(_ request: URLRequest? = nil, isPrivate: Bool) {
        guard !tabDisplayManager.isDragging else { return }

        // Ensure Firefox home page is refreshed if privacy mode was changed
        if tabManager.selectedTab?.isPrivate != isPrivate {
            let notificationObject = [Tab.privateModeKey: isPrivate]
            NotificationCenter.default.post(name: .TabsPrivacyModeChanged,
                                            object: notificationObject,
                                            userInfo: windowUUID.userInfo)
        }
        if isPrivate {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .privateBrowsingIcon,
                                         value: .tabTray,
                                         extras: [TelemetryWrapper.EventExtraKey.action.rawValue: "add"] )
        }
        tabManager.selectTab(tabManager.addTab(request, isPrivate: isPrivate))
    }

    func applyTheme() {
        tabDisplayManager.theme = currentTheme()
        emptyPrivateTabsView.applyTheme(currentTheme())
        backgroundPrivacyOverlay.backgroundColor = currentTheme().colors.layerScrim
        collectionView.backgroundColor = currentTheme().colors.layer3
        collectionView.reloadData()
    }

    // MARK: EmptyPrivateTabsViewDelegate
    func didTapLearnMore(urlRequest: URLRequest) {
        openNewTab(urlRequest,
                   isPrivate: tabDisplayManager.isPrivate)
    }

    func closeTabsTrayBackground() {
        tabDisplayManager.removeAllTabsFromView()

        tabManager.backgroundRemoveAllTabs(
            isPrivate: tabDisplayManager.isPrivate
        ) { recentlyClosedTabs, isPrivateState, previousTabUUID in
            DispatchQueue.main.async { [unowned self] in
                if isPrivateState {
                    let previousTab = self.tabManager.tabs.first(where: { $0.tabUUID == previousTabUUID })
                    self.tabManager.cleanupClosedTabs(recentlyClosedTabs,
                                                      previous: previousTab,
                                                      isPrivate: isPrivateState)

                    presentToastForClosingAllTabs(
                        recentlyClosedTabs: recentlyClosedTabs,
                        previousTabUUID: previousTabUUID,
                        isPrivate: isPrivateState
                    )

                    TelemetryWrapper.recordEvent(
                        category: .action,
                        method: .tap,
                        object: .privateBrowsingIcon,
                        value: .tabTray,
                        extras: [TelemetryWrapper.EventExtraKey.action.rawValue: "close_all_tabs"]
                    )
                } else {
                    self.tabManager.makeToastFromRecentlyClosedUrls(recentlyClosedTabs,
                                                                    isPrivate: isPrivateState,
                                                                    previousTabUUID: previousTabUUID)
                }
                closeTabsTrayHelper()
            }
        }
    }

    private func presentToastForClosingAllTabs(recentlyClosedTabs: [Tab], previousTabUUID: TabUUID, isPrivate: Bool) {
        self.presentUndoToast(tabsCount: recentlyClosedTabs.count) { [weak self] undoButtonPressed in
            guard undoButtonPressed else { return }
            self?.tabManager.undoCloseAllTabsLegacy(
                recentlyClosedTabs: recentlyClosedTabs,
                previousTabUUID: previousTabUUID,
                isPrivate: isPrivate
            )
        }
    }

    func closeTabsTrayHelper() {
        if tabDisplayManager.isPrivate {
            emptyPrivateTabsView.isHidden = !privateTabsAreEmpty
            if !emptyPrivateTabsView.isHidden {
                // Fade in the empty private tabs message. This slow fade allows time for the
                // closing tab animations to complete.
                emptyPrivateTabsView.alpha = 0
                UIView.animate(
                    withDuration: 0.5,
                    animations: { [weak self] in
                        self?.emptyPrivateTabsView.alpha = 1
                    })
            }
        } else if tabManager.normalTabs.count == 1,
                  let tab = tabManager.normalTabs.first {
            tabManager.selectTab(tab)
            dismissTabTray()
            notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
        }
    }

    func didTogglePrivateMode(_ togglePrivateModeOn: Bool) {
        if togglePrivateModeOn != tabDisplayManager.isPrivate {
            didTogglePrivateMode()
        }
    }

    func dismissTabTray() {
        DispatchQueue.main.async {
            self.navigationController?.dismiss(animated: true, completion: nil)
            TelemetryWrapper.recordEvent(category: .action, method: .close, object: .tabTray)
        }
    }

    /// Handles close tab by clicking on close button or swipe gesture
    func closeTabAction(tab: Tab, cell: LegacyTabCell) {
        tabManager.backupCloseTab = BackupCloseTab(
            tab: tab,
            restorePosition: tabManager.tabs.firstIndex(of: tab),
            isSelected: tabManager.selectedTab?.tabUUID == tab.tabUUID)
        tabDisplayManager.tabDisplayCompletionDelegate = self
        tabDisplayManager.performCloseAction(for: tab)

        // Handles case for last tab where Toast is shown on Homepage
        guard !tabDisplayManager.shouldPresentUndoToastOnHomepage else {
            handleUndoToastForLastTab()
            return
        }

        presentUndoToast(toastType: .closedSingleTab) { [weak self] undoButtonPressed in
            guard let self,
                  undoButtonPressed,
                  let closedTab = self.tabManager.backupCloseTab else { return }

            self.tabDisplayManager.undoCloseTab(tab: closedTab.tab, index: closedTab.restorePosition)
            NotificationCenter.default.post(name: .UpdateLabelOnTabClosed,
                                            object: nil,
                                            userInfo: windowUUID.userInfo)

            if self.tabDisplayManager.isPrivate {
                self.emptyPrivateTabsView.isHidden = !self.privateTabsAreEmpty
            }
        }
    }

    private func handleUndoToastForLastTab() {
        let viewModel = ButtonToastViewModel(
            labelText: .TabsTray.CloseTabsToast.SingleTabTitle,
            buttonText: .TabsTray.CloseTabsToast.Action)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: currentTheme(),
                                completion: { [weak self]  undoButtonPressed in
            guard undoButtonPressed, let closedTab = self?.tabManager.backupCloseTab else { return }

            self?.tabDisplayManager.undoCloseTab(tab: closedTab.tab,
                                                 index: closedTab.restorePosition)
        })
        delegate?.tabTrayDidCloseLastTab(toast: toast)
    }

    private func presentUndoToast(toastType: ToastType,
                                  completion: @escaping (Bool) -> Void) {
        if let currentToast = shownToast {
            currentToast.dismiss(false)
        }

        let viewModel = ButtonToastViewModel(
            labelText: toastType.title,
            buttonText: toastType.buttonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: currentTheme(),
                                completion: { buttonPressed in
            completion(buttonPressed)
        })

        toast.showToast(viewController: self,
                        delay: UX.undoToastDelay,
                        duration: UX.undoToastDuration) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                toast.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                toast.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                              constant: -self.toolbarHeight)
            ]
        }
        shownToast = toast
    }
}

// MARK: - TabDisplayer
extension LegacyGridTabViewController: TabDisplayerDelegate {
    func focusSelectedTab() {
        self.focusItem()
    }

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? LegacyTabCell else { return cell }
        tabCell.animator?.delegate = self
        tabCell.delegate = self
        let selected = tab == tabManager.selectedTab
        tabCell.configureLegacyCellWith(tab: tab, isSelected: selected, theme: currentTheme())
        return tabCell
    }
}

// MARK: - App Notifications
extension LegacyGridTabViewController {
    @objc
    func appWillResignActiveNotification() {
        if tabDisplayManager.isPrivate && !tabManager.privateTabs.isEmpty {
            backgroundPrivacyOverlay.alpha = 1
            view.bringSubviewToFront(backgroundPrivacyOverlay)
            collectionView.alpha = 0
            emptyPrivateTabsView.alpha = 0
        }
    }

    @objc
    func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(
            withDuration: 0.2,
            animations: { [weak self] in
                self?.collectionView.alpha = 1
                self?.emptyPrivateTabsView.alpha = 1
            }
        ) { [weak self] _ in
            guard let self else { return }
            self.backgroundPrivacyOverlay.alpha = 0
            self.view.sendSubviewToBack(self.backgroundPrivacyOverlay)
        }
    }
}

// MARK: - TabSelectionDelegate
extension LegacyGridTabViewController: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        if let tab = tabDisplayManager.dataStore.at(index) {
            if tab.isFxHomeTab {
                notificationCenter.post(name: .TabsTrayDidSelectHomeTab, withUserInfo: windowUUID.userInfo)
            }
            tabManager.selectTab(tab)
            dismissTabTray()
        }
    }
}

// MARK: UIScrollViewAccessibilityDelegate
extension LegacyGridTabViewController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
        guard var visibleCells = collectionView.visibleCells as? [LegacyTabCell] else { return nil }
        var bounds = collectionView.bounds
        bounds = bounds.offsetBy(dx: collectionView.contentInset.left,
                                 dy: collectionView.contentInset.top)
        bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
        bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
        // visible cells do sometimes return also not visible cells when attempting to go past the last cell
        // with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
        visibleCells = visibleCells.filter { !$0.frame.intersection(bounds).isEmpty }

        let cells = visibleCells.map { self.collectionView.indexPath(for: $0)! }
        let indexPaths = cells.sorted { (first: IndexPath, second: IndexPath) -> Bool in
            return first.section < second.section || (first.section == second.section && first.row < second.row)
        }

        guard !indexPaths.isEmpty else {
            return .TabTrayNoTabsAccessibilityHint
        }

        let firstTab = indexPaths.first!.row + 1
        let lastTab = indexPaths.last!.row + 1
        let tabCount = collectionView.numberOfItems(inSection: 1)

        if firstTab == lastTab {
            let format: String = .TabTrayVisibleTabRangeAccessibilityHint
            return String(
                format: format,
                NSNumber(value: firstTab as Int),
                NSNumber(value: tabCount as Int)
            )
        } else {
            let format: String = .TabTrayVisiblePartialRangeAccessibilityHint
            return String(
                format: format,
                NSNumber(value: firstTab as Int),
                NSNumber(value: lastTab as Int),
                NSNumber(value: tabCount as Int)
            )
        }
    }
}

// MARK: - SwipeAnimatorDelegate
extension LegacyGridTabViewController: SwipeAnimatorDelegate {
    func swipeAnimator(_ animator: SwipeAnimator) {
        guard let tabCell = animator.animatingView as? LegacyTabCell,
              let indexPath = collectionView.indexPath(for: tabCell) else { return }
        if let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            self.closeTabAction(tab: tab, cell: tabCell)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement,
                                 argument: String.TabTrayClosingTabAccessibilityMessage)
        }
    }

    // Disable swipe delete while drag reordering
    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool {
        return !tabDisplayManager.isDragging
    }
}

// MARK: - TabCellDelegate
extension LegacyGridTabViewController: LegacyTabCellDelegate {
    func tabCellDidClose(_ cell: LegacyTabCell) {
        if let indexPath = collectionView.indexPath(for: cell),
           let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            closeTabAction(tab: tab, cell: cell)
        }
    }
}

// MARK: - LegacyTabPeekDelegate
extension LegacyGridTabViewController: LegacyTabPeekDelegate {
    func tabPeekDidAddBookmark(_ tab: Tab) {
        delegate?.tabTrayDidAddBookmark(tab)
    }

    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? {
        return delegate?.tabTrayDidAddToReadingList(tab)
    }

    func tabPeekDidCloseTab(_ tab: Tab) {
        // Tab peek is only available on regular tabs
        if let index = tabDisplayManager.dataStore.index(of: tab),
           let cell = self.collectionView?.cellForItem(
            at: IndexPath(item: index, section: TabDisplaySection.regularTabs.rawValue)
           ) as? LegacyTabCell {
            cell.close()
        }
    }

    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }

    func tabPeekDidCopyUrl() {
        SimpleToast().showAlertWithText(.LegacyAppMenu.AppMenuCopyURLConfirmMessage,
                                        bottomContainer: view,
                                        theme: currentTheme(),
                                        bottomConstraintPadding: -toolbarHeight)
    }
}

// MARK: - TabDisplayCompletionDelegate & RecentlyClosedPanelDelegate
extension LegacyGridTabViewController: TabDisplayCompletionDelegate, RecentlyClosedPanelDelegate {
    // RecentlyClosedPanelDelegate
    func openRecentlyClosedSiteInSameTab(_ url: URL) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .inactiveTabTray,
                                     value: .openRecentlyClosedTab,
                                     extras: nil)
        delegate?.tabTrayOpenRecentlyClosedTab(url)
        dismissTabTray()
    }

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .inactiveTabTray,
                                     value: .openRecentlyClosedTab,
                                     extras: nil)
        openNewTab(URLRequest(url: url), isPrivate: isPrivate)
        dismissTabTray()
    }

    // TabDisplayCompletionDelegate
    func completedAnimation(for type: TabAnimationType) {
        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty

        switch type {
        case .addTab:
            dismissTabTray()
        case .removedLastTab:
            // when removing the last tab (only in normal mode) we will automatically open a new tab.
            // When that happens focus it by dismissing the tab tray
            notificationCenter.post(name: .TabsTrayDidClose, withUserInfo: windowUUID.userInfo)
            if !tabDisplayManager.isPrivate {
                self.dismissTabTray()
            }
        case .removedNonLastTab, .updateTab, .moveTab:
            break
        }
    }
}

// MARK: - Toolbar Actions
extension LegacyGridTabViewController {
    func performToolbarAction(_ action: TabTrayViewAction, sender: UIBarButtonItem) {
        switch action {
        case .addTab:
            didTapToolbarAddTab()
        case .deleteTab:
            didTapToolbarDelete(sender)
        }
        notificationCenter.post(name: .TabDataUpdated, withUserInfo: windowUUID.userInfo)
    }

    func didTapToolbarAddTab() {
        if tabDisplayManager.isDragging {
            return
        }
        openNewTab(isPrivate: tabDisplayManager.isPrivate)
    }

    func didTapToolbarDelete(_ sender: UIBarButtonItem) {
        guard !tabDisplayManager.isDragging else { return }

        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: .LegacyAppMenu.AppMenuCloseAllTabsTitleString,
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

// MARK: - DevicePickerViewControllerDelegate
extension LegacyGridTabViewController: DevicePickerViewControllerDelegate {
    func devicePickerViewController(
        _ devicePickerViewController: DevicePickerViewController,
        didPickDevices devices: [RemoteDevice]
    ) {
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
extension LegacyGridTabViewController: UIAdaptivePresentationControllerDelegate,
                                       UIPopoverPresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Notifiable
extension LegacyGridTabViewController: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            appWillResignActiveNotification()
        case UIApplication.didBecomeActiveNotification:
            appDidBecomeActiveNotification()
        default: break
        }
    }
}

// MARK: - Contextual Hint and Toast
extension LegacyGridTabViewController: InactiveTabsCFRProtocol {
    func setupCFR(with view: UILabel) {
        prepareJumpBackInContextualHint(on: view)
    }

    func presentCFR() {
        contextualHintViewController.startTimer()
    }

    func presentCFROnView() {
        present(contextualHintViewController, animated: true, completion: nil)

        UIAccessibility.post(notification: .layoutChanged, argument: contextualHintViewController)
    }

    func presentUndoToast(tabsCount: Int, completion: @escaping (Bool) -> Void) {
        presentUndoToast(toastType: .closedAllInactiveTabs(count: tabsCount),
                         completion: completion)
    }

    func presentUndoSingleToast(completion: @escaping (Bool) -> Void) {
        presentUndoToast(toastType: .closedSingleTab, completion: completion)
    }

    private func prepareJumpBackInContextualHint(on title: UILabel) {
        guard contextualHintViewController.shouldPresentHint() else { return }

        contextualHintViewController.configure(
            anchor: title,
            withArrowDirection: .up,
            andDelegate: self,
            presentedUsing: { self.presentCFROnView() },
            andActionForButton: { [weak self] in
                self?.dismissTabTray()
                self?.delegate?.tabTrayDidRequestTabsSettings()
            }, andShouldStartTimerRightAway: false
        )
    }
}
