/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Storage
import Shared

struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(6.0)
    static let TextBoxHeight = CGFloat(32.0)
    static let SearchBarHeight = CGFloat(64)
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

struct PrivateModeStrings {
    static let toggleAccessibilityLabel = NSLocalizedString("Private Mode", tableName: "PrivateBrowsing", comment: "Accessibility label for toggling on/off private mode")
    static let toggleAccessibilityHint = NSLocalizedString("Turns private mode on or off", tableName: "PrivateBrowsing", comment: "Accessiblity hint for toggling on/off private mode")
    static let toggleAccessibilityValueOn = NSLocalizedString("On", tableName: "PrivateBrowsing", comment: "Toggled ON accessibility value")
    static let toggleAccessibilityValueOff = NSLocalizedString("Off", tableName: "PrivateBrowsing", comment: "Toggled OFF accessibility value")
}

protocol TabTrayDelegate: AnyObject {
    func tabTrayDidDismiss(_ tabTray: TabTrayControllerV1)
    func tabTrayDidAddTab(_ tabTray: TabTrayControllerV1, tab: Tab)
    func tabTrayDidAddBookmark(_ tab: Tab)
    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListItem?
    func tabTrayRequestsPresentationOf(_ viewController: UIViewController)
}

class TabTrayControllerV1: UIViewController {
    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?
    var tabDisplayManager: TabDisplayManager!
    var tabCellIdentifer: TabDisplayer.TabCellIdentifer = TabCell.Identifier
    var otherBrowsingModeOffset = CGPoint.zero
    // Backdrop used for displaying greyed background for private tabs
    var webViewContainerBackdrop: UIView!
    var collectionView: UICollectionView!

    let statusBarBG = UIView()
    lazy var toolbar: TrayToolbar = {
        let toolbar = TrayToolbar()
        toolbar.addTabButton.addTarget(self, action: #selector(didTapToolbarAddTab), for: .touchUpInside)
        toolbar.maskButton.addTarget(self, action: #selector(didTogglePrivateMode), for: .touchUpInside)
        toolbar.deleteButton.addTarget(self, action: #selector(didTapToolbarDelete), for: .touchUpInside)
        return toolbar
    }()

    lazy var searchBar: SearchBarTextField = {
        let searchBar = SearchBarTextField()
        searchBar.backgroundColor = UIColor.theme.tabTray.searchBackground
        searchBar.leftView = UIImageView(image: UIImage(named: "quickSearch"))
        searchBar.leftViewMode = .unlessEditing
        searchBar.textColor = UIColor.theme.tabTray.tabTitleText
        searchBar.attributedPlaceholder = NSAttributedString(string: Strings.TabSearchPlaceholderText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tabTray.tabTitleText.withAlphaComponent(0.7)])
        searchBar.clearButtonMode = .never
        searchBar.delegate = self
        searchBar.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        return searchBar
    }()

    var searchBarHolder = UIView()

    var roundedSearchBarHolder: UIView = {
        let roundedView = UIView()
        roundedView.backgroundColor = UIColor.theme.tabTray.searchBackground
        roundedView.layer.cornerRadius = 4
        roundedView.layer.masksToBounds = true
        return roundedView
    }()

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setImage(UIImage.templateImageNamed("close-medium"), for: .normal)
        cancelButton.addTarget(self, action: #selector(didPressCancel), for: .touchUpInside)
        cancelButton.tintColor = UIColor.theme.tabTray.tabTitleText
        cancelButton.isHidden = true
        return cancelButton
    }()

    fileprivate lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.learnMoreButton.addTarget(self, action: #selector(didTapLearnMore), for: .touchUpInside)
        return emptyView
    }()

    fileprivate lazy var tabLayoutDelegate: TabLayoutDelegate = {
        let delegate = TabLayoutDelegate(profile: self.profile, traitCollection: self.traitCollection, scrollView: self.collectionView)
        delegate.tabSelectionDelegate = self
        return delegate
    }()

    var numberOfColumns: Int {
        return tabLayoutDelegate.numberOfColumns
    }

    init(tabManager: TabManager, profile: Profile, tabTrayDelegate: TabTrayDelegate? = nil) {
        self.tabManager = tabManager
        self.profile = profile
        self.delegate = tabTrayDelegate

        super.init(nibName: nil, bundle: nil)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        tabDisplayManager = TabDisplayManager(collectionView: self.collectionView, tabManager: self.tabManager, tabDisplayer: self, reuseID: TabCell.Identifier)
        collectionView.dataSource = tabDisplayManager
        collectionView.delegate = tabLayoutDelegate
        collectionView.contentInset = UIEdgeInsets(top: TabTrayControllerUX.SearchBarHeight, left: 0, bottom: 0, right: 0)

        // these will be animated during view show/hide transition
        statusBarBG.alpha = 0
        searchBarHolder.alpha = 0

        tabDisplayManager.tabDisplayCompletionDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.layoutIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // When the app enters split screen mode we refresh the collection view layout to show the proper grid
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    deinit {
        tabManager.removeDelegate(self.tabDisplayManager)
        tabManager.removeDelegate(self)
        tabDisplayManager = nil
    }
    
    func focusTab() {
        guard let currentTab = tabManager.selectedTab, let index = self.tabDisplayManager.dataStore.index(of: currentTab), let rect = self.collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame else {
            return
        }
        self.collectionView.scrollRectToVisible(rect, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }
    }

// MARK: View Controller Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        tabManager.addDelegate(self)
        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
        
        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.Photon.Ink90
        webViewContainerBackdrop.alpha = 0

        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = UIColor.theme.tabTray.background
        collectionView.keyboardDismissMode = .onDrag

        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = tabDisplayManager
        collectionView.dropDelegate = tabDisplayManager

        searchBarHolder.addSubview(roundedSearchBarHolder)
        searchBarHolder.addSubview(searchBar)
        searchBarHolder.backgroundColor = UIColor.theme.tabTray.toolbar
        [webViewContainerBackdrop, collectionView, toolbar, searchBarHolder, cancelButton].forEach { view.addSubview($0) }
        makeConstraints()

        // The statusBar needs a background color
        statusBarBG.backgroundColor = UIColor.theme.tabTray.toolbar
        view.addSubview(statusBarBG)
        statusBarBG.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.view)
            make.bottom.equalTo(self.view.safeArea.top)
        }

        view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.collectionView)
            make.bottom.equalTo(self.toolbar.snp.top)
        }

        if let tab = tabManager.selectedTab, tab.isPrivate {
            tabDisplayManager.togglePrivateMode(isOn: true, createTabOnEmptyPrivateMode: false)
            toolbar.applyUIMode(isPrivate: true)
            searchBar.applyUIMode(isPrivate: true)
        }

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()

        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        //special case for iPad
        if UIDevice.current.userInterfaceIdiom == .pad && ThemeManager.instance.currentName == .normal {
            return .default
        }
        return ThemeManager.instance.statusBarStyle
    }

    fileprivate func makeConstraints() {
        
        webViewContainerBackdrop.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        collectionView.snp.makeConstraints { make in
            make.left.equalTo(view.safeArea.left)
            make.right.equalTo(view.safeArea.right)
            make.bottom.equalTo(toolbar.snp.top)
            make.top.equalTo(self.view.safeArea.top)
        }

        toolbar.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }
        cancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.roundedSearchBarHolder.snp.centerY)
            make.trailing.equalTo(self.roundedSearchBarHolder.snp.trailing).offset(-8)
        }

        searchBarHolder.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leading)
            make.trailing.equalTo(view.snp.trailing)
            make.height.equalTo(TabTrayControllerUX.SearchBarHeight)
            self.tabLayoutDelegate.searchHeightConstraint = make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.top).constraint
        }

        roundedSearchBarHolder.snp.makeConstraints { make in
            make.top.equalTo(searchBarHolder).offset(15)
            make.leading.equalTo(view.safeArea.leading).offset(10) // we can just make the nested view conform to the safe area
            make.trailing.equalTo(view.safeArea.trailing).offset(-10)
            make.bottom.equalTo(searchBarHolder).offset(-10)
        }

        searchBar.snp.makeConstraints { make in
            make.edges.equalTo(roundedSearchBarHolder).inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        }
    }

    @objc func didTogglePrivateMode() {
        if tabDisplayManager.isDragging {
            return
        }
        toolbar.isUserInteractionEnabled = false

        let scaleDownTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        let newOffset = CGPoint(x: 0.0, y: collectionView.contentOffset.y)
        if self.otherBrowsingModeOffset.y > 0 {
            collectionView.setContentOffset(self.otherBrowsingModeOffset, animated: false)
        }
        self.otherBrowsingModeOffset = newOffset
        let fromView: UIView
        if !privateTabsAreEmpty(), let snapshot = collectionView.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = collectionView.frame
            view.insertSubview(snapshot, aboveSubview: collectionView)
            fromView = snapshot
        } else {
            fromView = emptyPrivateTabsView
        }

        tabManager.willSwitchTabMode(leavingPBM: tabDisplayManager.isPrivate)
        
        tabDisplayManager.togglePrivateMode(isOn: !tabDisplayManager.isPrivate, createTabOnEmptyPrivateMode: false)
        
        if tabDisplayManager.isPrivate, privateTabsAreEmpty() {
            UIView.animate(withDuration: 0.2) {
                self.searchBarHolder.alpha = 0
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.searchBarHolder.alpha = 1
            }
        }

        if tabDisplayManager.searchActive {
            self.didPressCancel()
        } else {
            self.tabDisplayManager.refreshStore()
        }

        // If we are exiting private mode and we have the close private tabs option selected, make sure
        // we clear out all of the private tabs
        let exitingPrivateMode = !tabDisplayManager.isPrivate && tabManager.shouldClearPrivateTabs()

        toolbar.maskButton.setSelected(tabDisplayManager.isPrivate, animated: true)
        collectionView.layoutSubviews()

        let toView: UIView
        if !privateTabsAreEmpty(), let newSnapshot = collectionView.snapshotView(afterScreenUpdates: !exitingPrivateMode) {
            emptyPrivateTabsView.isHidden = true
            //when exiting private mode don't screenshot the collectionview (causes the UI to hang)
            newSnapshot.frame = collectionView.frame
            view.insertSubview(newSnapshot, aboveSubview: fromView)
            collectionView.alpha = 0
            toView = newSnapshot
        } else {
            emptyPrivateTabsView.isHidden = false
            toView = emptyPrivateTabsView
        }
        toView.alpha = 0
        toView.transform = scaleDownTransform

        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
            fromView.transform = scaleDownTransform
            fromView.alpha = 0
            toView.transform = .identity
            toView.alpha = 1
        }) { finished in
            if fromView != self.emptyPrivateTabsView {
                fromView.removeFromSuperview()
            }
            if toView != self.emptyPrivateTabsView {
                toView.removeFromSuperview()
            }
            self.collectionView.alpha = 1
            self.toolbar.isUserInteractionEnabled = true

            // A final reload to ensure no animations happen while completing the transition.
            self.tabDisplayManager.refreshStore()
        }

        toolbar.applyUIMode(isPrivate: tabDisplayManager.isPrivate)
        searchBar.applyUIMode(isPrivate: tabDisplayManager.isPrivate)

        if let search = searchBar.text, !search.isEmpty {
            searchTabs(for: search)
        }
    }

    fileprivate func privateTabsAreEmpty() -> Bool {
        return tabDisplayManager.isPrivate && tabManager.privateTabs.isEmpty
    }

    @objc func didTapToolbarAddTab() {
        if tabDisplayManager.isDragging {
            return
        }
        openNewTab()
    }

    func openNewTab(_ request: URLRequest? = nil) {
        if tabDisplayManager.isDragging {
            return
        }
        // We dismiss the tab tray once we are done. So no need to re-enable the toolbar
        toolbar.isUserInteractionEnabled = false

        tabManager.selectTab(tabManager.addTab(request, isPrivate: tabDisplayManager.isPrivate))
    }
}

extension TabTrayControllerV1: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        if tabDisplayManager.isPrivate, privateTabsAreEmpty() {
            UIView.animate(withDuration: 0.2) {
                self.searchBarHolder.alpha = 0
            }
        }
    }
   
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        self.emptyPrivateTabsView.isHidden = !self.privateTabsAreEmpty()
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        if tabDisplayManager.isPrivate {
            UIView.animate(withDuration: 0.2) {
                self.searchBarHolder.alpha = 1
            }
        }
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        // No need to handle removeAll toast in TabTray.
        // When closing all normal tabs we automatically focus a tab and show the BVC. Which will handle the Toast.
        // We don't show the removeAll toast in PBM
    }
}

extension TabTrayControllerV1: UITextFieldDelegate {

    @objc func didPressCancel() {
        clearSearch()
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.isHidden = true
        }
        self.searchBar.resignFirstResponder()
    }

    @objc func textDidChange(textField: UITextField) {
        guard let text = textField.text, !text.isEmpty else {
            clearSearch()
            return
        }

        searchTabs(for: text)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.isHidden = false
        }
    }

    func searchTabs(for searchString: String) {
        let currentTabs = self.tabDisplayManager.isPrivate ? self.tabManager.privateTabs : self.tabManager.normalTabs
        let filteredTabs = currentTabs.filter { tab in
            if let url = tab.url, InternalURL.isValid(url: url) {
                return false
            }
            let title = tab.title ?? tab.lastTitle
            if title?.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            if tab.url?.absoluteString.lowercased().range(of: searchString.lowercased()) != nil {
                return true
            }
            return false
        }
        tabDisplayManager.searchedTabs = filteredTabs

        tabDisplayManager.searchTabsAnimated()
        
        TelemetryWrapper.recordEvent(category: .action, method: .press, object: .tabSearch)
    }

    func clearSearch() {
        tabDisplayManager.searchedTabs = nil
        searchBar.text = ""
        // Use evenIfHidden to workaround a refresh bug (#4969)
        tabDisplayManager.refreshStore(evenIfHidden: true)
    }
}

extension TabTrayControllerV1: TabDisplayer {

    func focusSelectedTab() {
        self.focusTab()
    }

    func cellFactory(for cell: UICollectionViewCell, using tab: Tab) -> UICollectionViewCell {
        guard let tabCell = cell as? TabCell else { return cell }
        tabCell.animator.delegate = self
        tabCell.delegate = self
        let selected = tab == tabManager.selectedTab
        tabCell.configureWith(tab: tab, is: selected)
        return tabCell
    }
}

extension TabTrayControllerV1 {

    @objc func didTapLearnMore() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let langID = Locale.preferredLanguages.first {
            let learnMoreRequest = URLRequest(url: "https://support.mozilla.org/1/mobile/\(appVersion ?? "0.0")/iOS/\(langID)/private-browsing-ios".asURL!)
            openNewTab(learnMoreRequest)
        }
    }

    func closeTabsForCurrentTray() {
        tabDisplayManager.hideDisplayedTabs() {
            self.tabManager.removeTabsWithUndoToast(self.tabDisplayManager.dataStore.compactMap { $0 })
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
            }
        }
    }

    func changePrivacyMode(_ isPrivate: Bool) {
        if isPrivate != tabDisplayManager.isPrivate {
            didTogglePrivateMode()
        }
    }

    func dismissTabTray() {
        collectionView.layer.removeAllAnimations()
        collectionView.cellForItem(at: IndexPath(row: 0, section: 0))?.layer.removeAllAnimations()
        _ = self.navigationController?.popViewController(animated: true)
    }

}

// MARK: - App Notifications
extension TabTrayControllerV1 {
    @objc func appWillResignActiveNotification() {
        if tabDisplayManager.isPrivate {
            webViewContainerBackdrop.alpha = 1
            view.bringSubviewToFront(webViewContainerBackdrop)
            collectionView.alpha = 0
            searchBarHolder.alpha = 0
            emptyPrivateTabsView.alpha = 0
        }
    }

    @objc func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.alpha = 1
            self.emptyPrivateTabsView.alpha = 1
            if self.tabDisplayManager.isPrivate, !self.privateTabsAreEmpty() {
                self.searchBarHolder.alpha = 1
            }
        }) { _ in
            self.webViewContainerBackdrop.alpha = 0
            self.view.sendSubviewToBack(self.webViewContainerBackdrop)
        }
    }
}

extension TabTrayControllerV1: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        if let tab = tabDisplayManager.dataStore.at(index) {
            tabManager.selectTab(tab)
            dismissTabTray()
        }
    }
}

extension TabTrayControllerV1: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
        dismiss(animated: animated, completion: { self.collectionView.reloadData() })
    }
}

extension TabTrayControllerV1: UIScrollViewAccessibilityDelegate {
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
            return NSLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
        }

        let firstTab = indexPaths.first!.row + 1
        let lastTab = indexPaths.last!.row + 1
        let tabCount = collectionView.numberOfItems(inSection: 0)

        if firstTab == lastTab {
            let format = NSLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
            return String(format: format, NSNumber(value: firstTab as Int), NSNumber(value: tabCount as Int))
        } else {
            let format = NSLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
            return String(format: format, NSNumber(value: firstTab as Int), NSNumber(value: lastTab as Int), NSNumber(value: tabCount as Int))
        }
    }
}

extension TabTrayControllerV1: SwipeAnimatorDelegate {
    func swipeAnimator(_ animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
        guard let tabCell = animator.animatingView as? TabCell, let indexPath = collectionView.indexPath(for: tabCell) else { return }
        if let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            self.removeByButtonOrSwipe(tab: tab, cell: tabCell)
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: NSLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed."))
        }
    }

    // Disable swipe delete while drag reordering
    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool {
        return !tabDisplayManager.isDragging
    }
}

extension TabTrayControllerV1: TabCellDelegate {
    func tabCellDidClose(_ cell: TabCell) {
        if let indexPath = collectionView.indexPath(for: cell), let tab = tabDisplayManager.dataStore.at(indexPath.item) {
            removeByButtonOrSwipe(tab: tab, cell: cell)
        }
    }
}

extension TabTrayControllerV1: TabPeekDelegate {

    func tabPeekDidAddBookmark(_ tab: Tab) {
        delegate?.tabTrayDidAddBookmark(tab)
    }

    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? {
        return delegate?.tabTrayDidAddToReadingList(tab)
    }

    func tabPeekDidCloseTab(_ tab: Tab) {
        if let index = tabDisplayManager.dataStore.index(of: tab),
            let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TabCell {
            cell.close()
        }
    }

    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {
        delegate?.tabTrayRequestsPresentationOf(viewController)
    }
}

extension TabTrayControllerV1: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let collectionView = collectionView else { return nil }
        let convertedLocation = self.view.convert(location, to: collectionView)

        guard let indexPath = collectionView.indexPathForItem(at: convertedLocation),
            let cell = collectionView.cellForItem(at: indexPath) else { return nil }

        guard let tab = tabDisplayManager.dataStore.at(indexPath.row) else {
            return nil
        }
        let tabVC = TabPeekViewController(tab: tab, delegate: self)
        if let browserProfile = profile as? BrowserProfile {
            tabVC.setState(withProfile: browserProfile, clientPickerDelegate: self)
        }
        previewingContext.sourceRect = self.view.convert(cell.frame, from: collectionView)

        return tabVC
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let tpvc = viewControllerToCommit as? TabPeekViewController else { return }
        tabManager.selectTab(tpvc.tab)
        navigationController?.popViewController(animated: true)
        delegate?.tabTrayDidDismiss(self)
    }
}

extension TabTrayControllerV1: TabDisplayCompletionDelegate {
    func completedAnimation(for type: TabAnimationType) {
        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()

        switch type {
        case .addTab:
            dismissTabTray()
            LeanPlumClient.shared.track(event: .openedNewTab, withParameters: ["Source": "Tab Tray"])
        case .removedLastTab:
            // when removing the last tab (only in normal mode) we will automatically open a new tab.
            // When that happens focus it by dismissing the tab tray
            if !tabDisplayManager.isPrivate {
                self.dismissTabTray()
            }
        case .removedNonLastTab, .updateTab, .moveTab:
            break
        }
    }
}

extension TabTrayControllerV1 {
    func removeByButtonOrSwipe(tab: Tab, cell: TabCell) {
        tabDisplayManager.tabDisplayCompletionDelegate = self
        tabDisplayManager.closeActionPerformed(forCell: cell)
    }
}

extension TabTrayControllerV1 {
    @objc func didTapToolbarDelete(_ sender: UIButton) {
        if tabDisplayManager.isDragging {
            return
        }

        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.AppMenuCloseAllTabsTitleString, style: .default, handler: { _ in self.closeTabsForCurrentTray() }), accessibilityIdentifier: "TabTrayController.deleteButton.closeAll")
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil), accessibilityIdentifier: "TabTrayController.deleteButton.cancel")
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        present(controller, animated: true, completion: nil)
    }
}

fileprivate class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    weak var tabSelectionDelegate: TabSelectionDelegate?
    var searchHeightConstraint: Constraint?
    let scrollView: UIScrollView
    var lastYOffset: CGFloat = 0

    enum ScrollDirection {
        case up
        case down
    }

    fileprivate var scrollDirection: ScrollDirection = .down
    fileprivate var traitCollection: UITraitCollection
    fileprivate var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return TabTrayControllerUX.CompactNumberOfColumnsThin
        } else {
            return TabTrayControllerUX.NumberOfColumnsWide
        }
    }

    init(profile: Profile, traitCollection: UITraitCollection, scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.traitCollection = traitCollection
        super.init()
    }

    func clamp(_ y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            if scrollDirection == .up {
                hideSearch()
            }
        }
    }

    func checkRubberbandingForDelta(_ delta: CGFloat, for scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y < 0 {
            return true
        } else {
            return false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let float = scrollView.contentOffset.y

        defer {
            self.lastYOffset = float
        }
        let delta = lastYOffset - float

        if delta > 0 {
            scrollDirection = .down
        } else if delta < 0 {
            scrollDirection = .up
        }
        if checkRubberbandingForDelta(delta, for: scrollView) {

            let offset = clamp(abs(scrollView.contentOffset.y), min: 0, max: TabTrayControllerUX.SearchBarHeight)
            searchHeightConstraint?.update(offset: offset)
            if scrollDirection == .down {
                scrollView.contentInset = UIEdgeInsets(top: offset, left: 0, bottom: 0, right: 0)
            }
        } else {
            self.hideSearch()
        }
    }

    func showSearch() {
        searchHeightConstraint?.update(offset: TabTrayControllerUX.SearchBarHeight)
        scrollView.contentInset = UIEdgeInsets(top: TabTrayControllerUX.SearchBarHeight, left: 0, bottom: 0, right: 0)
    }

    func hideSearch() {
        searchHeightConstraint?.update(offset: 0)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    fileprivate func cellHeightForCurrentDevice() -> CGFloat {
        let shortHeight = TabTrayControllerUX.TextBoxHeight * 6

        if self.traitCollection.verticalSizeClass == .compact {
            return shortHeight
        } else if self.traitCollection.horizontalSizeClass == .compact {
            return shortHeight
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - TabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns))
        return CGSize(width: cellWidth, height: self.cellHeightForCurrentDevice())
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(equalInset: TabTrayControllerUX.Margin)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

private struct EmptyPrivateTabsViewUX {
    static let TitleFont = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium)
    static let DescriptionFont = UIFont.systemFont(ofSize: 17)
    static let LearnMoreFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
    static let TextMargin: CGFloat = 18
    static let LearnMoreMargin: CGFloat = 30
    static let MaxDescriptionWidth: CGFloat = 250
    static let MinBottomMargin: CGFloat = 10
}

// View we display when there are no private tabs created
fileprivate class EmptyPrivateTabsView: UIView {
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Photon.White100
        label.font = EmptyPrivateTabsViewUX.TitleFont
        label.textAlignment = .center
        return label
    }()

    fileprivate var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Photon.White100
        label.font = EmptyPrivateTabsViewUX.DescriptionFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = EmptyPrivateTabsViewUX.MaxDescriptionWidth
        return label
    }()

    fileprivate var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(
            NSLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode"),
            for: [])
        button.setTitleColor(UIColor.theme.tabTray.privateModeLearnMore, for: [])
        button.titleLabel?.font = EmptyPrivateTabsViewUX.LearnMoreFont
        return button
    }()

    fileprivate var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.templateImageNamed("largePrivateMask"))
        imageView.tintColor = UIColor.Photon.Grey60
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text =  NSLocalizedString("Private Browsing",
            tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode")
        descriptionLabel.text = NSLocalizedString("Firefox won’t remember any of your history or cookies, but new bookmarks will be saved.",
            tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode")

        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(iconImageView)
        addSubview(learnMoreButton)

        titleLabel.snp.makeConstraints { make in
            make.center.equalTo(self)
        }

        iconImageView.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.top)
            make.height.width.equalTo(120)
            make.centerX.equalTo(self)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(EmptyPrivateTabsViewUX.TextMargin)
            make.centerX.equalTo(self)
        }

        learnMoreButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(EmptyPrivateTabsViewUX.LearnMoreMargin).priority(10)
            make.bottom.lessThanOrEqualTo(self).offset(-EmptyPrivateTabsViewUX.MinBottomMargin).priority(1000)
            make.centerX.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TabTrayControllerV1: DevicePickerViewControllerDelegate {
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

extension TabTrayControllerV1: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Toolbar
class TrayToolbar: UIView, Themeable, PrivateModeUI {
    fileprivate let toolbarButtonSize = CGSize(width: 44, height: 44)

    lazy var addTabButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("nav-add"), for: .normal)
        button.accessibilityLabel = NSLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
        button.accessibilityIdentifier = "TabTrayController.addTabButton"
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("action_delete"), for: .normal)
        button.accessibilityLabel = Strings.TabTrayDeleteMenuButtonAccessibilityLabel
        button.accessibilityIdentifier = "TabTrayController.removeTabsButton"
        return button
    }()

    lazy var maskButton = PrivateModeButton()
    fileprivate let sideOffset: CGFloat = 32

    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(addTabButton)

        var buttonToCenter: UIButton?
        addSubview(deleteButton)
        buttonToCenter = deleteButton

        maskButton.accessibilityIdentifier = "TabTrayController.maskButton"

        buttonToCenter?.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(self)
            make.size.equalTo(toolbarButtonSize)
        }

        addTabButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.trailing.equalTo(self).offset(-sideOffset)
            make.size.equalTo(toolbarButtonSize)
        }

        addSubview(maskButton)
        maskButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(sideOffset)
            make.size.equalTo(toolbarButtonSize)
        }

        applyTheme()
        applyUIMode(isPrivate: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyUIMode(isPrivate: Bool) {
        maskButton.applyUIMode(isPrivate: isPrivate)
    }

    func applyTheme() {
        [addTabButton, deleteButton].forEach {
            $0.tintColor = UIColor.theme.tabTray.toolbarButtonTint
        }
        backgroundColor = UIColor.theme.tabTray.toolbar
        maskButton.offTint = UIColor.theme.tabTray.privateModeButtonOffTint
        maskButton.onTint = UIColor.theme.tabTray.privateModeButtonOnTint
    }
}

protocol TabCellDelegate: AnyObject {
    func tabCellDidClose(_ cell: TabCell)
}

class TabCell: UICollectionViewCell {
    enum Style {
        case light
        case dark
    }

    static let Identifier = "TabCellIdentifier"
    static let BorderWidth: CGFloat = 3

    let backgroundHolder: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        view.clipsToBounds = true
        view.backgroundColor = UIColor.theme.tabTray.cellBackground
        return view
    }()

    let screenshotView: UIImageViewAligned = {
        let view = UIImageViewAligned()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.alignLeft = true
        view.alignTop = true
        view.backgroundColor = UIColor.theme.browser.background
        return view
    }()

    let titleText: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        label.textColor = UIColor.theme.tabTray.tabTitleText
        return label
    }()

    let favicon: UIImageView = {
        let favicon = UIImageView()
        favicon.backgroundColor = UIColor.clear
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
        return favicon
    }()

    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.imageEdgeInsets = UIEdgeInsets(equalInset: TabTrayControllerUX.CloseButtonEdgeInset)
        return button
    }()

    var title = UIVisualEffectView(effect: UIBlurEffect(style: UIColor.theme.tabTray.tabTitleBlur))
    var animator: SwipeAnimator!

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.animator = SwipeAnimator(animatingView: self)
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.screenshotView)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        backgroundHolder.addSubview(title)
        title.contentView.addSubview(self.closeButton)
        title.contentView.addSubview(self.titleText)
        title.contentView.addSubview(self.favicon)

        title.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(backgroundHolder)
            make.height.equalTo(TabTrayControllerUX.TextBoxHeight)
        }

        favicon.snp.makeConstraints { make in
            make.leading.equalTo(title.contentView).offset(6)
            make.top.equalTo((TabTrayControllerUX.TextBoxHeight - TabTrayControllerUX.FaviconSize) / 2)
            make.size.equalTo(TabTrayControllerUX.FaviconSize)
        }

        titleText.snp.makeConstraints { (make) in
            make.leading.equalTo(favicon.snp.trailing).offset(6)
            make.trailing.equalTo(closeButton.snp.leading).offset(-6)
            make.centerY.equalTo(title.contentView)
        }

        closeButton.snp.makeConstraints { make in
            make.size.equalTo(TabTrayControllerUX.CloseButtonSize)
            make.centerY.trailing.equalTo(title.contentView)
        }
    }

    func setTabSelected(_ isPrivate: Bool) {
        // This creates a border around a tabcell. Using the shadow craetes a border _outside_ of the tab frame.
        layer.shadowColor = (isPrivate ? UIColor.theme.tabTray.privateModePurple : UIConstants.SystemBlueColor).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 0 // A 0 radius creates a solid border instead of a gradient blur
        layer.masksToBounds = false
        // create a frame that is "BorderWidth" size bigger than the cell
        layer.shadowOffset = CGSize(width: -TabCell.BorderWidth, height: -TabCell.BorderWidth)
        let shadowPath = CGRect(width: layer.frame.width + (TabCell.BorderWidth * 2), height: layer.frame.height + (TabCell.BorderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: TabTrayControllerUX.CornerRadius+TabCell.BorderWidth).cgPath
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundHolder.frame = CGRect(x: margin, y: margin, width: frame.width, height: frame.height)
        screenshotView.frame = CGRect(size: backgroundHolder.frame.size)

        let shadowPath = CGRect(width: layer.frame.width + (TabCell.BorderWidth * 2), height: layer.frame.height + (TabCell.BorderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: TabTrayControllerUX.CornerRadius+TabCell.BorderWidth).cgPath
    }

    func configureWith(tab: Tab, is selected: Bool) {
        titleText.text = tab.displayTitle

        if !tab.displayTitle.isEmpty {
            accessibilityLabel = tab.displayTitle
        } else if let url = tab.url, let about = InternalURL(url)?.aboutComponent {
            accessibilityLabel = about
        } else {
            accessibilityLabel = ""
        }

        isAccessibilityElement = true
        accessibilityHint = NSLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")

        if let favIcon = tab.displayFavicon, let url = URL(string: favIcon.url) {
            favicon.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultFavicon"), options: [], completed: nil)
        } else {
            if ThemeManager.instance.currentName == .dark {
                favicon.image = UIImage(named: "defaultFavicon")?.withRenderingMode(.alwaysTemplate)
                favicon.tintColor = UIColor.theme.tabTray.faviconTint
            } else {
                favicon.image = UIImage(named: "defaultFavicon")
            }
        }
        if selected {
            setTabSelected(tab.isPrivate)
        } else {
            layer.shadowOffset = .zero
            layer.shadowPath = nil
            layer.shadowOpacity = 0
        }
        screenshotView.image = tab.screenshot
    }

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        layer.shadowOffset = .zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
        isHidden = false
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .left:
            right = false
        case .right:
            right = true
        default:
            return false
        }
        animator.close(right: right)
        return true
    }

    @objc func close() {
        delegate?.tabCellDidClose(self)
    }
}

class SearchBarTextField: UITextField, PrivateModeUI {
    static let leftInset = CGFloat(18)

    func applyUIMode(isPrivate: Bool) {
        tintColor = UIColor.theme.urlbar.textSelectionHighlight(isPrivate).textFieldMode
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: SearchBarTextField.leftInset, dy: 0)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: SearchBarTextField.leftInset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: SearchBarTextField.leftInset, dy: 0)
    }
}
