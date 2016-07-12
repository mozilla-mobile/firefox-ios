/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Storage
import ReadingList
import Shared

struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let BackgroundColor = UIConstants.AppBackgroundColor
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(18.0)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = UIConstants.AppBackgroundColor
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let CloseButtonSize = CGFloat(18.0)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(10)

    static let NumberOfColumnsThin = 1
    static let NumberOfColumnsWide = 3
    static let CompactNumberOfColumnsThin = 2

    static let MenuFixedWidth: CGFloat = 320

    // Moved from UIConstants temporarily until animation code is merged
    static var StatusBarHeight: CGFloat {
        if UIScreen.main().traitCollection.verticalSizeClass == .compact {
            return 0
        }
        return 20
    }
}

struct LightTabCellUX {
    static let TabTitleTextColor = UIColor.black()
}

struct DarkTabCellUX {
    static let TabTitleTextColor = UIColor.white()
}

protocol TabCellDelegate: class {
    func tabCellDidClose(_ cell: TabCell)
}

class TabCell: UICollectionViewCell {
    enum Style {
        case light
        case dark
    }

    static let Identifier = "TabCellIdentifier"

    var style: Style = .light {
        didSet {
            applyStyle(style)
        }
    }

    let backgroundHolder = UIView()
    let background = UIImageViewAligned()
    let titleText: UILabel
    let innerStroke: InnerStrokedView
    let favicon: UIImageView = UIImageView()
    let closeButton: UIButton

    var title: UIVisualEffectView!
    var animator: SwipeAnimator!

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        self.backgroundHolder.backgroundColor = UIColor.white()
        self.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.backgroundHolder.clipsToBounds = true
        self.backgroundHolder.backgroundColor = TabTrayControllerUX.CellBackgroundColor

        self.background.contentMode = UIViewContentMode.scaleAspectFill
        self.background.clipsToBounds = true
        self.background.isUserInteractionEnabled = false
        self.background.alignLeft = true
        self.background.alignTop = true

        self.favicon.backgroundColor = UIColor.clear()
        self.favicon.layer.cornerRadius = 2.0
        self.favicon.layer.masksToBounds = true

        self.titleText = UILabel()
        self.titleText.textAlignment = NSTextAlignment.left
        self.titleText.isUserInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold

        self.closeButton = UIButton()
        self.closeButton.setImage(UIImage(named: "stop"), for: UIControlState())
        self.closeButton.tintColor = UIColor.lightGray()
        self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)

        self.innerStroke = InnerStrokedView(frame: self.backgroundHolder.frame)
        self.innerStroke.layer.backgroundColor = UIColor.clear().cgColor

        super.init(frame: frame)

        self.isOpaque = true

        self.animator = SwipeAnimator(animatingView: self.backgroundHolder, container: self)
        self.closeButton.addTarget(self, action: #selector(TabCell.SELclose), for: UIControlEvents.touchUpInside)

        contentView.addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.background)
        backgroundHolder.addSubview(innerStroke)

        // Default style is light
        applyStyle(style)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: #selector(SwipeAnimator.SELcloseWithoutGesture))
        ]
    }

    private func applyStyle(_ style: Style) {
        self.title?.removeFromSuperview()

        let title: UIVisualEffectView
        switch style {
        case .light:
            title = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            self.titleText.textColor = LightTabCellUX.TabTitleTextColor
        case .dark:
            title = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            self.titleText.textColor = DarkTabCellUX.TabTitleTextColor
        }

        titleText.backgroundColor = UIColor.clear()

        title.layer.shadowColor = UIColor.black().cgColor
        title.layer.shadowOpacity = 0.2
        title.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        title.layer.shadowRadius = 0

        title.addSubview(self.closeButton)
        title.addSubview(self.titleText)
        title.addSubview(self.favicon)

        backgroundHolder.addSubview(title)
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = frame.width
        let h = frame.height
        backgroundHolder.frame = CGRect(x: margin,
            y: margin,
            width: w,
            height: h)
        background.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: backgroundHolder.frame.size)

        title.frame = CGRect(x: 0,
            y: 0,
            width: backgroundHolder.frame.width,
            height: TabTrayControllerUX.TextBoxHeight)

        favicon.frame = CGRect(x: 6,
            y: (TabTrayControllerUX.TextBoxHeight - TabTrayControllerUX.FaviconSize)/2,
            width: TabTrayControllerUX.FaviconSize,
            height: TabTrayControllerUX.FaviconSize)

        let titleTextLeft = favicon.frame.origin.x + favicon.frame.width + 6
        titleText.frame = CGRect(x: titleTextLeft,
            y: 0,
            width: title.frame.width - titleTextLeft - margin  - TabTrayControllerUX.CloseButtonSize - TabTrayControllerUX.CloseButtonMargin * 2,
            height: title.frame.height)

        innerStroke.frame = background.frame

        closeButton.snp_makeConstraints { make in
            make.size.equalTo(title.snp_height)
            make.trailing.centerY.equalTo(title)
        }

        let top = (TabTrayControllerUX.TextBoxHeight - titleText.bounds.height) / 2.0
        titleText.frame.origin = CGPoint(x: titleText.frame.origin.x, y: max(0, top))
    }


    override func prepareForReuse() {
        // Reset any close animations.
        backgroundHolder.transform = CGAffineTransform.identity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
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

    @objc
    func SELclose() {
        self.animator.SELcloseWithoutGesture()
    }
}

struct PrivateModeStrings {
    static let toggleAccessibilityLabel = NSLocalizedString("Private Mode", tableName: "PrivateBrowsing", comment: "Accessibility label for toggling on/off private mode")
    static let toggleAccessibilityHint = NSLocalizedString("Turns private mode on or off", tableName: "PrivateBrowsing", comment: "Accessiblity hint for toggling on/off private mode")
    static let toggleAccessibilityValueOn = NSLocalizedString("On", tableName: "PrivateBrowsing", comment: "Toggled ON accessibility value")
    static let toggleAccessibilityValueOff = NSLocalizedString("Off", tableName: "PrivateBrowsing", comment: "Toggled OFF accessibility value")
}

protocol TabTrayDelegate: class {
    func tabTrayDidDismiss(_ tabTray: TabTrayController)
    func tabTrayDidAddBookmark(_ tab: Tab)
    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListClientRecord?
    func tabTrayRequestsPresentationOf(viewController: UIViewController)
}

struct TabTrayState {
    var isPrivate: Bool = false
}

class TabTrayController: UIViewController {
    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?
    weak var appStateDelegate: AppStateDelegate?

    var collectionView: UICollectionView!
    lazy var toolbar: TrayToolbar = {
        let toolbar = TrayToolbar()
        toolbar.addTabButton.addTarget(self, action: #selector(TabTrayController.SELdidClickAddTab), for: .touchUpInside)

        if AppConstants.MOZ_MENU {
            toolbar.menuButton.addTarget(self, action: #selector(TabTrayController.didTapMenu), for: .touchUpInside)
        } else {
            toolbar.settingsButton.addTarget(self, action: #selector(TabTrayController.SELdidClickSettingsItem), for: .touchUpInside)
        }

        if #available(iOS 9, *) {
            toolbar.maskButton.addTarget(self, action: #selector(TabTrayController.SELdidTogglePrivateMode), for: .touchUpInside)
        }
        return toolbar
    }()

    var tabTrayState: TabTrayState {
        return TabTrayState(isPrivate: self.privateMode)
    }

    var leftToolbarButtons: [UIButton] {
        return [toolbar.addTabButton]
    }

    var rightToolbarButtons: [UIButton]? {
        if #available(iOS 9, *) {
            return [toolbar.maskButton]
        } else {
            return []
        }
    }

    private(set) internal var privateMode: Bool = false {
        didSet {
            if oldValue != privateMode {
                updateAppState()
            }

            tabDataSource.tabs = tabsToDisplay
            toolbar.styleToolbar(isPrivate: privateMode)
            collectionView?.reloadData()
        }
    }

    private var tabsToDisplay: [Tab] {
        return self.privateMode ? tabManager.privateTabs : tabManager.normalTabs
    }

    @available(iOS 9, *)
    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.learnMoreButton.addTarget(self, action: #selector(TabTrayController.SELdidTapLearnMore), for: UIControlEvents.touchUpInside)
        return emptyView
    }()

    private lazy var tabDataSource: TabManagerDataSource = {
        return TabManagerDataSource(tabs: self.tabsToDisplay, cellDelegate: self)
    }()

    private lazy var tabLayoutDelegate: TabLayoutDelegate = {
        let delegate = TabLayoutDelegate(profile: self.profile, traitCollection: self.traitCollection)
        delegate.tabSelectionDelegate = self
        return delegate
    }()

    init(tabManager: TabManager, profile: Profile) {
        self.tabManager = tabManager
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        tabManager.addDelegate(self)
    }

    convenience init(tabManager: TabManager, profile: Profile, tabTrayDelegate: TabTrayDelegate) {
        self.init(tabManager: tabManager, profile: profile)
        self.delegate = tabTrayDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
        self.tabManager.removeDelegate(self)
    }

    func SELDynamicFontChanged(_ notification: Notification) {
        guard notification.name == NotificationDynamicFontChanged else { return }

        self.collectionView.reloadData()
    }

// MARK: View Controller Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())

        collectionView.dataSource = tabDataSource
        collectionView.delegate = tabLayoutDelegate
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIConstants.ToolbarHeight, right: 0)
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor

        view.addSubview(collectionView)
        view.addSubview(toolbar)

        makeConstraints()

        if #available(iOS 9, *) {
            view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
            emptyPrivateTabsView.snp_makeConstraints { make in
                make.top.left.right.equalTo(self.collectionView)
                make.bottom.equalTo(self.toolbar.snp_top)
            }

            if let tab = tabManager.selectedTab where tab.isPrivate {
                privateMode = true
            }

            // register for previewing delegate to enable peek and pop if force touch feature available
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
            }

            emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.SELappWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.SELappDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.SELDynamicFontChanged(_:)), name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.SELdidClickSettingsItem), name: NSNotification.Name(rawValue: NotificationStatusNotificationTapped), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStatusNotificationTapped), object: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    private func makeConstraints() {
        collectionView.snp_makeConstraints { make in
            make.left.bottom.right.equalTo(view)
            make.top.equalTo(snp_topLayoutGuideBottom)
        }

        toolbar.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.height.equalTo(UIConstants.ToolbarHeight)
        }
    }

// MARK: Selectors
    func SELdidClickDone() {
        presentingViewController!.dismiss(animated: true, completion: nil)
    }

    func SELdidClickSettingsItem() {
        assert(Thread.isMainThread, "Opening settings requires being invoked on the main thread")

        let settingsTableViewController = AppSettingsTableViewController()
        settingsTableViewController.profile = profile
        settingsTableViewController.tabManager = tabManager
        settingsTableViewController.settingsDelegate = self

        let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
        controller.popoverDelegate = self
		controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
        present(controller, animated: true, completion: nil)
    }

    func SELdidClickAddTab() {
        openNewTab()
    }

    @available(iOS 9, *)
    func SELdidTapLearnMore() {
        let appVersion = Bundle.main.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        if let langID = Locale.preferredLanguages.first {
            let learnMoreRequest = URLRequest(url: "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(langID)/private-browsing-ios".asURL!)
            openNewTab(learnMoreRequest)
        }
    }

    @objc
    private func didTapMenu() {
        let state = mainStore.updateState(.tabTray(tabTrayState: self.tabTrayState))
        let mvc = MenuViewController(withAppState: state, presentationStyle: .modal)
        mvc.delegate = self
        mvc.actionDelegate = self
        mvc.menuTransitionDelegate = MenuPresentationAnimator()
        mvc.modalPresentationStyle = .overCurrentContext
        mvc.fixedWidth = TabTrayControllerUX.MenuFixedWidth
        self.present(mvc, animated: true, completion: nil)
    }

    @available(iOS 9, *)
    func SELdidTogglePrivateMode() {
        let scaleDownTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        let fromView: UIView
        if privateTabsAreEmpty() {
            fromView = emptyPrivateTabsView
        } else {
            let snapshot = collectionView.snapshotView(afterScreenUpdates: false)
            snapshot?.frame = collectionView.frame
            view.insertSubview(snapshot!, aboveSubview: collectionView)
            fromView = snapshot!
        }

        privateMode = !privateMode
        // If we are exiting private mode and we have the close private tabs option selected, make sure
        // we clear out all of the private tabs
        let exitingPrivateMode = !privateMode && profile.prefs.boolForKey("settings.closePrivateTabs") ?? false
        if exitingPrivateMode {
            tabManager.removeAllPrivateTabs(andNotify: false)
        }

        toolbar.maskButton.setSelected(privateMode, animated: true)
        collectionView.layoutSubviews()

        let toView: UIView
        if privateTabsAreEmpty() {
            emptyPrivateTabsView.isHidden = false
            toView = emptyPrivateTabsView
        } else {
            emptyPrivateTabsView.isHidden = true
            //when exiting private mode don't screenshot the collectionview (causes the UI to hang)
            let newSnapshot = collectionView.snapshotViewAfterScreenUpdates(!exitingPrivateMode)
            newSnapshot.frame = collectionView.frame
            view.insertSubview(newSnapshot, aboveSubview: fromView)
            collectionView.alpha = 0
            toView = newSnapshot
        }
        toView.alpha = 0
        toView.transform = scaleDownTransform

        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: { () -> Void in
            fromView.transform = scaleDownTransform
            fromView.alpha = 0
            toView.transform = CGAffineTransform.identity
            toView.alpha = 1
        }) { finished in
            if fromView != self.emptyPrivateTabsView {
                fromView.removeFromSuperview()
            }
            if toView != self.emptyPrivateTabsView {
                toView.removeFromSuperview()
            }
            self.collectionView.alpha = 1
        }
    }

    @available(iOS 9, *)
    private func privateTabsAreEmpty() -> Bool {
        return privateMode && tabManager.privateTabs.count == 0
    }

    @available(iOS 9, *)
    func changePrivacyMode(toPrivateMode isPrivate: Bool) {
        if isPrivate != privateMode {
            guard let _ = collectionView else {
                privateMode = isPrivate
                return
            }
            SELdidTogglePrivateMode()
        }
    }

    private func openNewTab(_ request: URLRequest? = nil) {
        toolbar.addTabButton.isUserInteractionEnabled = false

        // We're only doing one update here, but using a batch update lets us delay selecting the tab
        // until after its insert animation finishes.
        self.collectionView.performBatchUpdates({ _ in
            var tab: Tab
            if #available(iOS 9, *) {
                tab = self.tabManager.addTab(request, isPrivate: self.privateMode)
            } else {
                tab = self.tabManager.addTab(request)
            }
            self.tabManager.selectTab(tab)
        }, completion: { finished in
            if finished {
                self.toolbar.addTabButton.isUserInteractionEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
        })
    }

    private func updateAppState() {
        let state = mainStore.updateState(.tabTray(tabTrayState: self.tabTrayState))
        self.appStateDelegate?.appDidUpdateState(state)
    }

    private func closeTabsForCurrentTray() {
        tabManager.removeTabsWithUndoToast(tabsToDisplay)
        self.collectionView.reloadData()
    }
}

// MARK: - App Notifications
extension TabTrayController {
    func SELappWillResignActiveNotification() {
        if privateMode {
            collectionView.alpha = 0
        }
    }

    func SELappDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.collectionView.alpha = 1
        },
        completion: nil)
    }
}

extension TabTrayController: TabSelectionDelegate {
    func didSelectTab(atIndex index: Int) {
        let tab = tabsToDisplay[index]
        tabManager.selectTab(tab)
        self.navigationController?.popViewController(animated: true)
    }
}

extension TabTrayController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
        dismiss(animated: animated, completion: { self.collectionView.reloadData() })
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
    }

    func tabManager(_ tabManager: TabManager, didCreateTab tab: Tab) {
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        // Get the index of the added tab from it's set (private or normal)
        guard let index = tabsToDisplay.index(of: tab) else { return }
        if #available(iOS 9, *) {
            if !privateTabsAreEmpty() {
                emptyPrivateTabsView.isHidden = true
            }
        }

        tabDataSource.addTab(tab)
        self.collectionView?.performBatchUpdates({ _ in
            self.collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
        }, completion: { finished in
            if finished {
                tabManager.selectTab(tab)
                // don't pop the tab tray view controller if it is not in the foreground
                if self.presentedViewController == nil {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        // it is possible that we are removing a tab that we are not currently displaying
        // through the Close All Tabs feature (which will close tabs that are not in our current privacy mode)
        // check this before removing the item from the collection
        let removedIndex = tabDataSource.removeTab(tab)
        if removedIndex > -1 {
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [IndexPath(item: removedIndex, section: 0)])
            }, completion: { finished in
                if #available(iOS 9, *) {
                    guard finished && self.privateTabsAreEmpty() else { return }
                    self.emptyPrivateTabsView.isHidden = false
                }
            })

            // Workaround: On iOS 8.* devices, cells don't get reloaded during the deletion but after the
            // animation has finished which causes cells that animate from above to suddenly 'appear'. This
            // is fixed on iOS 9 but for iOS 8 we force a reload on non-visible cells during the animation.
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_8_3) {
                let visibleCount = collectionView.indexPathsForVisibleItems().count
                var offscreenIndexPaths = [IndexPath]()
                for i in 0..<(tabsToDisplay.count - visibleCount) {
                    offscreenIndexPaths.append(IndexPath(item: i, section: 0))
                }
                self.collectionView.reloadItems(at: offscreenIndexPaths)
            }
        }
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast:ButtonToast?) {
        guard privateMode else {
            return
        }
        if let undoToast = toast {
            view.addSubview(undoToast)
            undoToast.snp_makeConstraints { make in
                make.left.right.equalTo(view)
                make.bottom.equalTo(toolbar.snp_top)
            }
            undoToast.showToast()
        }
    }
}

extension TabTrayController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
        var visibleCells = collectionView.visibleCells() as! [TabCell]
        var bounds = collectionView.bounds
        bounds = bounds.offsetBy(dx: collectionView.contentInset.left, dy: collectionView.contentInset.top)
        bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
        bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
        // visible cells do sometimes return also not visible cells when attempting to go past the last cell with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
        visibleCells = visibleCells.filter { !$0.frame.intersection(bounds).isEmpty }

        let cells = visibleCells.map { self.collectionView.indexPath(for: $0)! }
        let indexPaths = cells.sorted { (a: IndexPath, b: IndexPath) -> Bool in
            return (a as NSIndexPath).section < (b as NSIndexPath).section || ((a as NSIndexPath).section == (b as NSIndexPath).section && (a as NSIndexPath).row < (b as NSIndexPath).row)
        }

        if indexPaths.count == 0 {
            return NSLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
        }

        let firstTab = (indexPaths.first! as NSIndexPath).row + 1
        let lastTab = (indexPaths.last! as NSIndexPath).row + 1
        let tabCount = collectionView.numberOfItems(inSection: 0)

        if (firstTab == lastTab) {
            let format = NSLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
            return String(format: format, NSNumber(value: firstTab), NSNumber(value: tabCount))
        } else {
            let format = NSLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
            return String(format: format, NSNumber(value: firstTab), NSNumber(value: lastTab), NSNumber(value: tabCount))
        }
    }
}

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(_ animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
        let tabCell = animator.container as! TabCell
        if let indexPath = collectionView.indexPath(for: tabCell) {
            let tab = tabsToDisplay[(indexPath as NSIndexPath).item]
            tabManager.removeTab(tab)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed."))
        }
    }
}

extension TabTrayController: TabCellDelegate {
    func tabCellDidClose(_ cell: TabCell) {
        let indexPath = collectionView.indexPath(for: cell)!
        let tab = tabsToDisplay[(indexPath as NSIndexPath).item]
        tabManager.removeTab(tab)
    }
}

extension TabTrayController: SettingsDelegate {
    func settingsOpenURLInNewTab(_ url: URL) {
        let request = URLRequest(url: url)
        openNewTab(request)
    }
}

private class TabManagerDataSource: NSObject, UICollectionViewDataSource {
    unowned var cellDelegate: protocol<TabCellDelegate, SwipeAnimatorDelegate>
    private var tabs: [Tab]

    init(tabs: [Tab], cellDelegate: protocol<TabCellDelegate, SwipeAnimatorDelegate>) {
        self.cellDelegate = cellDelegate
        self.tabs = tabs
        super.init()
    }

    /**
     Removes the given tab from the data source

     - parameter tab: Tab to remove

     - returns: The index of the removed tab, -1 if tab did not exist
     */
    func removeTab(_ tabToRemove: Tab) -> Int {
        var index: Int = -1
        for (i, tab) in tabs.enumerated() {
            if tabToRemove === tab {
                index = i
                tabs.remove(at: index)
                break
            }
        }
        return index
    }

    /**
     Adds the given tab to the data source

     - parameter tab: Tab to add
     */
    func addTab(_ tab: Tab) {
        tabs.append(tab)
    }

    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tabCell = collectionView.dequeueReusableCell(withReuseIdentifier: TabCell.Identifier, for: indexPath) as! TabCell
        tabCell.animator.delegate = cellDelegate
        tabCell.delegate = cellDelegate

        let tab = tabs[(indexPath as NSIndexPath).item]
        tabCell.style = tab.isPrivate ? .dark : .light
        tabCell.titleText.text = tab.displayTitle

        if !tab.displayTitle.isEmpty {
            tabCell.accessibilityLabel = tab.displayTitle
        } else {
            tabCell.accessibilityLabel = AboutUtils.getAboutComponent(tab.url)
        }

        tabCell.isAccessibilityElement = true
        tabCell.accessibilityHint = NSLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")

        if let favIcon = tab.displayFavicon {
            tabCell.favicon.sd_setImageWithURL(URL(string: favIcon.url)!)
        } else {
            var defaultFavicon = UIImage(named: "defaultFavicon")
            if tab.isPrivate {
                defaultFavicon = defaultFavicon?.withRenderingMode(.alwaysTemplate)
                tabCell.favicon.image = defaultFavicon
                tabCell.favicon.tintColor = UIColor.white()
            } else {
                tabCell.favicon.image = defaultFavicon
            }
        }

        tabCell.background.image = tab.screenshot
        return tabCell
    }

    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }
}

@objc protocol TabSelectionDelegate: class {
    func didSelectTab(atIndex index :Int)
}

private class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?

    private var traitCollection: UITraitCollection
    private var profile: Profile
    private var numberOfColumns: Int {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true

        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return compactLayout ? TabTrayControllerUX.CompactNumberOfColumnsThin : TabTrayControllerUX.NumberOfColumnsThin
        } else {
            return TabTrayControllerUX.NumberOfColumnsWide
        }
    }

    init(profile: Profile, traitCollection: UITraitCollection) {
        self.profile = profile
        self.traitCollection = traitCollection
        super.init()
    }

    private func cellHeightForCurrentDevice() -> CGFloat {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true
        let shortHeight = (compactLayout ? TabTrayControllerUX.TextBoxHeight * 6 : TabTrayControllerUX.TextBoxHeight * 5)

        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact {
            return shortHeight
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact {
            return shortHeight
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = floor((collectionView.bounds.width - TabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns))
        return CGSize(width: cellWidth, height: self.cellHeightForCurrentDevice())
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTab(atIndex: (indexPath as NSIndexPath).row)
    }
}

struct EmptyPrivateTabsViewUX {
    static let TitleColor = UIColor.white()
    static let TitleFont = UIFont.systemFont(ofSize: 22, weight: UIFontWeightMedium)
    static let DescriptionColor = UIColor.white()
    static let DescriptionFont = UIFont.systemFont(ofSize: 17)
    static let LearnMoreFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
    static let TextMargin: CGFloat = 18
    static let LearnMoreMargin: CGFloat = 30
    static let MaxDescriptionWidth: CGFloat = 250
    static let MinBottomMargin: CGFloat = 10
}

// View we display when there are no private tabs created
private class EmptyPrivateTabsView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.TitleColor
        label.font = EmptyPrivateTabsViewUX.TitleFont
        label.textAlignment = NSTextAlignment.center
        return label
    }()

    private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.DescriptionColor
        label.font = EmptyPrivateTabsViewUX.DescriptionFont
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = EmptyPrivateTabsViewUX.MaxDescriptionWidth
        return label
    }()

    private var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(
            NSLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode"),
            for: UIControlState())
        button.setTitleColor(UIConstants.PrivateModeTextHighlightColor, for: UIControlState())
        button.titleLabel?.font = EmptyPrivateTabsViewUX.LearnMoreFont
        return button
    }()

    private var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "largePrivateMask"))
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.text =  NSLocalizedString("Private Browsing",
            tableName: "PrivateBrowsing", comment: "Title displayed for when there are no open tabs while in private mode")
        descriptionLabel.text = NSLocalizedString("Firefox won't remember any of your history or cookies, but new bookmarks will be saved.",
            tableName: "PrivateBrowsing", comment: "Description text displayed when there are no open tabs while in private mode")

        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(iconImageView)
        addSubview(learnMoreButton)

        titleLabel.snp_makeConstraints { make in
            make.center.equalTo(self)
        }

        iconImageView.snp_makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp_top).offset(-EmptyPrivateTabsViewUX.TextMargin)
            make.centerX.equalTo(self)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottom).offset(EmptyPrivateTabsViewUX.TextMargin)
            make.centerX.equalTo(self)
        }

        learnMoreButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(descriptionLabel.snp_bottom).offset(EmptyPrivateTabsViewUX.LearnMoreMargin).priorityLow()
            make.bottom.lessThanOrEqualTo(self).offset(-EmptyPrivateTabsViewUX.MinBottomMargin).priorityHigh()
            make.centerX.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 9.0, *)
extension TabTrayController: TabPeekDelegate {

    func tabPeekDidAddBookmark(_ tab: Tab) {
        delegate?.tabTrayDidAddBookmark(tab)
    }

    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListClientRecord? {
        return delegate?.tabTrayDidAddToReadingList(tab)
    }

    func tabPeekDidClose(tab: Tab) {
        if let index = self.tabDataSource.tabs.index(of: tab),
            let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TabCell {
            cell.SELclose()
        }
    }

    func tabPeekRequestsPresentationOf(viewController: UIViewController) {
        delegate?.tabTrayRequestsPresentationOf(viewController: viewController)
    }
}

@available(iOS 9.0, *)
extension TabTrayController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let collectionView = collectionView else { return nil }
        let convertedLocation = self.view.convert(location, to: collectionView)

        guard let indexPath = collectionView.indexPathForItem(at: convertedLocation),
            let cell = collectionView.cellForItem(at: indexPath) else { return nil }

        let tab = tabDataSource.tabs[(indexPath as NSIndexPath).row]
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
        self.navigationController?.popViewController(animated: true)

        delegate?.tabTrayDidDismiss(self)

    }
}

extension TabTrayController: ClientPickerViewControllerDelegate {

    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        if let item = clientPickerViewController.shareItem {
            self.profile.sendItems([item], toClients: clients)
        }
        clientPickerViewController.dismiss(animated: true, completion: nil)
    }

    func clientPickerViewControllerDidCancel(_ clientPickerViewController: ClientPickerViewController) {
        clientPickerViewController.dismiss(animated: true, completion: nil)
    }
}

extension TabTrayController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

extension TabTrayController: MenuViewControllerDelegate {
    func menuViewControllerDidDismiss(_ menuViewController: MenuViewController) { }

    func shouldCloseMenu(_ menuViewController: MenuViewController, forRotationToNewSize size: CGSize, forTraitCollection traitCollection: UITraitCollection) -> Bool {
        return false
    }
}

extension TabTrayController: MenuActionDelegate {
    func performMenuAction(_ action: MenuAction, withAppState appState: AppState) {
        if let menuAction = AppMenuAction(rawValue: action.action) {
            switch menuAction {
            case .OpenNewNormalTab:
                DispatchQueue.main.async {
                    if #available(iOS 9, *) {
                        if self.privateMode {
                            self.SELdidTogglePrivateMode()
                        }
                    }
                    self.openNewTab()
                }
            // this is a case that is only available in iOS9
            case .OpenNewPrivateTab:
                if #available(iOS 9, *) {
                    DispatchQueue.main.async {
                        if !self.privateMode {
                            self.SELdidTogglePrivateMode()
                        }
                        self.openNewTab()
                    }
                }
            case .OpenSettings:
                DispatchQueue.main.async {
                    self.SELdidClickSettingsItem()
                }
            case .CloseAllTabs:
                DispatchQueue.main.async {
                    self.closeTabsForCurrentTray()
                }
            case .OpenTopSites:
                DispatchQueue.main.async {
                    self.openNewTab(PrivilegedRequest(coder: HomePanelType.topSites.localhostURL))
                }
            case .OpenBookmarks:
                DispatchQueue.main.async {
                    self.openNewTab(PrivilegedRequest(coder: HomePanelType.bookmarks.localhostURL))
                }
            case .OpenHistory:
                DispatchQueue.main.async {
                    self.openNewTab(PrivilegedRequest(coder: HomePanelType.history.localhostURL))
                }
            case .OpenReadingList:
                DispatchQueue.main.async {
                    self.openNewTab(PrivilegedRequest(coder: HomePanelType.readingList.localhostURL))
                }
            default: break
            }
        }
    }
}

// MARK: - Toolbar
class TrayToolbar: UIView {
    private let toolbarButtonSize = CGSize(width: 44, height: 44)

    lazy var settingsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("settings"), for: .Normal)
        button.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button in the Tab Tray.")
        button.accessibilityIdentifier = "TabTrayController.settingsButton"
        return button
    }()

    lazy var addTabButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("add"), for: .Normal)
        button.accessibilityLabel = NSLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
        button.accessibilityIdentifier = "TabTrayController.addTabButton"
        return button
    }()

    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.templateImageNamed("bottomNav-menu-pbm"), for: .Normal)
        button.accessibilityLabel = AppMenuConfiguration.MenuButtonAccessibilityLabel
        button.accessibilityIdentifier = "TabTrayController.menuButton"
        return button
    }()

    lazy var maskButton: ToggleButton = {
        let button = ToggleButton()
        button.accessibilityLabel = PrivateModeStrings.toggleAccessibilityLabel
        button.accessibilityHint = PrivateModeStrings.toggleAccessibilityHint
        return button
    }()

    private let sideOffset: CGFloat = 32

    private override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white()
        addSubview(addTabButton)

        var buttonToCenter: UIButton?
        if AppConstants.MOZ_MENU {
            addSubview(menuButton)
            buttonToCenter = menuButton
        } else {
            addSubview(settingsButton)
            buttonToCenter = settingsButton
        }

        buttonToCenter?.snp_makeConstraints { make in
            make.center.equalTo(self)
            make.size.equalTo(toolbarButtonSize)
        }

        addTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.left.equalTo(self).offset(sideOffset)
            make.size.equalTo(toolbarButtonSize)
        }

        if #available(iOS 9, *) {
            addSubview(maskButton)
            maskButton.snp_makeConstraints { make in
                make.centerY.equalTo(self)
                make.right.equalTo(self).offset(-sideOffset)
                make.size.equalTo(toolbarButtonSize)
            }
        }

        styleToolbar(isPrivate: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func styleToolbar(isPrivate: Bool) {
        addTabButton.tintColor = isPrivate ? .white() : .darkGray()
        if AppConstants.MOZ_MENU {
            menuButton.tintColor = isPrivate ? .white() : .darkGray()
        } else {
            settingsButton.tintColor = isPrivate ? .white() : .darkGray()
        }
        maskButton.tintColor = isPrivate ? .white() : .darkGray()
        backgroundColor = isPrivate ? UIConstants.PrivateModeToolbarTintColor : .white()
        updateMaskButtonState(isPrivate: isPrivate)
    }

    private func updateMaskButtonState(isPrivate: Bool) {
        let maskImage = UIImage(named: "smallPrivateMask")?.withRenderingMode(.alwaysTemplate)
        maskButton.imageView?.tintColor = isPrivate ? .white() : UIConstants.PrivateModeToolbarTintColor
        maskButton.setImage(maskImage, for: UIControlState())
        maskButton.isSelected = isPrivate
        maskButton.accessibilityValue = isPrivate ? PrivateModeStrings.toggleAccessibilityValueOn : PrivateModeStrings.toggleAccessibilityValueOff
    }
}
