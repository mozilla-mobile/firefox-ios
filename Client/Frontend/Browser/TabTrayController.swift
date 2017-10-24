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
    static let CornerRadius = CGFloat(6.0)
    static let BackgroundColor = UIConstants.TabTrayBG
    static let CellBackgroundColor = UIConstants.TabTrayBG
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(20)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = UIColor.black
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let CloseButtonSize = CGFloat(18.0)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(10)

    static let NumberOfColumnsThin = 1
    static let NumberOfColumnsWide = 3
    static let CompactNumberOfColumnsThin = 2

    static let MenuFixedWidth: CGFloat = 320
}

struct LightTabCellUX {
    static let TabTitleTextColor = UIColor.black
}

struct DarkTabCellUX {
    static let TabTitleTextColor = UIColor.white
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
    static let BorderWidth: CGFloat = 3

    var style: Style = .light {
        didSet {
            applyStyle(style)
        }
    }

    let backgroundHolder = UIView()
    let screenshotView = UIImageViewAligned()
    let titleText: UILabel
    let favicon: UIImageView = UIImageView()
    let closeButton: UIButton

    var title: UIVisualEffectView!
    var animator: SwipeAnimator!

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        self.backgroundHolder.backgroundColor = UIColor.white
        self.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.backgroundHolder.clipsToBounds = true
        self.backgroundHolder.backgroundColor = TabTrayControllerUX.CellBackgroundColor

        self.screenshotView.contentMode = UIViewContentMode.scaleAspectFill
        self.screenshotView.clipsToBounds = true
        self.screenshotView.isUserInteractionEnabled = false
        self.screenshotView.alignLeft = true
        self.screenshotView.alignTop = true
        screenshotView.backgroundColor = UIConstants.AppBackgroundColor

        self.favicon.backgroundColor = UIColor.clear
        self.favicon.layer.cornerRadius = 2.0
        self.favicon.layer.masksToBounds = true

        self.titleText = UILabel()
        self.titleText.textAlignment = NSTextAlignment.left
        self.titleText.isUserInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold

        self.closeButton = UIButton()
        self.closeButton.setImage(UIImage.templateImageNamed("nav-stop"), for: UIControlState())
        self.closeButton.tintColor = UIColor.lightGray
        self.closeButton.imageEdgeInsets = UIEdgeInsets(equalInset: TabTrayControllerUX.CloseButtonEdgeInset)

        super.init(frame: frame)
        
        self.animator = SwipeAnimator(animatingView: self)
        self.closeButton.addTarget(self, action: #selector(TabCell.close), for: UIControlEvents.touchUpInside)

        contentView.addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.screenshotView)

        // Default style is light
        applyStyle(style)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]
    }

    fileprivate func applyStyle(_ style: Style) {
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

        titleText.backgroundColor = UIColor.clear

        title.contentView.addSubview(self.closeButton)
        title.contentView.addSubview(self.titleText)
        title.contentView.addSubview(self.favicon)

        backgroundHolder.addSubview(title)
        self.title = title
    }

    func setTabSelected(_ isPrivate: Bool) {
        // This creates a border around a tabcell. Using the shadow craetes a border _outside_ of the tab frame.
        layer.shadowColor = (isPrivate ? UIConstants.PrivateModePurple : UIConstants.SystemBlueColor).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 0 // A 0 radius creates a solid border instead of a gradient blur
        layer.masksToBounds = false
        // create a frame that is "BorderWidth" size bigger than the cell
        layer.shadowOffset = CGSize(width: -TabCell.BorderWidth, height: -TabCell.BorderWidth)
        let shadowPath = CGRect(x: 0, y: 0, width: layer.frame.width + (TabCell.BorderWidth * 2), height: layer.frame.height + (TabCell.BorderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: TabTrayControllerUX.CornerRadius+TabCell.BorderWidth).cgPath
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
        screenshotView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: backgroundHolder.frame.size)

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

        closeButton.snp.makeConstraints { make in
            make.size.equalTo(title.snp.height)
            make.trailing.centerY.equalTo(title)
        }

        let top = (TabTrayControllerUX.TextBoxHeight - titleText.bounds.height) / 2.0
        titleText.frame.origin = CGPoint(x: titleText.frame.origin.x, y: max(0, top))
        let shadowPath = CGRect(x: 0, y: 0, width: layer.frame.width + (TabCell.BorderWidth * 2), height: layer.frame.height + (TabCell.BorderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: TabTrayControllerUX.CornerRadius+TabCell.BorderWidth).cgPath
    }

    override func prepareForReuse() {
        // Reset any close animations.
        backgroundHolder.transform = CGAffineTransform.identity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        layer.shadowOffset = CGSize.zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
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
    func close() {
        self.animator.closeWithoutGesture()
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
    func tabTrayRequestsPresentationOf(_ viewController: UIViewController)
}

class TabTrayController: UIViewController {
    let tabManager: TabManager
    let profile: Profile
    weak var delegate: TabTrayDelegate?

    var collectionView: UICollectionView!
    var draggedCell: TabCell?
    var dragOffset: CGPoint = CGPoint.zero
    lazy var toolbar: TrayToolbar = {
        let toolbar = TrayToolbar()
        toolbar.addTabButton.addTarget(self, action: #selector(TabTrayController.didClickAddTab), for: .touchUpInside)
        toolbar.maskButton.addTarget(self, action: #selector(TabTrayController.didTogglePrivateMode), for: .touchUpInside)
        toolbar.deleteButton.addTarget(self, action: #selector(TabTrayController.didTapDelete(_:)), for: .touchUpInside)
        return toolbar
    }()

    fileprivate(set) internal var privateMode: Bool = false {
        didSet {
            tabDataSource.tabs = tabsToDisplay
            toolbar.styleToolbar(privateMode)
            collectionView?.reloadData()
        }
    }

    fileprivate var tabsToDisplay: [Tab] {
        return self.privateMode ? tabManager.privateTabs : tabManager.normalTabs
    }

    fileprivate lazy var emptyPrivateTabsView: EmptyPrivateTabsView = {
        let emptyView = EmptyPrivateTabsView()
        emptyView.learnMoreButton.addTarget(self, action: #selector(TabTrayController.didTapLearnMore), for: UIControlEvents.touchUpInside)
        return emptyView
    }()

    fileprivate lazy var tabDataSource: TabManagerDataSource = {
        return TabManagerDataSource(tabs: self.tabsToDisplay, cellDelegate: self, tabManager: self.tabManager)
    }()

    fileprivate lazy var tabLayoutDelegate: TabLayoutDelegate = {
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
        self.tabManager.removeDelegate(self)
    }

    func dynamicFontChanged(_ notification: Notification) {
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
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIConstants.BottomToolbarHeight, right: 0)
        collectionView.register(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor

        view.addSubview(collectionView)
        view.addSubview(toolbar)

        makeConstraints()

        view.insertSubview(emptyPrivateTabsView, aboveSubview: collectionView)
        emptyPrivateTabsView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self.collectionView)
            make.bottom.equalTo(self.toolbar.snp.top)
        }

        if let tab = tabManager.selectedTab, tab.isPrivate {
            privateMode = true
        }

        // register for previewing delegate to enable peek and pop if force touch feature available
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

        emptyPrivateTabsView.isHidden = !privateTabsAreEmpty()

        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.appWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.appDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TabTrayController.dynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update the trait collection we reference in our layout delegate
        tabLayoutDelegate.traitCollection = traitCollection
        self.collectionView.collectionViewLayout.invalidateLayout()
    }

    fileprivate func cancelExistingGestures() {
        if let visibleCells = self.collectionView.visibleCells as? [TabCell] {
            for cell in visibleCells {
                cell.animator.cancelExistingGestures()
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent //this will need to be fixed
    }

    fileprivate func makeConstraints() {
        collectionView.snp.makeConstraints { make in
            make.left.bottom.right.equalTo(view)
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
        }

        toolbar.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(view)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }
    }

// MARK: Selectors
    func didClickDone() {
        presentingViewController!.dismiss(animated: true, completion: nil)
    }

    func didClickSettingsItem() {
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

    func didClickAddTab() {
        openNewTab()
        LeanplumIntegration.sharedInstance.track(eventName: .openedNewTab, withParameters: ["Source": "Tab Tray" as AnyObject])
    }

    func didTapLearnMore() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        if let langID = Locale.preferredLanguages.first {
            let learnMoreRequest = URLRequest(url: "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(langID)/private-browsing-ios".asURL!)
            openNewTab(learnMoreRequest)
        }
    }

    func didTogglePrivateMode() {
        let scaleDownTransform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        let fromView: UIView
        if !privateTabsAreEmpty(), let snapshot = collectionView.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = collectionView.frame
            view.insertSubview(snapshot, aboveSubview: collectionView)
            fromView = snapshot
        } else {
            fromView = emptyPrivateTabsView
        }

        tabManager.willSwitchTabMode()
        privateMode = !privateMode
        // If we are exiting private mode and we have the close private tabs option selected, make sure
        // we clear out all of the private tabs
        let exitingPrivateMode = !privateMode && tabManager.shouldClearPrivateTabs()

        toolbar.maskButton.setSelected(privateMode, animated: true)
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

    fileprivate func privateTabsAreEmpty() -> Bool {
        return privateMode && tabManager.privateTabs.count == 0
    }

    func changePrivacyMode(_ isPrivate: Bool) {
        if isPrivate != privateMode {
            guard let _ = collectionView else {
                privateMode = isPrivate
                return
            }
            didTogglePrivateMode()
        }
    }
    
    fileprivate func openNewTab(_ request: URLRequest? = nil) {
        toolbar.isUserInteractionEnabled = false

        // We're only doing one update here, but using a batch update lets us delay selecting the tab
        // until after its insert animation finishes.
        self.collectionView.performBatchUpdates({ _ in
            let tab = self.tabManager.addTab(request, isPrivate: self.privateMode)
        }, completion: { finished in
            // The addTab delegate method will pop to the BVC no need to do anything here.
            self.toolbar.isUserInteractionEnabled = true
            if finished {
                if request == nil && NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage {
                    if let bvc = self.navigationController?.topViewController as? BrowserViewController {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            bvc.urlBar.tabLocationViewDidTapLocation(bvc.urlBar.locationView)
                        }
                    }
                }
            }
        })
    }

    fileprivate func closeTabsForCurrentTray() {
        tabManager.removeTabsWithUndoToast(tabsToDisplay)
        self.collectionView.reloadData()
    }
}

// MARK: - App Notifications
extension TabTrayController {
    func appWillResignActiveNotification() {
        if privateMode {
            collectionView.alpha = 0
        }
    }

    func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.collectionView.alpha = 1
        },
        completion: nil)
    }
}

extension TabTrayController: TabSelectionDelegate {
    func didSelectTabAtIndex(_ index: Int) {
        let tab = tabsToDisplay[index]
        tabManager.selectTab(tab)
        _ = self.navigationController?.popViewController(animated: true)
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

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        // Get the index of the added tab from it's set (private or normal)
        guard let index = tabsToDisplay.index(of: tab) else { return }
        if !privateTabsAreEmpty() {
            emptyPrivateTabsView.isHidden = true
        }

        tabDataSource.addTab(tab)
        self.collectionView?.performBatchUpdates({ _ in
            self.collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
        }, completion: { finished in
            if finished {
                tabManager.selectTab(tab)
                // don't pop the tab tray view controller if it is not in the foreground
                if self.presentedViewController == nil {
                    _ = self.navigationController?.popViewController(animated: true)
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
                guard finished && self.privateTabsAreEmpty() else { return }
                self.emptyPrivateTabsView.isHidden = false
            })
        }
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        guard privateMode else {
            return
        }

        if let toast = toast {
            view.addSubview(toast)
            toast.snp.makeConstraints { make in
                make.left.right.equalTo(view)
                make.bottom.equalTo(toolbar.snp.top)
            }
            toast.showToast()
        }
    }
}

extension TabTrayController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatus(for scrollView: UIScrollView) -> String? {
        var visibleCells = collectionView.visibleCells as! [TabCell]
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

        if indexPaths.count == 0 {
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

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(_ animator: SwipeAnimator, viewWillExitContainerBounds: UIView) {
        let tabCell = animator.animatingView as! TabCell
        if let indexPath = collectionView.indexPath(for: tabCell) {
            let tab = tabsToDisplay[indexPath.item]
            tabManager.removeTab(tab)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Closing tab", comment: "Accessibility label (used by assistive technology) notifying the user that the tab is being closed."))
        }
    }
}

extension TabTrayController: TabCellDelegate {
    func tabCellDidClose(_ cell: TabCell) {
        let indexPath = collectionView.indexPath(for: cell)!
        let tab = tabsToDisplay[indexPath.item]
        tabManager.removeTab(tab)
    }
}

extension TabTrayController: SettingsDelegate {
    func settingsOpenURLInNewTab(_ url: URL) {
        let request = URLRequest(url: url)
        openNewTab(request)
    }
}

extension TabTrayController: PhotonActionSheetProtocol {
    func didTapDelete(_ sender: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.AppMenuCloseAllTabsTitleString, style: .default, handler: { _ in self.closeTabsForCurrentTray() }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil))
        controller.popoverPresentationController?.sourceView = sender
        controller.popoverPresentationController?.sourceRect = sender.bounds
        present(controller, animated: true, completion: nil)
    }
}

fileprivate class TabManagerDataSource: NSObject, UICollectionViewDataSource {
    unowned var cellDelegate: TabCellDelegate & SwipeAnimatorDelegate
    fileprivate var tabs: [Tab]
    fileprivate var tabManager: TabManager

    init(tabs: [Tab], cellDelegate: TabCellDelegate & SwipeAnimatorDelegate, tabManager: TabManager) {
        self.cellDelegate = cellDelegate
        self.tabs = tabs
        self.tabManager = tabManager
        super.init()
    }

    /**
     Removes the given tab from the data source

     - parameter tab: Tab to remove

     - returns: The index of the removed tab, -1 if tab did not exist
     */
    func removeTab(_ tabToRemove: Tab) -> Int {
        var index: Int = -1
        for (i, tab) in tabs.enumerated() where tabToRemove === tab {
            index = i
            tabs.remove(at: index)
            break
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

        let tab = tabs[indexPath.item]
        tabCell.style = tab.isPrivate ? .dark : .light
        tabCell.titleText.text = tab.displayTitle
        tabCell.closeButton.tintColor = tab.isPrivate ? UIColor.white : UIColor.gray

        if !tab.displayTitle.isEmpty {
            tabCell.accessibilityLabel = tab.displayTitle
        } else {
            tabCell.accessibilityLabel = tab.url?.aboutComponent ?? "" // If there is no title we are most likely on a home panel.
        }
        tabCell.isAccessibilityElement = true
        tabCell.accessibilityHint = NSLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")

        if let favIcon = tab.displayFavicon {
            tabCell.favicon.sd_setImage(with: URL(string: favIcon.url)!)
        } else {
            let defaultFavicon = UIImage(named: "defaultFavicon")
            if tab.isPrivate {
                tabCell.favicon.image = defaultFavicon
                tabCell.favicon.tintColor = UIColor.white
            } else {
                tabCell.favicon.image = defaultFavicon
            }
        }
        if tab == tabManager.selectedTab {
            tabCell.setTabSelected(tab.isPrivate)
        }
        tabCell.screenshotView.image = tab.screenshot
        return tabCell
    }

    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }
    
    @objc fileprivate func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let fromIndex = sourceIndexPath.item
        let toIndex = destinationIndexPath.item
        tabs.insert(tabs.remove(at: fromIndex), at: toIndex < fromIndex ? toIndex : toIndex - 1)
        tabManager.moveTab(isPrivate: tabs[fromIndex].isPrivate, fromIndex: fromIndex, toIndex: toIndex)
    }
}

@objc protocol TabSelectionDelegate: class {
    func didSelectTabAtIndex(_ index: Int)
}

fileprivate class TabLayoutDelegate: NSObject, UICollectionViewDelegateFlowLayout {
    weak var tabSelectionDelegate: TabSelectionDelegate?

    fileprivate var traitCollection: UITraitCollection
    fileprivate var profile: Profile
    fileprivate var numberOfColumns: Int {
        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            return TabTrayControllerUX.CompactNumberOfColumnsThin
        } else {
            return TabTrayControllerUX.NumberOfColumnsWide
        }
    }

    init(profile: Profile, traitCollection: UITraitCollection) {
        self.profile = profile
        self.traitCollection = traitCollection
        super.init()
    }

    fileprivate func cellHeightForCurrentDevice() -> CGFloat {
        let shortHeight = TabTrayControllerUX.TextBoxHeight * 6

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
        return UIEdgeInsets(equalInset: TabTrayControllerUX.Margin)
    }

    @objc func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    @objc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tabSelectionDelegate?.didSelectTabAtIndex(indexPath.row)
    }
}

struct EmptyPrivateTabsViewUX {
    static let TitleColor = UIColor.white
    static let TitleFont = UIFont.systemFont(ofSize: 22, weight: UIFontWeightMedium)
    static let DescriptionColor = UIColor.white
    static let DescriptionFont = UIFont.systemFont(ofSize: 17)
    static let LearnMoreFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightMedium)
    static let TextMargin: CGFloat = 18
    static let LearnMoreMargin: CGFloat = 30
    static let MaxDescriptionWidth: CGFloat = 250
    static let MinBottomMargin: CGFloat = 10
}

// View we display when there are no private tabs created
fileprivate class EmptyPrivateTabsView: UIView {
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.TitleColor
        label.font = EmptyPrivateTabsViewUX.TitleFont
        label.textAlignment = NSTextAlignment.center
        return label
    }()

    fileprivate var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = EmptyPrivateTabsViewUX.DescriptionColor
        label.font = EmptyPrivateTabsViewUX.DescriptionFont
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = EmptyPrivateTabsViewUX.MaxDescriptionWidth
        return label
    }()

    fileprivate var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(
            NSLocalizedString("Learn More", tableName: "PrivateBrowsing", comment: "Text button displayed when there are no tabs open while in private mode"),
            for: UIControlState())
        button.setTitleColor(UIConstants.PrivateModeTextHighlightColor, for: UIControlState())
        button.titleLabel?.font = EmptyPrivateTabsViewUX.LearnMoreFont
        return button
    }()

    fileprivate var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "largePrivateMask"))
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
            make.bottom.equalTo(titleLabel.snp.top).offset(-EmptyPrivateTabsViewUX.TextMargin)
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

extension TabTrayController: TabPeekDelegate {

    func tabPeekDidAddBookmark(_ tab: Tab) {
        delegate?.tabTrayDidAddBookmark(tab)
    }

    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListClientRecord? {
        return delegate?.tabTrayDidAddToReadingList(tab)
    }

    func tabPeekDidCloseTab(_ tab: Tab) {
        if let index = self.tabDataSource.tabs.index(of: tab),
            let cell = self.collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? TabCell {
            cell.close()
        }
    }

    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {
        delegate?.tabTrayRequestsPresentationOf(viewController)
    }
}

extension TabTrayController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let collectionView = collectionView else { return nil }
        let convertedLocation = self.view.convert(location, to: collectionView)

        guard let indexPath = collectionView.indexPathForItem(at: convertedLocation),
            let cell = collectionView.cellForItem(at: indexPath) else { return nil }

        let tab = tabDataSource.tabs[indexPath.row]
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

// MARK: - Toolbar
class TrayToolbar: UIView {
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

    lazy var maskButton: PrivateModeButton = PrivateModeButton()
    fileprivate let sideOffset: CGFloat = 32

    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
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
            make.right.equalTo(self).offset(-sideOffset)
            make.size.equalTo(toolbarButtonSize)
        }

        addSubview(maskButton)
        maskButton.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.left.equalTo(self).offset(sideOffset)
            make.size.equalTo(toolbarButtonSize)
        }

        styleToolbar(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func styleToolbar(_ isPrivate: Bool) {
        addTabButton.tintColor = isPrivate ? UIColor(rgb: 0xf9f9fa) : UIColor(rgb: 0x272727)
        deleteButton.tintColor = isPrivate ? UIColor(rgb: 0xf9f9fa) : UIColor(rgb: 0x272727)
        backgroundColor = isPrivate ? UIConstants.PrivateModeToolbarTintColor : UIColor(rgb: 0xf9f9fa)
        maskButton.styleForMode(privateMode: isPrivate)
    }
}
