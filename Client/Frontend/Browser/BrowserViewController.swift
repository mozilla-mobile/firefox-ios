/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Photos
import UIKit
import WebKit
import Shared
import Storage
import SnapKit
import XCGLogger
import Alamofire
import Account
import ReadingList
import MobileCoreServices
import WebImage
import SwiftyJSON

private let log = Logger.browserLogger

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"
private let KVOURL = "URL"
private let KVOCanGoBack = "canGoBack"
private let KVOCanGoForward = "canGoForward"
private let KVOContentSize = "contentSize"

private let ActionSheetTitleMaxLength = 120

private struct BrowserViewControllerUX {
    fileprivate static let BackgroundColor = UIConstants.AppBackgroundColor
    fileprivate static let ShowHeaderTapAreaHeight: CGFloat = 32
    fileprivate static let BookmarkStarAnimationDuration: Double = 0.5
    fileprivate static let BookmarkStarAnimationOffset: CGFloat = 80
}

class BrowserViewController: UIViewController {
    var homePanelController: HomePanelViewController?
    var webViewContainer: UIView!
    var menuViewController: MenuViewController?
    var urlBar: URLBarView!
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    fileprivate var statusBarOverlay: UIView!
    fileprivate(set) var toolbar: TabToolbar?
    fileprivate var searchController: SearchViewController?
    fileprivate var screenshotHelper: ScreenshotHelper!
    fileprivate var homePanelIsInline = false
    fileprivate var searchLoader: SearchLoader!
    fileprivate let snackBars = UIView()
    fileprivate let webViewContainerToolbar = UIView()
    fileprivate var findInPageBar: FindInPageBar?
    fileprivate let findInPageContainer = UIView()

    fileprivate lazy var mailtoLinkHandler: MailtoLinkHandler = MailtoLinkHandler()

    lazy fileprivate var customSearchEngineButton: UIButton = {
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "AddSearch")?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        searchButton.addTarget(self, action: #selector(BrowserViewController.addCustomSearchEngineForFocusedElement), for: .touchUpInside)
        searchButton.accessibilityIdentifier = "BrowserViewController.customSearchEngineButton"
        return searchButton
    }()

    fileprivate var customSearchBarButton: UIBarButtonItem?

    // popover rotation handling
    fileprivate var displayedPopoverController: UIViewController?
    fileprivate var updateDisplayedPopoverProperties: (() -> Void)?

    fileprivate var openInHelper: OpenInHelper?

    // location label actions
    fileprivate var pasteGoAction: AccessibleAction!
    fileprivate var pasteAction: AccessibleAction!
    fileprivate var copyAddressAction: AccessibleAction!

    fileprivate weak var tabTrayController: TabTrayController!

    fileprivate let profile: Profile
    let tabManager: TabManager

    // These views wrap the urlbar and toolbar to provide background effects on them
    var header: BlurWrapper!
    var headerBackdrop: UIView!
    var footer: UIView!
    var footerBackdrop: UIView!
    fileprivate var footerBackground: BlurWrapper?
    fileprivate var topTouchArea: UIButton!
    let urlBarTopTabsContainer = UIView(frame: CGRect.zero)

    // Backdrop used for displaying greyed background for private tabs
    var webViewContainerBackdrop: UIView!

    fileprivate var scrollController = TabScrollingController()

    fileprivate var keyboardState: KeyboardState?

    var didRemoveAllTabs: Bool = false
    var pendingToast: ButtonToast? // A toast that might be waiting for BVC to appear before displaying

    let WhiteListedUrls = ["\\/\\/itunes\\.apple\\.com\\/"]

    // Tracking navigation items to record history types.
    // TODO: weak references?
    var ignoredNavigation = Set<WKNavigation>()
    var typedNavigation = [WKNavigation: VisitType]()
    var navigationToolbar: TabToolbarProtocol {
        return toolbar ?? urlBar
    }
    
    var topTabsViewController: TopTabsViewController?
    let topTabsContainer = UIView(frame: CGRect.zero)

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        self.readerModeCache = DiskReaderModeCache.sharedInstance
        super.init(nibName: nil, bundle: nil)
        didInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        displayedPopoverController?.dismiss(animated: true) {
            self.displayedPopoverController = nil
        }

        coordinator.animate(alongsideTransition: { context in
            self.scrollController.updateMinimumZoom()
            self.topTabsViewController?.scrollToCurrentTab(false, centerCell: false)
            if let popover = self.displayedPopoverController {
                self.updateDisplayedPopoverProperties?()
                self.present(popover, animated: true, completion: nil)
            }
        }, completion: { _ in
            self.scrollController.setMinimumZoom()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.debug("BVC received memory warning")
    }

    fileprivate func didInit() {
        screenshotHelper = ScreenshotHelper(controller: self)
        tabManager.addDelegate(self)
        tabManager.addNavigationDelegate(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    func shouldShowFooterForTraitCollection(_ previousTraitCollection: UITraitCollection) -> Bool {
        return previousTraitCollection.verticalSizeClass != .compact &&
               previousTraitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabsForTraitCollection(_ newTraitCollection: UITraitCollection) -> Bool {
        guard AppConstants.MOZ_TOP_TABS else {
            return false
        }
        return newTraitCollection.verticalSizeClass == .regular &&
            newTraitCollection.horizontalSizeClass == .regular
    }

    func toggleSnackBarVisibility(show: Bool) {
        if show {
            UIView.animate(withDuration: 0.1, animations: { self.snackBars.isHidden = false })
        } else {
            snackBars.isHidden = true
        }
    }

    fileprivate func updateToolbarStateForTraitCollection(_ newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator? = nil) {
        let showToolbar = shouldShowFooterForTraitCollection(newCollection)
        let showTopTabs = shouldShowTopTabsForTraitCollection(newCollection)

        if UI_USER_INTERFACE_IDIOM() == .pad,
            let mvc = menuViewController, showToolbar != (toolbar != nil) {
            // Hide the menu, and then re-open it so that the menu is always the correct one for the given traits
            mvc.dismiss(animated: true, completion: nil)
            coordinator?.animate(alongsideTransition: nil, completion: { _ in
                self.tabToolbarDidPressMenu(self.navigationToolbar, button: self.navigationToolbar.menuButton)
            })
        }

        urlBar.topTabsIsShowing = showTopTabs
        urlBar.setShowToolbar(!showToolbar)
        toolbar?.removeFromSuperview()
        toolbar?.tabToolbarDelegate = nil
        footerBackground?.removeFromSuperview()
        footerBackground = nil
        toolbar = nil

        if showToolbar {
            toolbar = TabToolbar()
            toolbar?.tabToolbarDelegate = self
            footerBackground = BlurWrapper(view: toolbar!)
            footerBackground?.translatesAutoresizingMaskIntoConstraints = false

            // Need to reset the proper blur style
            if let selectedTab = tabManager.selectedTab, selectedTab.isPrivate {
                footerBackground!.blurStyle = .dark
                toolbar?.applyTheme(Theme.PrivateMode)
            }
            footer.addSubview(footerBackground!)
        }
        
        if showTopTabs {
            if topTabsViewController == nil {
                let topTabsViewController = TopTabsViewController(tabManager: tabManager)
                topTabsViewController.delegate = self
                addChildViewController(topTabsViewController)
                topTabsViewController.view.frame = topTabsContainer.frame
                topTabsContainer.addSubview(topTabsViewController.view)
                topTabsViewController.view.snp.makeConstraints { make in
                    make.edges.equalTo(topTabsContainer)
                    make.height.equalTo(TopTabsUX.TopTabsViewHeight)
                }
                self.topTabsViewController = topTabsViewController
            }
            topTabsContainer.snp.updateConstraints { make in
                make.height.equalTo(TopTabsUX.TopTabsViewHeight)
            }
            header.disableBlur = true
        } else {
            topTabsContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            topTabsViewController?.view.removeFromSuperview()
            topTabsViewController?.removeFromParentViewController()
            topTabsViewController = nil
            header.disableBlur = false
        }

        view.setNeedsUpdateConstraints()
        if let home = homePanelController {
            home.view.setNeedsUpdateConstraints()
        }

        if let tab = tabManager.selectedTab,
               let webView = tab.webView {
            updateURLBarDisplayURL(tab)
            navigationToolbar.updateBackStatus(webView.canGoBack)
            navigationToolbar.updateForwardStatus(webView.canGoForward)
            navigationToolbar.updateReloadStatus(tab.loading)
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        // During split screen launching on iPad, this callback gets fired before viewDidLoad gets a chance to
        // set things up. Make sure to only update the toolbar state if the view is ready for it.
        if isViewLoaded {
            updateToolbarStateForTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        }

        displayedPopoverController?.dismiss(animated: true, completion: nil)
        coordinator.animate(alongsideTransition: { context in
            self.scrollController.showToolbars(animated: false)
            }, completion: nil)
    }

    func SELappDidEnterBackgroundNotification() {
        displayedPopoverController?.dismiss(animated: false) {
            self.displayedPopoverController = nil
        }
    }

    func SELtappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

    func SELappWillResignActiveNotification() {
        // Dismiss any popovers that might be visible
        displayedPopoverController?.dismiss(animated: false) {
            self.displayedPopoverController = nil
        }

        // Dismiss menu if presenting
        menuViewController?.dismiss(animated: true, completion: nil)

        // If we are displying a private tab, hide any elements in the tab that we wouldn't want shown
        // when the app is in the home switcher
        guard let privateTab = tabManager.selectedTab, privateTab.isPrivate else {
            return
        }

        webViewContainerBackdrop.alpha = 1
        webViewContainer.alpha = 0
        urlBar.locationContainer.alpha = 0
        topTabsViewController?.switchForegroundStatus(isInForeground: false)
        presentedViewController?.popoverPresentationController?.containerView?.alpha = 0
        presentedViewController?.view.alpha = 0
    }

    func SELappDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.webViewContainer.alpha = 1
            self.urlBar.locationContainer.alpha = 1
            self.topTabsViewController?.switchForegroundStatus(isInForeground: true)
            self.presentedViewController?.popoverPresentationController?.containerView?.alpha = 1
            self.presentedViewController?.view.alpha = 1
            self.view.backgroundColor = UIColor.clear
        }, completion: { _ in
            self.webViewContainerBackdrop.alpha = 0
        })

        // Re-show toolbar which might have been hidden during scrolling (prior to app moving into the background)
        scrollController.showToolbars(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BookmarkStatusChangedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }

    override func viewDidLoad() {
        log.debug("BVC viewDidLoad…")
        super.viewDidLoad()
        log.debug("BVC super viewDidLoad called.")
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELBookmarkStatusDidChange(_:)), name: NSNotification.Name(rawValue: BookmarkStatusChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappDidEnterBackgroundNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        KeyboardHelper.defaultHelper.addDelegate(self)

        log.debug("BVC adding footer and header…")
        footerBackdrop = UIView()
        footerBackdrop.backgroundColor = UIColor.white
        view.addSubview(footerBackdrop)
        headerBackdrop = UIView()
        headerBackdrop.backgroundColor = UIColor.white
        view.addSubview(headerBackdrop)

        log.debug("BVC setting up webViewContainer…")
        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.gray
        webViewContainerBackdrop.alpha = 0
        view.addSubview(webViewContainerBackdrop)

        webViewContainer = UIView()
        webViewContainer.addSubview(webViewContainerToolbar)
        view.addSubview(webViewContainer)

        log.debug("BVC setting up status bar…")
        // Temporary work around for covering the non-clipped web view content
        statusBarOverlay = UIView()
        statusBarOverlay.backgroundColor = BrowserViewControllerUX.BackgroundColor
        view.addSubview(statusBarOverlay)

        log.debug("BVC setting up top touch area…")
        topTouchArea = UIButton()
        topTouchArea.isAccessibilityElement = false
        topTouchArea.addTarget(self, action: #selector(BrowserViewController.SELtappedTopArea), for: UIControlEvents.touchUpInside)
        view.addSubview(topTouchArea)

        log.debug("BVC setting up URL bar…")
        // Setup the URL bar, wrapped in a view to get transparency effect
        urlBar = URLBarView()
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.tabToolbarDelegate = self
        header = BlurWrapper(view: urlBarTopTabsContainer)
        urlBarTopTabsContainer.addSubview(urlBar)
        urlBarTopTabsContainer.addSubview(topTabsContainer)
        view.addSubview(header)

        // UIAccessibilityCustomAction subclass holding an AccessibleAction instance does not work, thus unable to generate AccessibleActions and UIAccessibilityCustomActions "on-demand" and need to make them "persistent" e.g. by being stored in BVC
        pasteGoAction = AccessibleAction(name: NSLocalizedString("Paste & Go", comment: "Paste the URL into the location bar and visit"), handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.general.string {
                self.urlBar(self.urlBar, didSubmitText: pasteboardContents)
                return true
            }
            return false
        })
        pasteAction = AccessibleAction(name: NSLocalizedString("Paste", comment: "Paste the URL into the location bar"), handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.general.string {
                // Enter overlay mode and fire the text entered callback to make the search controller appear.
                self.urlBar.enterOverlayMode(pasteboardContents, pasted: true)
                self.urlBar(self.urlBar, didEnterText: pasteboardContents)
                return true
            }
            return false
        })
        copyAddressAction = AccessibleAction(name: NSLocalizedString("Copy Address", comment: "Copy the URL from the location bar"), handler: { () -> Bool in
            if let url = self.urlBar.currentURL {
                UIPasteboard.general.url = url as URL
            }
            return true
        })

        log.debug("BVC setting up search loader…")
        searchLoader = SearchLoader(profile: profile, urlBar: urlBar)

        footer = UIView()
        self.view.addSubview(footer)
        self.view.addSubview(snackBars)
        snackBars.backgroundColor = UIColor.clear
        self.view.addSubview(findInPageContainer)

        scrollController.urlBar = urlBar
        scrollController.header = header
        scrollController.footer = footer
        scrollController.snackBars = snackBars
        scrollController.webViewContainerToolbar = webViewContainerToolbar

        log.debug("BVC updating toolbar state…")
        self.updateToolbarStateForTraitCollection(self.traitCollection)

        log.debug("BVC setting up constraints…")
        setupConstraints()
        log.debug("BVC done.")
    }

    fileprivate func setupConstraints() {
        topTabsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.header)
            make.top.equalTo(urlBarTopTabsContainer)
        }
        
        urlBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(urlBarTopTabsContainer)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.top.equalTo(topTabsContainer.snp.bottom)
        }

        header.snp.makeConstraints { make in
            scrollController.headerTopConstraint = make.top.equalTo(self.topLayoutGuide.snp.bottom).constraint
            make.left.right.equalTo(self.view)
        }

        headerBackdrop.snp.makeConstraints { make in
            make.edges.equalTo(self.header)
        }

        webViewContainerBackdrop.snp.makeConstraints { make in
            make.edges.equalTo(webViewContainer)
        }

        webViewContainerToolbar.snp.makeConstraints { make in
            make.left.right.top.equalTo(webViewContainer)
            make.height.equalTo(0)
        }
    }

    override func viewDidLayoutSubviews() {
        log.debug("BVC viewDidLayoutSubviews…")
        super.viewDidLayoutSubviews()
        statusBarOverlay.snp.remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(self.topLayoutGuide.length)
        }
        self.appDidUpdateState(getCurrentAppState())
        log.debug("BVC done.")
    }

    func loadQueuedTabs() {
        log.debug("Loading queued tabs in the background.")

        // Chain off of a trivial deferred in order to run on the background queue.
        succeed().upon() { res in
            self.dequeueQueuedTabs()
        }
    }

    fileprivate func dequeueQueuedTabs() {
        assert(!Thread.current.isMainThread, "This must be called in the background.")
        self.profile.queue.getQueuedTabs() >>== { cursor in

            // This assumes that the DB returns rows in some kind of sane order.
            // It does in practice, so WFM.
            log.debug("Queue. Count: \(cursor.count).")
            if cursor.count <= 0 {
                return
            }

            let urls = cursor.flatMap { $0?.url.asURL }
            if !urls.isEmpty {
                DispatchQueue.main.async {
                    self.tabManager.addTabsForURLs(urls, zombie: false)
                }
            }

            // Clear *after* making an attempt to open. We're making a bet that
            // it's better to run the risk of perhaps opening twice on a crash,
            // rather than losing data.
            self.profile.queue.clearQueuedTabs()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        log.debug("BVC viewWillAppear.")
        super.viewWillAppear(animated)
        log.debug("BVC super.viewWillAppear done.")

        // On iPhone, if we are about to show the On-Boarding, blank out the tab so that it does
        // not flash before we present. This change of alpha also participates in the animation when
        // the intro view is dismissed.
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.alpha = (profile.prefs.intForKey(IntroViewControllerSeenProfileKey) != nil) ? 1.0 : 0.0
        }

        if PLCrashReporter.shared().hasPendingCrashReport() {
            PLCrashReporter.shared().purgePendingCrashReport()
            showRestoreTabsAlert()
        } else {
            log.debug("Restoring tabs.")
            tabManager.restoreTabs()
            log.debug("Done restoring tabs.")
        }

        log.debug("Updating tab count.")
        updateTabCountUsingTabManager(tabManager, animated: false)
        log.debug("BVC done.")

        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(BrowserViewController.openSettings),
                                                         name: NSNotification.Name(rawValue: NotificationStatusNotificationTapped),
                                                         object: nil)
    }

    fileprivate func showRestoreTabsAlert() {
        guard shouldRestoreTabs() else {
            self.tabManager.addTabAndSelect()
            return
        }

        let alert = UIAlertController.restoreTabsAlert(
            okayCallback: { _ in
                self.tabManager.restoreTabs()
                self.updateTabCountUsingTabManager(self.tabManager, animated: false)
            },
            noCallback: { _ in
                self.tabManager.addTabAndSelect()
                self.updateTabCountUsingTabManager(self.tabManager, animated: false)
            }
        )

        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func shouldRestoreTabs() -> Bool {
        guard let tabsToRestore = TabManager.tabsToRestore() else { return false }
        let onlyNoHistoryTabs = !tabsToRestore.every {
            if $0.sessionData?.urls.count ?? 0 > 1 {
                if let url = $0.sessionData?.urls.first {
                    return !url.isAboutHomeURL
                }
            }
            return false
        }
        return !onlyNoHistoryTabs && !DebugSettingsBundleOptions.skipSessionRestore
    }

    override func viewDidAppear(_ animated: Bool) {
        log.debug("BVC viewDidAppear.")
        presentIntroViewController()
        log.debug("BVC intro presented.")
        self.webViewContainerToolbar.isHidden = false

        screenshotHelper.viewIsVisible = true
        log.debug("BVC taking pending screenshots….")
        screenshotHelper.takePendingScreenshots(tabManager.tabs)
        log.debug("BVC done taking screenshots.")

        log.debug("BVC calling super.viewDidAppear.")
        super.viewDidAppear(animated)
        log.debug("BVC done.")

        if shouldShowWhatsNewTab() {
            if let whatsNewURL = SupportUtils.URLForTopic("new-ios") {
                self.openURLInNewTab(whatsNewURL, isPrivileged: false)
                profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
            }
        }

        if let toast = self.pendingToast {
            self.pendingToast = nil
            show(buttonToast: toast, afterWaiting: ButtonToastUX.ToastDelay)
        }
        showQueuedAlertIfAvailable()
    }

    fileprivate func shouldShowWhatsNewTab() -> Bool {
        guard let latestMajorAppVersion = profile.prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first else {
            return DeviceInfo.hasConnectivity()
        }

        return latestMajorAppVersion != AppInfo.majorAppVersion && DeviceInfo.hasConnectivity()
    }

    fileprivate func showQueuedAlertIfAvailable() {
        if let queuedAlertInfo = tabManager.selectedTab?.dequeueJavascriptAlertPrompt() {
            let alertController = queuedAlertInfo.alertController()
            alertController.delegate = self
            present(alertController, animated: true, completion: nil)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        screenshotHelper.viewIsVisible = false
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationStatusNotificationTapped), object: nil)
    }

    func resetBrowserChrome() {
        // animate and reset transform for tab chrome
        urlBar.updateAlphaForSubviews(1)
        footer.alpha = 1

        [header,
            footer,
            readerModeBar,
            footerBackdrop,
            headerBackdrop].forEach { view in
                view?.transform = CGAffineTransform.identity
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        topTouchArea.snp.remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(BrowserViewControllerUX.ShowHeaderTapAreaHeight)
        }

        readerModeBar?.snp.remakeConstraints { make in
            make.top.equalTo(self.header.snp.bottom)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.leading.trailing.equalTo(self.view)
        }

        webViewContainer.snp.remakeConstraints { make in
            make.left.right.equalTo(self.view)

            if let readerModeBarBottom = readerModeBar?.snp.bottom {
                make.top.equalTo(readerModeBarBottom)
            } else {
                make.top.equalTo(self.header.snp.bottom)
            }

            let findInPageHeight = (findInPageBar == nil) ? 0 : UIConstants.ToolbarHeight
            if let toolbar = self.toolbar {
                make.bottom.equalTo(toolbar.snp.top).offset(-findInPageHeight)
            } else {
                make.bottom.equalTo(self.view).offset(-findInPageHeight)
            }
        }

        // Setup the bottom toolbar
        toolbar?.snp.remakeConstraints { make in
            make.edges.equalTo(self.footerBackground!)
            make.height.equalTo(UIConstants.ToolbarHeight)
        }

        footer.snp.remakeConstraints { make in
            scrollController.footerBottomConstraint = make.bottom.equalTo(self.view.snp.bottom).constraint
            make.top.equalTo(self.snackBars.snp.top)
            make.leading.trailing.equalTo(self.view)
        }

        footerBackdrop.snp.remakeConstraints { make in
            make.edges.equalTo(self.footer)
        }

        updateSnackBarConstraints()
        footerBackground?.snp.remakeConstraints { make in
            make.bottom.left.right.equalTo(self.footer)
            make.height.equalTo(UIConstants.ToolbarHeight)
        }
        urlBar.setNeedsUpdateConstraints()

        // Remake constraints even if we're already showing the home controller.
        // The home controller may change sizes if we tap the URL bar while on about:home.
        homePanelController?.view.snp.remakeConstraints { make in
            make.top.equalTo(self.urlBar.snp.bottom)
            make.left.right.equalTo(self.view)
            if self.homePanelIsInline {
                make.bottom.equalTo(self.toolbar?.snp.top ?? self.view.snp.bottom)
            } else {
                make.bottom.equalTo(self.view.snp.bottom)
            }
        }

        findInPageContainer.snp.remakeConstraints { make in
            make.left.right.equalTo(self.view)

            if let keyboardHeight = keyboardState?.intersectionHeightForView(self.view), keyboardHeight > 0 {
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            } else if let toolbar = self.toolbar {
                make.bottom.equalTo(toolbar.snp.top)
            } else {
                make.bottom.equalTo(self.view)
            }
        }
    }

    fileprivate func showHomePanelController(inline: Bool) {
        log.debug("BVC showHomePanelController.")
        homePanelIsInline = inline

        if homePanelController == nil {
            let homePanelController = HomePanelViewController()
            homePanelController.profile = profile
            homePanelController.delegate = self
            homePanelController.appStateDelegate = self
            homePanelController.url = tabManager.selectedTab?.url?.displayURL
            homePanelController.view.alpha = 0
            self.homePanelController = homePanelController

            addChildViewController(homePanelController)
            view.addSubview(homePanelController.view)
            homePanelController.didMove(toParentViewController: self)
        }
        guard let homePanelController = self.homePanelController else {
            assertionFailure("homePanelController is still nil after assignment.")
            return
        }

        let panelNumber = tabManager.selectedTab?.url?.fragment

        // splitting this out to see if we can get better crash reports when this has a problem
        var newSelectedButtonIndex = 0
        if let numberArray = panelNumber?.components(separatedBy: "=") {
            if let last = numberArray.last, let lastInt = Int(last) {
                newSelectedButtonIndex = lastInt
            }
        }
        homePanelController.selectedPanel = HomePanelType(rawValue: newSelectedButtonIndex)
        homePanelController.isPrivateMode = tabManager.selectedTab?.isPrivate ?? false

        // We have to run this animation, even if the view is already showing because there may be a hide animation running
        // and we want to be sure to override its results.
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            homePanelController.view.alpha = 1
        }, completion: { finished in
            if finished {
                self.webViewContainer.accessibilityElementsHidden = true
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            }
        })
        view.setNeedsUpdateConstraints()
        log.debug("BVC done with showHomePanelController.")
    }

    fileprivate func hideHomePanelController() {
        if let controller = homePanelController {
            self.homePanelController = nil
            UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.willMove(toParentViewController: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.webViewContainer.accessibilityElementsHidden = false
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)

                // Refresh the reading view toolbar since the article record may have changed
                if let readerMode = self.tabManager.selectedTab?.getHelper(name: ReaderMode.name()) as? ReaderMode, readerMode.state == .active {
                    self.showReaderModeBar(animated: false)
                }
            })
        }
    }

    fileprivate func updateInContentHomePanel(_ url: URL?) {
        if !urlBar.inOverlayMode {
            if let url = url, url.isAboutHomeURL {
                showHomePanelController(inline: true)
            } else {
                hideHomePanelController()
            }
        }
    }

    fileprivate func showSearchController() {
        if searchController != nil {
            return
        }

        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        searchController = SearchViewController(isPrivate: isPrivate)
        searchController!.searchEngines = profile.searchEngines
        searchController!.searchDelegate = self
        searchController!.profile = self.profile

        searchLoader.addListener(searchController!)

        addChildViewController(searchController!)
        view.addSubview(searchController!.view)
        searchController!.view.snp.makeConstraints { make in
            make.top.equalTo(self.urlBar.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
            return
        }

        homePanelController?.view?.isHidden = true

        searchController!.didMove(toParentViewController: self)
    }

    fileprivate func hideSearchController() {
        if let searchController = searchController {
            searchController.willMove(toParentViewController: nil)
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            self.searchController = nil
            homePanelController?.view?.isHidden = false
        }
    }

    fileprivate func finishEditingAndSubmit(_ url: URL, visitType: VisitType) {
        urlBar.currentURL = url
        urlBar.leaveOverlayMode()

        guard let tab = tabManager.selectedTab else {
            return
        }

        if let webView = tab.webView {
            resetSpoofedUserAgentIfRequired(webView, newURL: url)
        }

        if let nav = tab.loadRequest(PrivilegedRequest(url: url) as URLRequest) {
            self.recordNavigationInTab(tab, navigation: nav, visitType: visitType)
        }
    }

    func addBookmark(_ tabState: TabState) {
        guard let url = tabState.url else { return }
        let absoluteString = url.absoluteString
        let shareItem = ShareItem(url: absoluteString, title: tabState.title, favicon: tabState.favicon)
        profile.bookmarks.shareItem(shareItem)
        var userData = [QuickActions.TabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActions.TabTitleKey] = title
        }
        QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
            withUserData: userData,
            toApplication: UIApplication.shared)
        if let tab = tabManager.getTabForURL(url) {
            tab.isBookmarked = true
        }
    }

    fileprivate func animateBookmarkStar() {
        let offset: CGFloat
        let button: UIButton!

        if let toolbar: TabToolbar = self.toolbar {
            offset = BrowserViewControllerUX.BookmarkStarAnimationOffset * -1
            button = toolbar.bookmarkButton
        } else {
            offset = BrowserViewControllerUX.BookmarkStarAnimationOffset
            button = self.urlBar.bookmarkButton
        }

        JumpAndSpinAnimator.animateFromView(button.imageView ?? button, offset: offset, completion: nil)
    }

    fileprivate func removeBookmark(_ tabState: TabState) {
        guard let url = tabState.url else { return }
        let absoluteString = url.absoluteString
        profile.bookmarks.modelFactory >>== {
            $0.removeByURL(absoluteString)
                .uponQueue(DispatchQueue.main) { res in
                if res.isSuccess {
                    if let tab = self.tabManager.getTabForURL(url) {
                        tab.isBookmarked = false
                    }
                }
            }
        }
    }

    func SELBookmarkStatusDidChange(_ notification: Notification) {
        if let bookmark = notification.object as? BookmarkItem {
            if bookmark.url == urlBar.currentURL?.absoluteString {
                if let userInfo = notification.userInfo as? Dictionary<String, Bool> {
                    if userInfo["added"] != nil {
                        if let tab = self.tabManager.getTabForURL(urlBar.currentURL!) {
                            tab.isBookmarked = false
                        }
                    }
                }
            }
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        if urlBar.inOverlayMode {
            urlBar.SELdidClickCancel()
            return true
        } else if let selectedTab = tabManager.selectedTab, selectedTab.canGoBack {
            selectedTab.goBack()
            return true
        }
        return false
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let webView = object as! WKWebView
        guard let path = keyPath else { assertionFailure("Unhandled KVO key: \(keyPath)"); return }
        switch path {
        case KVOEstimatedProgress:
            guard webView == tabManager.selectedTab?.webView,
                let progress = change?[NSKeyValueChangeKey.newKey] as? Float else { break }
            
            urlBar.updateProgressBar(progress)
        case KVOLoading:
            guard let loading = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }

            if webView == tabManager.selectedTab?.webView {
                navigationToolbar.updateReloadStatus(loading)
            }

            if !loading {
                runScriptsOnWebView(webView)
            }
        case KVOURL:
            guard let tab = tabManager[webView] else { break }

            // To prevent spoofing, only change the URL immediately if the new URL is on
            // the same origin as the current URL. Otherwise, do nothing and wait for
            // didCommitNavigation to confirm the page load.
            if tab.url?.origin == webView.url?.origin {
                tab.url = webView.url

                if tab === tabManager.selectedTab && !tab.restoring {
                    updateUIForReaderHomeStateForTab(tab)
                }
            }
        case KVOCanGoBack:
            guard webView == tabManager.selectedTab?.webView,
                let canGoBack = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }
            
            navigationToolbar.updateBackStatus(canGoBack)
        case KVOCanGoForward:
            guard webView == tabManager.selectedTab?.webView,
                let canGoForward = change?[NSKeyValueChangeKey.newKey] as? Bool else { break }

            navigationToolbar.updateForwardStatus(canGoForward)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath)")
        }
    }

    fileprivate func runScriptsOnWebView(_ webView: WKWebView) {
        webView.evaluateJavaScript("__firefox__.favicons.getFavicons()", completionHandler: nil)

        if AppConstants.MOZ_CONTENT_METADATA_PARSING {
            webView.evaluateJavaScript("__firefox__.metadata.extractMetadata()", completionHandler: nil)
        }
    }

    fileprivate func updateUIForReaderHomeStateForTab(_ tab: Tab) {
        updateURLBarDisplayURL(tab)
        scrollController.showToolbars(animated: false)

        if let url = tab.url {
            if url.isReaderModeURL {
                showReaderModeBar(animated: false)
                NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
            } else {
                hideReaderModeBar(animated: false)
                NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
            }

            updateInContentHomePanel(url as URL)
        }
    }

    fileprivate func isWhitelistedUrl(_ url: URL) -> Bool {
        for entry in WhiteListedUrls {
            if let _ = url.absoluteString.range(of: entry, options: .regularExpression) {
                return UIApplication.shared.canOpenURL(url)
            }
        }
        return false
    }

    /// Updates the URL bar text and button states.
    /// Call this whenever the page URL changes.
    fileprivate func updateURLBarDisplayURL(_ tab: Tab) {
        urlBar.currentURL = tab.url?.displayURL

        let isPage = tab.url?.displayURL?.isWebPage() ?? false
        navigationToolbar.updatePageStatus(isPage)

        guard let url = tab.url?.displayURL?.absoluteString else {
            return
        }

        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(url).uponQueue(DispatchQueue.main) { [weak tab] result in
                guard let bookmarked = result.successValue else {
                    log.error("Error getting bookmark status: \(result.failureValue).")
                    return
                }
                tab?.isBookmarked = bookmarked
            }
        }
    }
    // Mark: Opening New Tabs

    func switchToPrivacyMode(isPrivate: Bool ) {
        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

        let tabTrayController = self.tabTrayController ?? TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)
        if tabTrayController.privateMode != isPrivate {
            tabTrayController.changePrivacyMode(isPrivate)
        }
        self.tabTrayController = tabTrayController
    }

    func switchToTabForURLOrOpen(_ url: URL, isPrivate: Bool = false, isPrivileged: Bool) {
        popToBVC()
        if let tab = tabManager.getTabForURL(url) {
            tabManager.selectTab(tab)
        } else {
            openURLInNewTab(url, isPrivate: isPrivate, isPrivileged: isPrivileged)
        }
    }

    func openURLInNewTab(_ url: URL?, isPrivate: Bool = false, isPrivileged: Bool) {
        if let selectedTab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(selectedTab)
        }
        let request: URLRequest?
        if let url = url {
            request = isPrivileged ? PrivilegedRequest(url: url) as URLRequest : URLRequest(url: url)
        } else {
            request = nil
        }

        switchToPrivacyMode(isPrivate: isPrivate)
        let _ = tabManager.addTabAndSelect(request, isPrivate: isPrivate)
        if url == nil && NewTabAccessors.getNewTabPage(profile.prefs) == .blankPage {
            urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
        }
    }

    func openBlankNewTab(isPrivate: Bool = false) {
        popToBVC()
        openURLInNewTab(nil, isPrivate: isPrivate, isPrivileged: true)
    }

    fileprivate func popToBVC() {
        guard let currentViewController = navigationController?.topViewController else {
                return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        if currentViewController != self {
            let _ = self.navigationController?.popViewController(animated: true)
        } else if urlBar.inOverlayMode {
            urlBar.SELdidClickCancel()
        }
    }

    // Mark: User Agent Spoofing

    fileprivate func resetSpoofedUserAgentIfRequired(_ webView: WKWebView, newURL: URL) {
        // Reset the UA when a different domain is being loaded
        if webView.url?.host != newURL.host {
            webView.customUserAgent = nil
        }
    }

    fileprivate func restoreSpoofedUserAgentIfRequired(_ webView: WKWebView, newRequest: URLRequest) {
        // Restore any non-default UA from the request's header
        let ua = newRequest.value(forHTTPHeaderField: "User-Agent")
        webView.customUserAgent = ua != UserAgent.defaultUserAgent() ? ua : nil
    }

    fileprivate func presentActivityViewController(_ url: URL, tab: Tab? = nil, sourceView: UIView?, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection) {
        var activities = [UIActivity]()

        let findInPageActivity = FindInPageActivity() { [unowned self] in
            self.updateFindInPageVisibility(visible: true)
        }
        activities.append(findInPageActivity)

        if let tab = tab, (tab.getHelper(name: ReaderMode.name()) as? ReaderMode)?.state != .active {
            let requestDesktopSiteActivity = RequestDesktopSiteActivity(requestMobileSite: tab.desktopSite) { [unowned tab] in
                tab.toggleDesktopSite()
            }
            activities.append(requestDesktopSiteActivity)
        }

        let helper = ShareExtensionHelper(url: url, tab: tab, activities: activities)

        let controller = helper.createActivityViewController({ [unowned self] completed, _ in
            // After dismissing, check to see if there were any prompts we queued up
            self.showQueuedAlertIfAvailable()

            // Usually the popover delegate would handle nil'ing out the references we have to it
            // on the BVC when displaying as a popover but the delegate method doesn't seem to be
            // invoked on iOS 10. See Bug 1297768 for additional details.
            self.displayedPopoverController = nil
            self.updateDisplayedPopoverProperties = nil

            if completed {
                // We don't know what share action the user has chosen so we simply always
                // update the toolbar and reader mode bar to reflect the latest status.
                if let tab = tab {
                    self.updateURLBarDisplayURL(tab)
                }
                self.updateReaderModeBar()
            }
        })

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.permittedArrowDirections = arrowDirection
            popoverPresentationController.delegate = self
        }

        self.present(controller, animated: true, completion: nil)
    }

    fileprivate func updateFindInPageVisibility(visible: Bool) {
        if visible {
            if findInPageBar == nil {
                let findInPageBar = FindInPageBar()
                self.findInPageBar = findInPageBar
                findInPageBar.delegate = self
                findInPageContainer.addSubview(findInPageBar)

                findInPageBar.snp.makeConstraints { make in
                    make.edges.equalTo(findInPageContainer)
                    make.height.equalTo(UIConstants.ToolbarHeight)
                }

                updateViewConstraints()

                // We make the find-in-page bar the first responder below, causing the keyboard delegates
                // to fire. This, in turn, will animate the Find in Page container since we use the same
                // delegate to slide the bar up and down with the keyboard. We don't want to animate the
                // constraints added above, however, so force a layout now to prevent these constraints
                // from being lumped in with the keyboard animation.
                findInPageBar.layoutIfNeeded()
            }

            self.findInPageBar?.becomeFirstResponder()
        } else if let findInPageBar = self.findInPageBar {
            findInPageBar.endEditing(true)
            guard let webView = tabManager.selectedTab?.webView else { return }
            webView.evaluateJavaScript("__firefox__.findDone()", completionHandler: nil)
            findInPageBar.removeFromSuperview()
            self.findInPageBar = nil
            updateViewConstraints()
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        // Make the web view the first responder so that it can show the selection menu.
        return tabManager.selectedTab?.webView?.becomeFirstResponder() ?? false
    }

    func reloadTab() {
        if homePanelController == nil {
            tabManager.selectedTab?.reload()
        }
    }

    func goBack() {
        if tabManager.selectedTab?.canGoBack == true && homePanelController == nil {
            tabManager.selectedTab?.goBack()
        }
    }
    func goForward() {
        if tabManager.selectedTab?.canGoForward == true && homePanelController == nil {
            tabManager.selectedTab?.goForward()
        }
    }

    func findOnPage() {
        if homePanelController == nil {
            tab( (tabManager.selectedTab)!, didSelectFindInPageForSelection: "")
        }
    }

    func selectLocationBar() {
        scrollController.showToolbars(animated: true)
        urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
    }

    func newTab() {
        openBlankNewTab(isPrivate: false)
    }
    func newPrivateTab() {
        openBlankNewTab(isPrivate: true)
    }

    func closeTab() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }
        tabManager.removeTab(currentTab)
    }

    func nextTab() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.index(of: currentTab), index + 1 < tabs.count {
            tabManager.selectTab(tabs[index + 1])
        } else if let firstTab = tabs.first {
            tabManager.selectTab(firstTab)
        }
    }

    func previousTab() {
        guard let currentTab = tabManager.selectedTab else {
            return
        }

        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.index(of: currentTab), index - 1 < tabs.count && index != 0 {
            tabManager.selectTab(tabs[index - 1])
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(BrowserViewController.reloadTab), discoverabilityTitle: Strings.ReloadPageTitle),
            UIKeyCommand(input: "[", modifierFlags: .command, action: #selector(BrowserViewController.goBack), discoverabilityTitle: Strings.BackTitle),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: .command, action: #selector(BrowserViewController.goBack), discoverabilityTitle: Strings.BackTitle),
            UIKeyCommand(input: "]", modifierFlags: .command, action: #selector(BrowserViewController.goForward), discoverabilityTitle: Strings.ForwardTitle),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: .command, action: #selector(BrowserViewController.goForward), discoverabilityTitle: Strings.ForwardTitle),

            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(BrowserViewController.findOnPage), discoverabilityTitle: Strings.FindTitle),
            UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(BrowserViewController.selectLocationBar), discoverabilityTitle: Strings.SelectLocationBarTitle),
            UIKeyCommand(input: "t", modifierFlags: .command, action: #selector(BrowserViewController.newTab), discoverabilityTitle: Strings.NewTabTitle),
            UIKeyCommand(input: "p", modifierFlags: [.command, .shift], action: #selector(BrowserViewController.newPrivateTab), discoverabilityTitle: Strings.NewPrivateTabTitle),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(BrowserViewController.closeTab), discoverabilityTitle: Strings.CloseTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: .control, action: #selector(BrowserViewController.nextTab), discoverabilityTitle: Strings.ShowNextTabTitle),
            UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [.command, .shift], action: #selector(BrowserViewController.nextTab), discoverabilityTitle: Strings.ShowNextTabTitle),
            UIKeyCommand(input: "\t", modifierFlags: [.control, .shift], action: #selector(BrowserViewController.previousTab), discoverabilityTitle: Strings.ShowPreviousTabTitle),
            UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [.command, .shift], action: #selector(BrowserViewController.previousTab), discoverabilityTitle: Strings.ShowPreviousTabTitle),
        ]
    }

    fileprivate func getCurrentAppState() -> AppState {
        return mainStore.updateState(getCurrentUIState())
    }

    fileprivate func getCurrentUIState() -> UIState {
        if let homePanelController = homePanelController {
            return .homePanels(homePanelState: homePanelController.homePanelState)
        }
        guard let tab = tabManager.selectedTab else {
            return .loading
        }
        if tab.url == nil {
            return .emptyTab
        }
        return .tab(tabState: tab.tabState)
    }

    @objc fileprivate func openSettings() {
        assert(Thread.isMainThread, "Opening settings requires being invoked on the main thread")

        let settingsTableViewController = AppSettingsTableViewController()
        settingsTableViewController.profile = profile
        settingsTableViewController.tabManager = tabManager
        settingsTableViewController.settingsDelegate = self

        let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
        controller.popoverDelegate = self
        controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(controller, animated: true, completion: nil)
    }
}

extension BrowserViewController: AppStateDelegate {

    func appDidUpdateState(_ appState: AppState) {
        menuViewController?.appState = appState
        toolbar?.appDidUpdateState(appState)
        urlBar?.appDidUpdateState(appState)
    }
}

extension BrowserViewController: MenuActionDelegate {
    func performMenuAction(_ action: MenuAction, withAppState appState: AppState) {
        if let menuAction = AppMenuAction(rawValue: action.action) {
            switch menuAction {
            case .openNewNormalTab:
                self.openURLInNewTab(nil, isPrivate: false, isPrivileged: true)
                LeanplumIntegration.sharedInstance.track(eventName: .openedNewTab)

            // this is a case that is only available in iOS9
            case .openNewPrivateTab:
                self.openURLInNewTab(nil, isPrivate: true, isPrivileged: true)
            case .findInPage:
                self.updateFindInPageVisibility(visible: true)
            case .toggleBrowsingMode:
                guard let tab = tabManager.selectedTab else { break }
                tab.toggleDesktopSite()
            case .toggleBookmarkStatus:
                switch appState.ui {
                case .tab(let tabState):
                    self.toggleBookmarkForTabState(tabState)
                default: break
                }
            case .showImageMode:
                self.setNoImageMode(false)
            case .hideImageMode:
                self.setNoImageMode(true)
            case .showNightMode:
                NightModeHelper.setNightMode(self.profile.prefs, tabManager: self.tabManager, enabled: false)
            case .hideNightMode:
                NightModeHelper.setNightMode(self.profile.prefs, tabManager: self.tabManager, enabled: true)
            case .openSettings:
                self.openSettings()
            case .openTopSites:
                openHomePanel(.topSites, forAppState: appState)
            case .openBookmarks:
                openHomePanel(.bookmarks, forAppState: appState)
            case .openHistory:
                openHomePanel(.history, forAppState: appState)
            case .openReadingList:
                openHomePanel(.readingList, forAppState: appState)
            case .setHomePage:
                guard let tab = tabManager.selectedTab else { break }
                HomePageHelper(prefs: profile.prefs).setHomePage(toTab: tab, withNavigationController: navigationController)
            case .openHomePage:
                guard let tab = tabManager.selectedTab else { break }
                HomePageHelper(prefs: profile.prefs).openHomePage(inTab: tab, withNavigationController: navigationController)
            case .sharePage:
                guard let url = tabManager.selectedTab?.url else { break }
                let sourceView = self.navigationToolbar.menuButton
                let tab = tabManager.selectedTab
                presentActivityViewController(url as URL, tab: tab, sourceView: sourceView.superview, sourceRect: sourceView.frame, arrowDirection: .up)
            default: break
            }
        }
    }

    fileprivate func openHomePanel(_ panel: HomePanelType, forAppState appState: AppState) {
        switch appState.ui {
        case .tab(_):
            self.openURLInNewTab(panel.localhostURL as URL, isPrivate: appState.ui.isPrivate(), isPrivileged: true)
        case .homePanels(_):
            self.homePanelController?.selectedPanel = panel
        default: break
        }
    }
}

extension BrowserViewController: SettingsDelegate {
    func settingsOpenURLInNewTab(_ url: URL) {
        self.openURLInNewTab(url, isPrivileged: false)
    }
}

extension BrowserViewController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
        self.appDidUpdateState(getCurrentAppState())
        self.dismiss(animated: animated, completion: nil)
    }
}

/**
 * History visit management.
 * TODO: this should be expanded to track various visit types; see Bug 1166084.
 */
extension BrowserViewController {
    func ignoreNavigationInTab(_ tab: Tab, navigation: WKNavigation) {
        self.ignoredNavigation.insert(navigation)
    }

    func recordNavigationInTab(_ tab: Tab, navigation: WKNavigation, visitType: VisitType) {
        self.typedNavigation[navigation] = visitType
    }

    /**
     * Untrack and do the right thing.
     */
    func getVisitTypeForTab(_ tab: Tab, navigation: WKNavigation?) -> VisitType? {
        guard let navigation = navigation else {
            // See https://github.com/WebKit/webkit/blob/master/Source/WebKit2/UIProcess/Cocoa/NavigationState.mm#L390
            return VisitType.link
        }

        if let _ = self.ignoredNavigation.remove(navigation) {
            return nil
        }

        return self.typedNavigation.removeValue(forKey: navigation) ?? VisitType.link
    }
}

extension BrowserViewController: URLBarDelegate {

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        self.webViewContainerToolbar.isHidden = true
        updateFindInPageVisibility(visible: false)

        let tabTrayController = TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)

        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }

        self.navigationController?.pushViewController(tabTrayController, animated: true)
        self.tabTrayController = tabTrayController
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .available:
                    enableReaderMode()
                case .active:
                    disableReaderMode()
                case .unavailable:
                    break
                }
            }
        }
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
               let url = tab.url?.displayURL,
               let result = profile.readingList?.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed."))
                return false
        }

        switch result {
        case .success:
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Added page to Reading List", comment: "Accessibility message e.g. spoken by VoiceOver after the current page gets added to the Reading List using the Reader View button, e.g. by long-pressing it or by its accessibility custom action."))
            // TODO: https://bugzilla.mozilla.org/show_bug.cgi?id=1158503 provide some form of 'this has been added' visual feedback?
        case .failure(let error):
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading List. Maybe it's already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures."))
            log.error("readingList.createRecordWithURL(url: \"\(url.absoluteString)\", ...) failed with error: \(error)")
        }
        return true
    }

    func locationActionsForURLBar(_ urlBar: URLBarView) -> [AccessibleAction] {
        if UIPasteboard.general.string != nil {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func urlBarDisplayTextForURL(_ url: URL?) -> String? {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.currentInitialURL
        if searchURL?.isErrorPageURL ?? true {
            searchURL = url
        }
        return profile.searchEngines.queryForSearchURL(searchURL as URL?) ?? url?.absoluteString
    }

    func urlBarDidLongPressLocation(_ urlBar: URLBarView) {
        let longPressAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for action in locationActionsForURLBar(urlBar) {
            longPressAlertController.addAction(action.alertAction(style: .default))
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: { (alert: UIAlertAction) -> Void in
        })
        longPressAlertController.addAction(cancelAction)

        let setupPopover = { [unowned self] in
            if let popoverPresentationController = longPressAlertController.popoverPresentationController {
                popoverPresentationController.sourceView = urlBar
                popoverPresentationController.sourceRect = urlBar.frame
                popoverPresentationController.permittedArrowDirections = .any
                popoverPresentationController.delegate = self
            }
        }

        setupPopover()

        if longPressAlertController.popoverPresentationController != nil {
            displayedPopoverController = longPressAlertController
            updateDisplayedPopoverProperties = setupPopover
        }

        self.present(longPressAlertController, animated: true, completion: nil)
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        if let selectedTab = tabManager.selectedTab {
            // Only scroll to top if we are not showing the home view controller
            if homePanelController == nil {
                selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
            }
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        searchLoader.query = text

        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController!.searchQuery = text
        }
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.characters.index(of: " ") else {
            submitSearchText(text)
            return
        }

        let possibleKeyword = trimmedText.substring(to: possibleKeywordQuerySeparatorSpace)
        let possibleQuery = trimmedText.substring(from: trimmedText.index(after: possibleKeywordQuerySeparatorSpace))

        profile.bookmarks.getURLForKeywordSearch(possibleKeyword).uponQueue(DispatchQueue.main) { result in
            if var urlString = result.successValue,
                let escapedQuery = possibleQuery.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed),
                let range = urlString.range(of: "%s") {
                urlString.replaceSubrange(range, with: escapedQuery)

                if let url = URL(string: urlString) {
                    self.finishEditingAndSubmit(url, visitType: VisitType.typed)
                    return
                }
            }

            self.submitSearchText(text)
        }
    }

    fileprivate func submitSearchText(_ text: String) {
        let engine = profile.searchEngines.defaultEngine

        if let searchURL = engine.searchURLForQuery(text) {
            // We couldn't find a matching search keyword, so do a search query.
            Telemetry.recordEvent(SearchTelemetry.makeEvent(engine, source: .URLBar))
            finishEditingAndSubmit(searchURL, visitType: VisitType.typed)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            log.error("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
        }
    }

    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView) {
        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
        } else {
            showHomePanelController(inline: false)
        }

        LeanplumIntegration.sharedInstance.track(eventName: .interactWithURLBar)
    }

    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView) {
        hideSearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
    }
}

extension BrowserViewController: TabToolbarDelegate {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showBackForwardList()
    }

    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }

    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {

        guard let tab = tabManager.selectedTab, tab.webView?.url != nil && (tab.getHelper(name: ReaderMode.name()) as? ReaderMode)?.state != .active else {
            return
        }

        let toggleActionTitle: String
        if tab.desktopSite {
            toggleActionTitle = NSLocalizedString("Request Mobile Site", comment: "Action Sheet Button for Requesting the Mobile Site")
        } else {
            toggleActionTitle = NSLocalizedString("Request Desktop Site", comment: "Action Sheet Button for Requesting the Desktop Site")
        }

        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: toggleActionTitle, style: .default, handler: { _ in tab.toggleDesktopSite() }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Label for Cancel button"), style: .cancel, handler: nil))
        controller.popoverPresentationController?.sourceView = toolbar ?? urlBar
        controller.popoverPresentationController?.sourceRect = button.frame
        present(controller, animated: true, completion: nil)
    }

    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showBackForwardList()
    }

    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        // ensure that any keyboards or spinners are dismissed before presenting the menu
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
        // check the trait collection
        // open as modal if portrait\
        let presentationStyle: MenuViewPresentationStyle = (self.traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular) ? .modal : .popover
        let mvc = MenuViewController(withAppState: getCurrentAppState(), presentationStyle: presentationStyle)
        mvc.delegate = self
        mvc.actionDelegate = self
        mvc.menuTransitionDelegate = MenuPresentationAnimator()
        mvc.modalPresentationStyle = presentationStyle == .modal ? .overCurrentContext : .popover

        if let popoverPresentationController = mvc.popoverPresentationController {
            popoverPresentationController.backgroundColor = UIColor.clear
            popoverPresentationController.delegate = self
            popoverPresentationController.sourceView = button
            popoverPresentationController.sourceRect = CGRect(x: button.frame.width/2, y: button.frame.size.height * 0.75, width: 1, height: 1)
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.up
        }

        self.present(mvc, animated: true, completion: nil)
        menuViewController = mvc
    }

    fileprivate func setNoImageMode(_ enabled: Bool) {
        self.profile.prefs.setBool(enabled, forKey: PrefsKeys.KeyNoImageModeStatus)
        for tab in self.tabManager.tabs {
            tab.setNoImageMode(enabled, force: true)
        }
        self.tabManager.selectedTab?.reload()
    }

    func toggleBookmarkForTabState(_ tabState: TabState) {
        if tabState.isBookmarked {
            self.removeBookmark(tabState)
        } else {
            self.addBookmark(tabState)
            LeanplumIntegration.sharedInstance.track(eventName: .savedBookmark)
        }
    }

    func tabToolbarDidPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard let tab = tabManager.selectedTab,
            let _ = tab.url?.displayURL?.absoluteString else {
                log.error("Bookmark error: No tab is selected, or no URL in tab.")
                return
        }

        toggleBookmarkForTabState(tab.tabState)
    }

    func tabToolbarDidLongPressBookmark(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
    }

    func tabToolbarDidPressShare(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        if let tab = tabManager.selectedTab, let url = tab.url?.displayURL {
            let sourceView = self.navigationToolbar.shareButton
            presentActivityViewController(url, tab: tab, sourceView: sourceView.superview, sourceRect: sourceView.frame, arrowDirection: .up)
        }
    }

    func tabToolbarDidPressHomePage(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        HomePageHelper(prefs: profile.prefs).openHomePage(inTab: tab, withNavigationController: navigationController)
    }
    
    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.bvc = self
            backForwardViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
    }
}

extension BrowserViewController: MenuViewControllerDelegate {
    func menuViewControllerDidDismiss(_ menuViewController: MenuViewController) {
        self.menuViewController = nil
        displayedPopoverController = nil
        updateDisplayedPopoverProperties = nil
    }

    func shouldCloseMenu(_ menuViewController: MenuViewController, forRotationToNewSize size: CGSize, forTraitCollection traitCollection: UITraitCollection) -> Bool {
        // if we're presenting in popover but we haven't got a preferred content size yet, don't dismiss, otherwise we might dismiss before we've presented
        if (traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .compact) && menuViewController.preferredContentSize == CGSize.zero {
            return false
        }

        // Dismiss the menu if we are going into the background.
        let state = UIApplication.shared.applicationState
        if state != .active {
            return true
        }

        func orientationForSize(_ size: CGSize) -> UIInterfaceOrientation {
            return size.height < size.width ? .landscapeLeft : .portrait
        }

        let currentOrientation = orientationForSize(self.view.bounds.size)
        let newOrientation = orientationForSize(size)
        let isiPhone = UI_USER_INTERFACE_IDIOM() == .phone

        // we only want to dismiss when rotating on iPhone
        // if we're rotating from landscape to portrait then we are rotating from popover to modal
        return isiPhone && currentOrientation != newOrientation
    }
}

extension BrowserViewController: WindowCloseHelperDelegate {
    func windowCloseHelper(_ helper: WindowCloseHelper, didRequestToCloseTab tab: Tab) {
        tabManager.removeTab(tab)
    }
}

extension BrowserViewController: TabDelegate {

    func tab(_ tab: Tab, didCreateWebView webView: WKWebView) {
        webView.frame = webViewContainer.frame
        // Observers that live as long as the tab. Make sure these are all cleared
        // in willDeleteWebView below!
        webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: KVOLoading, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoBack, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoForward, options: .new, context: nil)
        tab.webView?.addObserver(self, forKeyPath: KVOURL, options: .new, context: nil)

        webView.scrollView.addObserver(self.scrollController, forKeyPath: KVOContentSize, options: .new, context: nil)

        webView.uiDelegate = self

        let readerMode = ReaderMode(tab: tab)
        readerMode.delegate = self
        tab.addHelper(readerMode, name: ReaderMode.name())

        let favicons = FaviconManager(tab: tab, profile: profile)
        tab.addHelper(favicons, name: FaviconManager.name())

        // only add the logins helper if the tab is not a private browsing tab
        if !tab.isPrivate {
            let logins = LoginsHelper(tab: tab, profile: profile)
            tab.addHelper(logins, name: LoginsHelper.name())
        }

        let contextMenuHelper = ContextMenuHelper(tab: tab)
        contextMenuHelper.delegate = self
        tab.addHelper(contextMenuHelper, name: ContextMenuHelper.name())

        let errorHelper = ErrorPageHelper()
        tab.addHelper(errorHelper, name: ErrorPageHelper.name())

        let windowCloseHelper = WindowCloseHelper(tab: tab)
        windowCloseHelper.delegate = self
        tab.addHelper(windowCloseHelper, name: WindowCloseHelper.name())

        let sessionRestoreHelper = SessionRestoreHelper(tab: tab)
        sessionRestoreHelper.delegate = self
        tab.addHelper(sessionRestoreHelper, name: SessionRestoreHelper.name())

        let findInPageHelper = FindInPageHelper(tab: tab)
        findInPageHelper.delegate = self
        tab.addHelper(findInPageHelper, name: FindInPageHelper.name())

        let noImageModeHelper = NoImageModeHelper(tab: tab)
        tab.addHelper(noImageModeHelper, name: NoImageModeHelper.name())
        
        let printHelper = PrintHelper(tab: tab)
        tab.addHelper(printHelper, name: PrintHelper.name())

        let customSearchHelper = CustomSearchHelper(tab: tab)
        tab.addHelper(customSearchHelper, name: CustomSearchHelper.name())

        let openURL = {(url: URL) -> Void in
            self.switchToTabForURLOrOpen(url, isPrivileged: true)
        }

        let nightModeHelper = NightModeHelper(tab: tab)
        tab.addHelper(nightModeHelper, name: NightModeHelper.name())

        let spotlightHelper = SpotlightHelper(tab: tab, openURL: openURL)
        tab.addHelper(spotlightHelper, name: SpotlightHelper.name())

        tab.addHelper(LocalRequestHelper(), name: LocalRequestHelper.name())

        if AppConstants.MOZ_CONTENT_METADATA_PARSING {
            let metadataHelper = MetadataParserHelper(tab: tab, profile: profile)
            tab.addHelper(metadataHelper, name: MetadataParserHelper.name())
        }
    }

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {
        tab.cancelQueuedAlerts()

        webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
        webView.removeObserver(self, forKeyPath: KVOLoading)
        webView.removeObserver(self, forKeyPath: KVOCanGoBack)
        webView.removeObserver(self, forKeyPath: KVOCanGoForward)
        webView.scrollView.removeObserver(self.scrollController, forKeyPath: KVOContentSize)
        webView.removeObserver(self, forKeyPath: KVOURL)

        webView.uiDelegate = nil
        webView.scrollView.delegate = nil
        webView.removeFromSuperview()
    }

    fileprivate func findSnackbar(_ barToFind: SnackBar) -> Int? {
        let bars = snackBars.subviews
        for (index, bar) in bars.enumerated() {
            if bar === barToFind {
                return index
            }
        }
        return nil
    }

    fileprivate func updateSnackBarConstraints() {
        snackBars.snp.remakeConstraints { make in
            make.bottom.equalTo(findInPageContainer.snp.top)

            let bars = self.snackBars.subviews
            if bars.count > 0 {
                let view = bars[bars.count-1]
                make.top.equalTo(view.snp.top)
            } else {
                make.height.equalTo(0)
            }

            if traitCollection.horizontalSizeClass != .regular {
                make.leading.trailing.equalTo(self.footer)
                self.snackBars.layer.borderWidth = 0
            } else {
                make.centerX.equalTo(self.footer)
                make.width.equalTo(SnackBarUX.MaxWidth)
                self.snackBars.layer.borderColor = UIConstants.BorderColor.cgColor
                self.snackBars.layer.borderWidth = 1
            }
        }
    }

    // This removes the bar from its superview and updates constraints appropriately
    fileprivate func finishRemovingBar(_ bar: SnackBar) {
        // If there was a bar above this one, we need to remake its constraints.
        if let index = findSnackbar(bar) {
            // If the bar being removed isn't on the top of the list
            let bars = snackBars.subviews
            if index < bars.count-1 {
                // Move the bar above this one
                let nextbar = bars[index+1] as! SnackBar
                nextbar.snp.makeConstraints { make in
                    // If this wasn't the bottom bar, attach to the bar below it
                    if index > 0 {
                        let bar = bars[index-1] as! SnackBar
                        nextbar.bottom = make.bottom.equalTo(bar.snp.top).constraint
                    } else {
                        // Otherwise, we attach it to the bottom of the snackbars
                        nextbar.bottom = make.bottom.equalTo(self.snackBars.snp.bottom).constraint
                    }
                }
            }
        }

        // Really remove the bar
        bar.removeFromSuperview()
    }

    fileprivate func finishAddingBar(_ bar: SnackBar) {
        snackBars.addSubview(bar)
        bar.snp.makeConstraints { make in
            // If there are already bars showing, add this on top of them
            let bars = self.snackBars.subviews

            // Add the bar on top of the stack
            // We're the new top bar in the stack, so make sure we ignore ourself
            if bars.count > 1 {
                let view = bars[bars.count - 2]
                bar.bottom = make.bottom.equalTo(view.snp.top).offset(0).constraint
            } else {
                bar.bottom = make.bottom.equalTo(self.snackBars.snp.bottom).offset(0).constraint
            }
            make.leading.trailing.equalTo(self.snackBars)
        }
    }

    func showBar(_ bar: SnackBar, animated: Bool) {
        finishAddingBar(bar)
        updateSnackBarConstraints()

        bar.hide()
        view.layoutIfNeeded()
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: { () -> Void in
            bar.show()
            self.view.layoutIfNeeded()
        })
    }

    func removeBar(_ bar: SnackBar, animated: Bool) {
        if let _ = findSnackbar(bar) {
            UIView.animate(withDuration: animated ? 0.25 : 0, animations: { () -> Void in
                bar.hide()
                self.view.layoutIfNeeded()
            }, completion: { success in
                // Really remove the bar
                self.finishRemovingBar(bar)
                self.updateSnackBarConstraints()
            }) 
        }
    }

    func removeAllBars() {
        let bars = snackBars.subviews
        for bar in bars {
            if let bar = bar as? SnackBar {
                bar.removeFromSuperview()
            }
        }
        self.updateSnackBarConstraints()
    }

    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar) {
        showBar(bar, animated: true)
    }

    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar) {
        removeBar(bar, animated: true)
    }

    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String) {
        updateFindInPageVisibility(visible: true)
        findInPageBar?.text = selection
    }
}

extension BrowserViewController: HomePanelViewControllerDelegate {
    func homePanelViewController(_ homePanelViewController: HomePanelViewController, didSelectURL url: URL, visitType: VisitType) {
        finishEditingAndSubmit(url, visitType: visitType)
    }

    func homePanelViewController(_ homePanelViewController: HomePanelViewController, didSelectPanel panel: Int) {
        if let url = tabManager.selectedTab?.url, url.isAboutHomeURL {
            tabManager.selectedTab?.webView?.evaluateJavaScript("history.replaceState({}, '', '#panel=\(panel)')", completionHandler: nil)
        }
    }

    func homePanelViewControllerDidRequestToCreateAccount(_ homePanelViewController: HomePanelViewController) {
        let fxaOptions = FxALaunchParams(view: "signup", email: nil, access_code: nil)
        presentSignInViewController(fxaOptions) // TODO UX Right now the flow for sign in and create account is the same
    }

    func homePanelViewControllerDidRequestToSignIn(_ homePanelViewController: HomePanelViewController) {
        let fxaOptions = FxALaunchParams(view: "signin", email: nil, access_code: nil)
        presentSignInViewController(fxaOptions) // TODO UX Right now the flow for sign in and create account is the same
    }
    
    func homePanelViewControllerDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        self.tabManager.addTab(URLRequest(url: url), afterTab: self.tabManager.selectedTab, isPrivate: isPrivate)
    }
}

extension BrowserViewController: SearchViewControllerDelegate {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL) {
        finishEditingAndSubmit(url, visitType: VisitType.typed)
    }

    func presentSearchSettingsController() {
        let settingsNavigationController = SearchSettingsTableViewController()
        settingsNavigationController.model = self.profile.searchEngines
        settingsNavigationController.profile = self.profile

        let navController = UINavigationController(rootViewController: settingsNavigationController)

        self.present(navController, animated: true, completion: nil)
    }
}

extension BrowserViewController: TabManagerDelegate {

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        if let wv = previous?.webView {
            removeOpenInView()
            wv.endEditing(true)
            wv.accessibilityLabel = nil
            wv.accessibilityElementsHidden = true
            wv.accessibilityIdentifier = nil
            wv.removeFromSuperview()
        }

        if let tab = selected, let webView = tab.webView {
            updateURLBarDisplayURL(tab)
            if tab.isPrivate {
                readerModeCache = MemoryReaderModeCache.sharedInstance
                applyTheme(Theme.PrivateMode)
            } else {
                readerModeCache = DiskReaderModeCache.sharedInstance
                applyTheme(Theme.NormalMode)
            }
            if let privateModeButton = topTabsViewController?.privateModeButton, previous != nil && previous?.isPrivate != tab.isPrivate {
                privateModeButton.setSelected(tab.isPrivate, animated: true)
            }
            ReaderModeHandlers.readerModeCache = readerModeCache

            scrollController.tab = selected
            webViewContainer.addSubview(webView)
            webView.snp.makeConstraints { make in
                make.top.equalTo(webViewContainerToolbar.snp.bottom)
                make.left.right.bottom.equalTo(self.webViewContainer)
            }
            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.accessibilityIdentifier = "contentView"
            webView.accessibilityElementsHidden = false

            if let url = webView.url {
                let absoluteString = url.absoluteString
                // Don't bother fetching bookmark state for about/sessionrestore and about/home.
                if url.isAboutURL {
                    // Indeed, because we don't show the toolbar at all, don't even blank the star.
                } else {
                    profile.bookmarks.modelFactory >>== { [weak tab] in
                        $0.isBookmarked(absoluteString)
                            .uponQueue(DispatchQueue.main) {
                            guard let isBookmarked = $0.successValue else {
                                log.error("Error getting bookmark status: \($0.failureValue).")
                                return
                            }

                            tab?.isBookmarked = isBookmarked
                        }
                    }
                }
            } else {
                // The web view can go gray if it was zombified due to memory pressure.
                // When this happens, the URL is nil, so try restoring the page upon selection.
                tab.reload()
            }
        }

        if let selected = selected, let previous = previous, selected.isPrivate != previous.isPrivate {
            updateTabCountUsingTabManager(tabManager)
        }

        removeAllBars()
        if let bars = selected?.bars {
            for bar in bars {
                showBar(bar, animated: true)
            }
        }

        updateFindInPageVisibility(visible: false)

        navigationToolbar.updateReloadStatus(selected?.loading ?? false)
        navigationToolbar.updateBackStatus(selected?.canGoBack ?? false)
        navigationToolbar.updateForwardStatus(selected?.canGoForward ?? false)
        self.urlBar.updateProgressBar(Float(selected?.estimatedProgress ?? 0))

        if let readerMode = selected?.getHelper(name: ReaderMode.name()) as? ReaderMode {
            urlBar.updateReaderModeState(readerMode.state)
            if readerMode.state == .active {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }
        } else {
            urlBar.updateReaderModeState(ReaderModeState.unavailable)
        }

        updateInContentHomePanel(selected?.url as URL?)
    }

    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab) {
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab) {
        // If we are restoring tabs then we update the count once at the end
        if !tabManager.isRestoring {
            updateTabCountUsingTabManager(tabManager)
        }
        tab.tabDelegate = self
        tab.appStateDelegate = self
    }

    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab) {
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        updateTabCountUsingTabManager(tabManager)
        // tabDelegate is a weak ref (and the tab's webView may not be destroyed yet)
        // so we don't expcitly unset it.

        if let url = tab.url, !url.isAboutURL && !tab.isPrivate {
            profile.recentlyClosedTabs.addTab(url as URL, title: tab.title, faviconURL: tab.displayFavicon?.url)
        }
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func show(buttonToast: ButtonToast, afterWaiting delay: Double = 0, duration: Double = SimpleToastUX.ToastDismissAfter) {
        // If BVC isnt visible hold on to this toast until viewDidAppear
        if self.view.window == nil {
            self.pendingToast = buttonToast
            return
        }

        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds) + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.view.addSubview(buttonToast)
            buttonToast.snp.makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.bottom.equalTo(self.webViewContainer)
            }
            buttonToast.showToast()
        }
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        guard let toast = toast, !tabTrayController.privateMode else {
            return
        }
        show(buttonToast: toast, afterWaiting: ButtonToastUX.ToastDelay)
    }

    fileprivate func updateTabCountUsingTabManager(_ tabManager: TabManager, animated: Bool = true) {
        if let selectedTab = tabManager.selectedTab {
            let count = selectedTab.isPrivate ? tabManager.privateTabs.count : tabManager.normalTabs.count
            urlBar.updateTabCount(max(count, 1), animated: animated)
            topTabsViewController?.updateTabCount(max(count, 1), animated: animated)
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if tabManager.selectedTab?.webView !== webView {
            return
        }

        updateFindInPageVisibility(visible: false)

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.url {
            if !url.isReaderModeURL {
                urlBar.updateReaderModeState(ReaderModeState.unavailable)
                hideReaderModeBar(animated: false)
            }

            // remove the open in overlay view if it is present
            removeOpenInView()
        }
    }

    // Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
    // it could just be a visit to a regular page on maps.apple.com.
    fileprivate func isAppleMapsURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "maps.apple.com" && url.query != nil {
                return true
            }
        }
        return false
    }

    // Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
    // used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
    // them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
    // leave a 'Back to Safari' button in the status bar, which we do not want.
    fileprivate func isStoreURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "itunes.apple.com" {
                return true
            }
        }
        return false
    }

    // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
    // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
    // method.

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }

        if url.scheme == "about" {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }

        if !navigationAction.isAllowed && navigationAction.navigationType != .backForward {
            print("\(navigationAction.isAllowed) \(navigationAction.navigationType == .backForward) \(navigationAction.request.url)")
            log.warning("Denying unprivileged request: \(navigationAction.request)")
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }

        // First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
        // gives us the exact same behaviour as Safari.

        if url.scheme == "tel" || url.scheme == "facetime" || url.scheme == "facetime-audio" {
            if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false), let phoneNumber = components.path, !phoneNumber.isEmpty {
                let formatter = PhoneNumberFormatter()
                let formattedPhoneNumber = formatter.formatPhoneNumber(phoneNumber)
                let alert = UIAlertController(title: formattedPhoneNumber, message: nil, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Label for Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Call", comment:"Alert Call Button"), style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
                    UIApplication.shared.openURL(url)
                }))
                present(alert, animated: true, completion: nil)

                LeanplumIntegration.sharedInstance.track(eventName: .openedTelephoneLink)
            }
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }

        // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
        // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
        // iOS will always say yes. TODO Is this the same as isWhitelisted?

        if isAppleMapsURL(url) || isStoreURL(url) {
            UIApplication.shared.openURL(url)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }

        // Handles custom mailto URL schemes.
        if url.scheme == "mailto" {
            if let mailToMetadata = url.mailToMetadata(), let mailScheme = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption), mailScheme != "mailto" {
                self.mailtoLinkHandler.launchMailClientForScheme(mailScheme, metadata: mailToMetadata, defaultMailtoURL: url)
            } else {
                UIApplication.shared.openURL(url)
            }

            LeanplumIntegration.sharedInstance.track(eventName: .openedMailtoLink)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }

        // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
        // always allow this. Additionally, data URIs are also handled just like normal web pages.

        if url.scheme == "http" || url.scheme == "https" || url.scheme == "data" {
            if navigationAction.navigationType == .linkActivated {
                resetSpoofedUserAgentIfRequired(webView, newURL: url)
            } else if navigationAction.navigationType == .backForward {
                restoreSpoofedUserAgentIfRequired(webView, newRequest: navigationAction.request)
            }
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }

        // Default to calling openURL(). What this does depends on the iOS version. On iOS 8, it will just work without
        // prompting. On iOS9, depending on the scheme, iOS will prompt: "Firefox" wants to open "Twitter". It will ask
        // every time. There is no way around this prompt. (TODO Confirm this is true by adding them to the Info.plist)

        let openedURL = UIApplication.shared.openURL(url)
        if !openedURL {
            let alert = UIAlertController(title: Strings.UnableToOpenURLErrorTitle, message: Strings.UnableToOpenURLError, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: UIConstants.OKString, style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        decisionHandler(WKNavigationActionPolicy.cancel)
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // If this is a certificate challenge, see if the certificate has previously been
        // accepted by the user.
        let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust,
           let cert = SecTrustGetCertificateAtIndex(trust, 0), profile.certStore.containsCertificate(cert, forOrigin: origin) {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: trust))
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
              let tab = tabManager[webView] else {
            completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
            return
        }

        // If this is a request to our local web server, use our private credentials.
        if challenge.protectionSpace.host == "localhost" && challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
            completionHandler(.useCredential, WebServer.sharedInstance.credentials)
            return
        }

        // The challenge may come from a background tab, so ensure it's the one visible.
        tabManager.selectTab(tab)

        let loginsHelper = tab.getHelper(name: LoginsHelper.name()) as? LoginsHelper
        Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper).uponQueue(DispatchQueue.main) { res in
            if let credentials = res.successValue {
                completionHandler(.useCredential, credentials.credentials)
            } else {
                completionHandler(URLSession.AuthChallengeDisposition.rejectProtectionSpace, nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let tab = tabManager[webView] else { return }

        tab.url = webView.url
        self.scrollController.resetZoomState()

        if tabManager.selectedTab === tab {
            updateUIForReaderHomeStateForTab(tab)
            appDidUpdateState(getCurrentAppState())
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let tab: Tab! = tabManager[webView]
        tabManager.expireSnackbars()

        if let url = webView.url, !url.isErrorPageURL && !url.isAboutHomeURL {
            tab.lastExecutedTime = Date.now()

            if navigation == nil {
                log.warning("Implicitly unwrapped optional navigation was nil.")
            }

            postLocationChangeNotificationForTab(tab, navigation: navigation)

            // Fire the readability check. This is here and not in the pageShow event handler in ReaderMode.js anymore
            // because that event wil not always fire due to unreliable page caching. This will either let us know that
            // the currently loaded page can be turned into reading mode or if the page already is in reading mode. We
            // ignore the result because we are being called back asynchronous when the readermode status changes.
            webView.evaluateJavaScript("\(ReaderModeNamespace).checkReadability()", completionHandler: nil)
        }

        if tab === tabManager.selectedTab {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            // must be followed by LayoutChanged, as ScreenChanged will make VoiceOver
            // cursor land on the correct initial element, but if not followed by LayoutChanged,
            // VoiceOver will sometimes be stuck on the element, not allowing user to move
            // forward/backward. Strange, but LayoutChanged fixes that.
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        } else {
            // To Screenshot a tab that is hidden we must add the webView,
            // then wait enough time for the webview to render.
            if let webView =  tab.webView {
                view.insertSubview(webView, at: 0)
                let time = DispatchTime.now() + Double(Int64(500 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time) {
                    self.screenshotHelper.takeScreenshot(tab)
                    if webView.superview == self.view {
                        webView.removeFromSuperview()
                    }
                }
            }
        }

        // Remember whether or not a desktop site was requested
        tab.desktopSite = webView.customUserAgent?.isEmpty == false
    }

    fileprivate func addViewForOpenInHelper(_ openInHelper: OpenInHelper) {
        guard let view = openInHelper.openInView else { return }
        webViewContainerToolbar.addSubview(view)
        webViewContainerToolbar.snp.updateConstraints { make in
            make.height.equalTo(OpenInViewUX.ViewHeight)
        }
        view.snp.makeConstraints { make in
            make.edges.equalTo(webViewContainerToolbar)
        }

        self.openInHelper = openInHelper
    }

    fileprivate func removeOpenInView() {
        guard let _ = self.openInHelper else { return }
        webViewContainerToolbar.subviews.forEach { $0.removeFromSuperview() }

        webViewContainerToolbar.snp.updateConstraints { make in
            make.height.equalTo(0)
        }

        self.openInHelper = nil
    }

    fileprivate func postLocationChangeNotificationForTab(_ tab: Tab, navigation: WKNavigation?) {
        let notificationCenter = NotificationCenter.default
        var info = [AnyHashable: Any]()
        info["url"] = tab.url?.displayURL
        info["title"] = tab.title
        if let visitType = self.getVisitTypeForTab(tab, navigation: navigation)?.rawValue {
            info["visitType"] = visitType
        }
        info["isPrivate"] = tab.isPrivate
        notificationCenter.post(name: NotificationOnLocationChange, object: self, userInfo: info)
    }
}

/// List of schemes that are allowed to open a popup window
private let SchemesAllowedToOpenPopups = ["http", "https", "javascript", "data"]

extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }

        if !navigationAction.isAllowed {
            log.warning("Denying unprivileged request: \(navigationAction.request)")
            return nil
        }

        if let currentTab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(currentTab)
        }

        // If the page uses window.open() or target="_blank", open the page in a new tab.
        let newTab = tabManager.addTab(navigationAction.request, configuration: configuration, afterTab: parentTab, isPrivate: parentTab.isPrivate)
        tabManager.selectTab(newTab)

        // If the page we just opened has a bad scheme, we return nil here so that JavaScript does not
        // get a reference to it which it can return from window.open() - this will end up as a
        // CFErrorHTTPBadURL being presented.
        guard let scheme = (navigationAction.request as NSURLRequest).url?.scheme?.lowercased(), SchemesAllowedToOpenPopups.contains(scheme) else {
            return nil
        }

        return newTab.webView
    }

    fileprivate func canDisplayJSAlertForWebView(_ webView: WKWebView) -> Bool {
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return ((tabManager.selectedTab == nil ? false : tabManager.selectedTab!.webView == webView)) && (self.presentedViewController == nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let messageAlert = MessageAlert(message: message, frame: frame, completionHandler: completionHandler)
        if canDisplayJSAlertForWebView(webView) {
            present(messageAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(messageAlert)
        } else {
            // This should never happen since an alert needs to come from a web view but just in case call the handler
            // since not calling it will result in a runtime exception.
            completionHandler()
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let confirmAlert = ConfirmPanelAlert(message: message, frame: frame, completionHandler: completionHandler)
        if canDisplayJSAlertForWebView(webView) {
            present(confirmAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(confirmAlert)
        } else {
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let textInputAlert = TextInputAlert(message: prompt, frame: frame, completionHandler: completionHandler, defaultText: defaultText)
        if canDisplayJSAlertForWebView(webView) {
            present(textInputAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(textInputAlert)
        } else {
            completionHandler(nil)
        }
    }

    /// Invoked when an error occurs while starting to load data for the main frame.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        let error = error as NSError
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        if checkIfWebContentProcessHasCrashed(webView, error: error as NSError) {
            return
        }

        if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
            if let tab = tabManager[webView], tab === tabManager.selectedTab {
                urlBar.currentURL = tab.url?.displayURL
            }
            return
        }

        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            ErrorPageHelper().showPage(error, forUrl: url, inWebView: webView)

            // If the local web server isn't working for some reason (Firefox cellular data is
            // disabled in settings, for example), we'll fail to load the session restore URL.
            // We rely on loading that page to get the restore callback to reset the restoring
            // flag, so if we fail to load that page, reset it here.
            if url.aboutComponent == "sessionrestore" {
                tabManager.tabs.filter { $0.webView == webView }.first?.restoring = false
            }
        }
    }

    fileprivate func checkIfWebContentProcessHasCrashed(_ webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKError.webContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            log.debug("WebContent process has crashed. Trying to reloadFromOrigin to restart it.")
            webView.reloadFromOrigin()
            return true
        }

        return false
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let helperForURL = OpenIn.helperForResponse(navigationResponse.response)
        if navigationResponse.canShowMIMEType {
            if let openInHelper = helperForURL {
                addViewForOpenInHelper(openInHelper)
            }
            decisionHandler(WKNavigationResponsePolicy.allow)
            return
        }

        guard var openInHelper = helperForURL else {
            let error = NSError(domain: ErrorPageHelper.MozDomain, code: Int(ErrorPageHelper.MozErrorDownloadsNotEnabled), userInfo: [NSLocalizedDescriptionKey: Strings.UnableToDownloadError])
            ErrorPageHelper().showPage(error, forUrl: navigationResponse.response.url!, inWebView: webView)
            return decisionHandler(WKNavigationResponsePolicy.allow)
        }
        
        if openInHelper.openInView == nil {
            openInHelper.openInView = navigationToolbar.shareButton
        }

        openInHelper.open()
        decisionHandler(WKNavigationResponsePolicy.cancel)
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let tab = tabManager[webView] {
            self.tabManager.removeTab(tab)
        }
    }
}

extension BrowserViewController: ReaderModeDelegate {
    func readerMode(_ readerMode: ReaderMode, didChangeReaderModeState state: ReaderModeState, forTab tab: Tab) {
        // If this reader mode availability state change is for the tab that we currently show, then update
        // the button. Otherwise do nothing and the button will be updated when the tab is made active.
        if tabManager.selectedTab === tab {
            urlBar.updateReaderModeState(state)
        }
    }

    func readerMode(_ readerMode: ReaderMode, didDisplayReaderizedContentForTab tab: Tab) {
        self.showReaderModeBar(animated: true)
        tab.showContent(true)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension BrowserViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        displayedPopoverController = nil
        updateDisplayedPopoverProperties = nil
    }
}

extension BrowserViewController: UIAdaptivePresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

// MARK: - ReaderModeStyleViewControllerDelegate

extension BrowserViewController: ReaderModeStyleViewControllerDelegate {
    func readerModeStyleViewController(_ readerModeStyleViewController: ReaderModeStyleViewController, didConfigureStyle style: ReaderModeStyle) {
        // Persist the new style to the profile
        let encodedStyle: [String:Any] = style.encode()
        profile.prefs.setObject(encodedStyle, forKey: ReaderModeProfileKeyStyle)
        // Change the reader mode style on all tabs that have reader mode active
        for tabIndex in 0..<tabManager.count {
            if let tab = tabManager[tabIndex] {
                if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                    if readerMode.state == ReaderModeState.active {
                        readerMode.style = style
                    }
                }
            }
        }
    }
}

extension BrowserViewController {
    func updateReaderModeBar() {
        if let readerModeBar = readerModeBar {
            if let tab = self.tabManager.selectedTab, tab.isPrivate {
                readerModeBar.applyTheme(Theme.PrivateMode)
            } else {
                readerModeBar.applyTheme(Theme.NormalMode)
            }
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, let record = successValue {
                    readerModeBar.unread = record.unread
                    readerModeBar.added = true
                } else {
                    readerModeBar.unread = true
                    readerModeBar.added = false
                }
            } else {
                readerModeBar.unread = true
                readerModeBar.added = false
            }
        }
    }

    func showReaderModeBar(animated: Bool) {
        if self.readerModeBar == nil {
            let readerModeBar = ReaderModeBarView(frame: CGRect.zero)
            readerModeBar.delegate = self
            view.insertSubview(readerModeBar, belowSubview: header)
            self.readerModeBar = readerModeBar
        }

        updateReaderModeBar()

        self.updateViewConstraints()
    }

    func hideReaderModeBar(animated: Bool) {
        if let readerModeBar = self.readerModeBar {
            readerModeBar.removeFromSuperview()
            self.readerModeBar = nil
            self.updateViewConstraints()
        }
    }

    /// There are two ways we can enable reader mode. In the simplest case we open a URL to our internal reader mode
    /// and be done with it. In the more complicated case, reader mode was already open for this page and we simply
    /// navigated away from it. So we look to the left and right in the BackForwardList to see if a readerized version
    /// of the current page is there. And if so, we go there.

    func enableReaderMode() {
        guard let tab = tabManager.selectedTab, let webView = tab.webView else { return }

        let backList = webView.backForwardList.backList
        let forwardList = webView.backForwardList.forwardList

        guard let currentURL = webView.backForwardList.currentItem?.url, let readerModeURL = currentURL.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) else { return }

        if backList.count > 1 && backList.last?.url == readerModeURL {
            webView.go(to: backList.last!)
        } else if forwardList.count > 0 && forwardList.first?.url == readerModeURL {
            webView.go(to: forwardList.first!)
        } else {
            // Store the readability result in the cache and load it. This will later move to the ReadabilityHelper.
            webView.evaluateJavaScript("\(ReaderModeNamespace).readerize()", completionHandler: { (object, error) -> Void in
                if let readabilityResult = ReadabilityResult(object: object as AnyObject?) {
                    do {
                        try self.readerModeCache.put(currentURL, readabilityResult)
                    } catch _ {
                    }
                    if let nav = webView.load(PrivilegedRequest(url: readerModeURL) as URLRequest) {
                        self.ignoreNavigationInTab(tab, navigation: nav)
                    }
                }
            })
        }
    }

    /// Disabling reader mode can mean two things. In the simplest case we were opened from the reading list, which
    /// means that there is nothing in the BackForwardList except the internal url for the reader mode page. In that
    /// case we simply open a new page with the original url. In the more complicated page, the non-readerized version
    /// of the page is either to the left or right in the BackForwardList. If that is the case, we navigate there.

    func disableReaderMode() {
        if let tab = tabManager.selectedTab,
            let webView = tab.webView {
            let backList = webView.backForwardList.backList
            let forwardList = webView.backForwardList.forwardList

            if let currentURL = webView.backForwardList.currentItem?.url {
                if let originalURL = currentURL.decodeReaderModeURL {
                    if backList.count > 1 && backList.last?.url == originalURL {
                        webView.go(to: backList.last!)
                    } else if forwardList.count > 0 && forwardList.first?.url == originalURL {
                        webView.go(to: forwardList.first!)
                    } else {
                        if let nav = webView.load(URLRequest(url: originalURL)) {
                            self.ignoreNavigationInTab(tab, navigation: nav)
                        }
                    }
                }
            }
        }
    }

    func SELDynamicFontChanged(_ notification: Notification) {
        guard notification.name == NotificationDynamicFontChanged else { return }

        var readerModeStyle = DefaultReaderModeStyle
        if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
            if let style = ReaderModeStyle(dict: dict as [String : AnyObject]) {
                readerModeStyle = style
            }
        }
        readerModeStyle.fontSize = ReaderModeFontSize.defaultSize
        self.readerModeStyleViewController(ReaderModeStyleViewController(), didConfigureStyle: readerModeStyle)
    }
}

extension BrowserViewController: ReaderModeBarViewDelegate {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType) {
        switch buttonType {
        case .settings:
            if let readerMode = tabManager.selectedTab?.getHelper(name: "ReaderMode") as? ReaderMode, readerMode.state == ReaderModeState.active {
                var readerModeStyle = DefaultReaderModeStyle
                if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                    if let style = ReaderModeStyle(dict: dict as [String : AnyObject]) {
                        readerModeStyle = style
                    }
                }

                let readerModeStyleViewController = ReaderModeStyleViewController()
                readerModeStyleViewController.delegate = self
                readerModeStyleViewController.readerModeStyle = readerModeStyle
                readerModeStyleViewController.modalPresentationStyle = UIModalPresentationStyle.popover

                let setupPopover = { [unowned self] in
                    if let popoverPresentationController = readerModeStyleViewController.popoverPresentationController {
                        popoverPresentationController.backgroundColor = UIColor.white
                        popoverPresentationController.delegate = self
                        popoverPresentationController.sourceView = readerModeBar
                        popoverPresentationController.sourceRect = CGRect(x: readerModeBar.frame.width/2, y: UIConstants.ToolbarHeight, width: 1, height: 1)
                        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.up
                    }
                }

                setupPopover()

                if readerModeStyleViewController.popoverPresentationController != nil {
                    displayedPopoverController = readerModeStyleViewController
                    updateDisplayedPopoverProperties = setupPopover
                }

                self.present(readerModeStyleViewController, animated: true, completion: nil)
            }

        case .markAsRead:
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, let record = successValue {
                    profile.readingList?.updateRecord(record, unread: false) // TODO Check result, can this fail?
                    readerModeBar.unread = false
                }
            }

        case .markAsUnread:
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let result = profile.readingList?.getRecordWithURL(url) {
                if let successValue = result.successValue, let record = successValue {
                    profile.readingList?.updateRecord(record, unread: true) // TODO Check result, can this fail?
                    readerModeBar.unread = true
                }
            }

        case .addToReadingList:
            if let tab = tabManager.selectedTab,
               let rawURL = tab.url, rawURL.isReaderModeURL,
               let url = rawURL.decodeReaderModeURL {
                    profile.readingList?.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name) // TODO Check result, can this fail?
                    readerModeBar.added = true
                    readerModeBar.unread = true
            }

        case .removeFromReadingList:
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString,
               let result = profile.readingList?.getRecordWithURL(url),
               let successValue = result.successValue,
               let record = successValue {
                    profile.readingList?.deleteRecord(record) // TODO Check result, can this fail?
                    readerModeBar.added = false
                    readerModeBar.unread = false
            }
        }
    }
}

extension BrowserViewController: IntroViewControllerDelegate {
    @discardableResult func presentIntroViewController(_ force: Bool = false) -> Bool {
        if force || profile.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            // On iPad we present it modally in a controller
            if UIDevice.current.userInterfaceIdiom == .pad {
                introViewController.preferredContentSize = CGSize(width: IntroViewControllerUX.Width, height: IntroViewControllerUX.Height)
                introViewController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            }
            present(introViewController, animated: true) {
                self.profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
                // On first run (and forced) open up the homepage in the background.
                let state = self.getCurrentAppState()
                if let homePageURL = HomePageAccessors.getHomePage(state), let tab = self.tabManager.selectedTab, DeviceInfo.hasConnectivity() {
                    tab.loadRequest(URLRequest(url: homePageURL))
                }
            }

            return true
        }

        return false
    }

    func introViewControllerDidFinish(_ introViewController: IntroViewController) {
        introViewController.dismiss(animated: true) { finished in
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                let _ = self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    func presentSignInViewController(_ fxaOptions: FxALaunchParams) {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let vcToPresent: UIViewController
        if profile.hasAccount() {
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = profile
            settingsTableViewController.tabManager = tabManager
            vcToPresent = settingsTableViewController
        } else {
            let signInVC = FxAContentViewController()
            signInVC.delegate = self
            signInVC.url = profile.accountConfiguration.signInURL
            signInVC.fxaOptions = fxaOptions
            signInVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(BrowserViewController.dismissSignInViewController))
            vcToPresent = signInVC
        }

        let settingsNavigationController = SettingsNavigationController(rootViewController: vcToPresent)
		settingsNavigationController.modalPresentationStyle = .formSheet
        self.present(settingsNavigationController, animated: true, completion: nil)
    }

    func dismissSignInViewController() {
        self.dismiss(animated: true, completion: nil)
    }

    func introViewControllerDidRequestToLogin(_ introViewController: IntroViewController) {
        introViewController.dismiss(animated: true, completion: { () -> Void in
            let fxaOptions = FxALaunchParams(view: "signup", email: nil, access_code: nil)
            self.presentSignInViewController(fxaOptions)
        })
    }
}

extension BrowserViewController: FxAContentViewControllerDelegate {
    func contentViewControllerDidSignIn(_ viewController: FxAContentViewController, data: JSON) {
        if data["keyFetchToken"].string == nil || data["unwrapBKey"].string == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            log.debug("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let account = FirefoxAccount.from(profile.accountConfiguration, andJSON: data)!
        profile.setAccount(account)
        if let account = self.profile.getAccount() {
            account.advance()
        }

        // Dismiss the FxA content view if the account is verified.
        if let verified = data["verified"].bool, verified {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func contentViewControllerDidCancel(_ viewController: FxAContentViewController) {
        log.info("Did cancel out of FxA signin")
        self.dismiss(animated: true, completion: nil)
    }
}

extension BrowserViewController: ContextMenuHelperDelegate {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer) {
        // locationInView can return (0, 0) when the long press is triggered in an invalid page
        // state (e.g., long pressing a link before the document changes, then releasing after a
        // different page loads).
        let touchPoint = gestureRecognizer.location(in: view)
        guard touchPoint != CGPoint.zero else { return }

        let touchSize = CGSize(width: 0, height: 16)

        let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        var dialogTitle: String?

        if let url = elements.link, let currentTab = tabManager.selectedTab {
            dialogTitle = url.absoluteString
            let isPrivate = currentTab.isPrivate

            let addTab = { (rURL: URL, isPrivate: Bool) in
                self.scrollController.showToolbars(animated: !self.scrollController.toolbarsShowing, completion: { _ in
                    let tab = self.tabManager.addTab(URLRequest(url: rURL as URL), afterTab: currentTab, isPrivate: isPrivate)
                    guard self.topTabsViewController == nil else {
                        return
                    }
                    // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
                    let toast = ButtonToast(labelText: Strings.ContextMenuButtonToastNewTabOpenedLabelText, buttonText: Strings.ContextMenuButtonToastNewTabOpenedButtonText, completion: { buttonPressed in
                        if buttonPressed {
                            self.tabManager.selectTab(tab)
                        }
                    })
                    self.show(buttonToast: toast)
                })
            }

            if !isPrivate {
                let newTabTitle = NSLocalizedString("Open in New Tab", comment: "Context menu item for opening a link in a new tab")
                let openNewTabAction =  UIAlertAction(title: newTabTitle, style: UIAlertActionStyle.default) { (action: UIAlertAction) in
                    addTab(url, false)
                }
                actionSheetController.addAction(openNewTabAction)
            }

            let openNewPrivateTabTitle = NSLocalizedString("Open in New Private Tab", tableName: "PrivateBrowsing", comment: "Context menu option for opening a link in a new private tab")
            let openNewPrivateTabAction =  UIAlertAction(title: openNewPrivateTabTitle, style: UIAlertActionStyle.default) { (action: UIAlertAction) in
                addTab(url, true)
            }
            actionSheetController.addAction(openNewPrivateTabAction)

            let copyTitle = NSLocalizedString("Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
            let copyAction = UIAlertAction(title: copyTitle, style: UIAlertActionStyle.default) { (action: UIAlertAction) -> Void in
                let pasteBoard = UIPasteboard.general
                pasteBoard.url = url as URL
            }
            actionSheetController.addAction(copyAction)

            let shareTitle = NSLocalizedString("Share Link", comment: "Context menu item for sharing a link URL")
            let shareAction = UIAlertAction(title: shareTitle, style: UIAlertActionStyle.default) { _ in
                self.presentActivityViewController(url as URL, sourceView: self.view, sourceRect: CGRect(origin: touchPoint, size: touchSize), arrowDirection: .any)
            }
            actionSheetController.addAction(shareAction)
        }

        if let url = elements.image {
            if dialogTitle == nil {
                dialogTitle = url.absoluteString
            }

            let photoAuthorizeStatus = PHPhotoLibrary.authorizationStatus()
            let saveImageTitle = NSLocalizedString("Save Image", comment: "Context menu item for saving an image")
            let saveImageAction = UIAlertAction(title: saveImageTitle, style: UIAlertActionStyle.default) { (action: UIAlertAction) -> Void in
                if photoAuthorizeStatus == PHAuthorizationStatus.authorized || photoAuthorizeStatus == PHAuthorizationStatus.notDetermined {
                    self.getImage(url as URL) { UIImageWriteToSavedPhotosAlbum($0, nil, nil, nil) }
                } else {
                    let accessDenied = UIAlertController(title: NSLocalizedString("Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7"), message: NSLocalizedString("This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7"), preferredStyle: UIAlertControllerStyle.alert)
                    let dismissAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.default, handler: nil)
                    accessDenied.addAction(dismissAction)
                    let settingsAction = UIAlertAction(title: NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7"), style: UIAlertActionStyle.default ) { (action: UIAlertAction!) -> Void in
                        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    }
                    accessDenied.addAction(settingsAction)
                    self.present(accessDenied, animated: true, completion: nil)
                    LeanplumIntegration.sharedInstance.track(eventName: .downloadedImage)
                }
            }
            actionSheetController.addAction(saveImageAction)

            let copyImageTitle = NSLocalizedString("Copy Image", comment: "Context menu item for copying an image to the clipboard")
            let copyAction = UIAlertAction(title: copyImageTitle, style: UIAlertActionStyle.default) { (action: UIAlertAction) -> Void in
                // put the actual image on the clipboard
                // do this asynchronously just in case we're in a low bandwidth situation
                let pasteboard = UIPasteboard.general
                pasteboard.url = url as URL
                let changeCount = pasteboard.changeCount
                let application = UIApplication.shared
                var taskId: UIBackgroundTaskIdentifier = 0
                taskId = application.beginBackgroundTask (expirationHandler: { _ in
                    application.endBackgroundTask(taskId)
                })

                Alamofire.request(url)
                    .validate(statusCode: 200..<300)
                    .response { response in
                        // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                        // fetching the image; otherwise, in low-bandwidth situations,
                        // we might be overwriting something that the user has subsequently added.
                        if changeCount == pasteboard.changeCount, let imageData = response.data, response.error == nil {
                            pasteboard.addImageWithData(imageData, forURL: url)
                        }

                        application.endBackgroundTask(taskId)
                }
            }
            actionSheetController.addAction(copyAction)
        }

        // If we're showing an arrow popup, set the anchor to the long press location.
        if let popoverPresentationController = actionSheetController.popoverPresentationController {
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(origin: touchPoint, size: touchSize)
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.delegate = self
        }

        if actionSheetController.popoverPresentationController != nil {
            displayedPopoverController = actionSheetController
        }

        actionSheetController.title = dialogTitle?.ellipsize(maxLength: ActionSheetTitleMaxLength)
        let cancelAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        self.present(actionSheetController, animated: true, completion: nil)
    }

    fileprivate func getImage(_ url: URL, success: @escaping (UIImage) -> Void) {
        Alamofire.request(url)
            .validate(statusCode: 200..<300)
            .response { response in
                if let data = response.data,
                   let image = UIImage.dataIsGIF(data) ? UIImage.imageFromGIFDataThreadSafe(data) : UIImage.imageFromDataThreadSafe(data) {
                    success(image)
                }
            }
    }
}

/**
 A third party search engine Browser extension
**/
extension BrowserViewController {

    func addCustomSearchButtonToWebView(_ webView: WKWebView) {
        //check if the search engine has already been added.
        let domain = webView.url?.domainURL.host
        let matches = self.profile.searchEngines.orderedEngines.filter {$0.shortName == domain}
        if !matches.isEmpty {
            self.customSearchEngineButton.tintColor = UIColor.gray
            self.customSearchEngineButton.isUserInteractionEnabled = false
        } else {
            self.customSearchEngineButton.tintColor = UIConstants.SystemBlueColor
            self.customSearchEngineButton.isUserInteractionEnabled = true
        }

        /*
         This is how we access hidden views in the WKContentView
         Using the public headers we can find the keyboard accessoryView which is not usually available.
         Specific values here are from the WKContentView headers.
         https://github.com/JaviSoto/iOS9-Runtime-Headers/blob/master/Frameworks/WebKit.framework/WKContentView.h
        */
        guard let webContentView = UIView.findSubViewWithFirstResponder(webView) else {
            /*
             In some cases the URL bar can trigger the keyboard notification. In that case the webview isnt the first responder
             and a search button should not be added.
             */
            return
        }

        guard let input = webContentView.perform(#selector(getter: UIResponder.inputAccessoryView)),
            let inputView = input.takeUnretainedValue() as? UIInputView,
            let nextButton = inputView.value(forKey: "_nextItem") as? UIBarButtonItem,
            let nextButtonView = nextButton.value(forKey: "view") as? UIView else {
                //failed to find the inputView instead lets use the inputAssistant
                addCustomSearchButtonToInputAssistant(webContentView)
                return
            }
            inputView.addSubview(self.customSearchEngineButton)
            self.customSearchEngineButton.snp.remakeConstraints { make in
                make.leading.equalTo(nextButtonView.snp.trailing).offset(20)
                make.width.equalTo(inputView.snp.height)
                make.top.equalTo(nextButtonView.snp.top)
                make.height.equalTo(inputView.snp.height)
            }
    }

    /**
     This adds the customSearchButton to the inputAssistant
     for cases where the inputAccessoryView could not be found for example
     on the iPad where it does not exist. However this only works on iOS9
     **/
    func addCustomSearchButtonToInputAssistant(_ webContentView: UIView) {
        guard customSearchBarButton == nil else {
            return //The searchButton is already on the keyboard
        }
        let inputAssistant = webContentView.inputAssistantItem
        let item = UIBarButtonItem(customView: customSearchEngineButton)
        customSearchBarButton = item
        inputAssistant.trailingBarButtonGroups.last?.barButtonItems.append(item)
    }

    func addCustomSearchEngineForFocusedElement() {
        guard let webView = tabManager.selectedTab?.webView else {
            return
        }
        webView.evaluateJavaScript("__firefox__.searchQueryForField()") { (result, _) in
            guard let searchQuery = result as? String, let favicon = self.tabManager.selectedTab!.displayFavicon else {
                //Javascript responded with an incorrectly formatted message. Show an error.
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.present(alert, animated: true, completion: nil)
                return
            }
            self.addSearchEngine(searchQuery, favicon: favicon)
            self.customSearchEngineButton.tintColor = UIColor.gray
            self.customSearchEngineButton.isUserInteractionEnabled = false
        }
    }

    func addSearchEngine(_ searchQuery: String, favicon: Favicon) {
        guard searchQuery != "",
            let iconURL = URL(string: favicon.url),
            let url = URL(string: searchQuery.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!),
            let shortName = url.domainURL.host else {
                let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                self.present(alert, animated: true, completion: nil)
                return
        }

        let alert = ThirdPartySearchAlerts.addThirdPartySearchEngine { alert in
            self.customSearchEngineButton.tintColor = UIColor.gray
            self.customSearchEngineButton.isUserInteractionEnabled = false
            SDWebImageManager.shared().downloadImage(with: iconURL, options: SDWebImageOptions.continueInBackground, progress: nil) { (image, error, cacheType, success, url) in
                guard image != nil else {
                    let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.profile.searchEngines.addSearchEngine(OpenSearchEngine(engineID: nil, shortName: shortName, image: image!, searchTemplate: searchQuery, suggestTemplate: nil, isCustomEngine: true))
                let Toast = SimpleToast()
                Toast.showAlertWithText(Strings.ThirdPartySearchEngineAdded)
            }
        }

        self.present(alert, animated: true, completion: {})
    }
}

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animate(withDuration: state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.findInPageContainer.layoutIfNeeded()
            self.snackBars.layoutIfNeeded()
        }

        if let webView = tabManager.selectedTab?.webView {
            webView.evaluateJavaScript("__firefox__.searchQueryForField()") { (result, _) in
                guard let _ = result as? String else {
                    return
                }
                self.addCustomSearchButtonToWebView(webView)
            }
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateViewConstraints()
        //If the searchEngineButton exists remove it form the keyboard
        if let buttonGroup = customSearchBarButton?.buttonGroup {
            buttonGroup.barButtonItems = buttonGroup.barButtonItems.filter { $0 != customSearchBarButton }
            customSearchBarButton = nil
        }

        if self.customSearchEngineButton.superview != nil {
            self.customSearchEngineButton.removeFromSuperview()
        }

        UIView.animate(withDuration: state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.findInPageContainer.layoutIfNeeded()
            self.snackBars.layoutIfNeeded()
        }
    }
}

extension BrowserViewController: SessionRestoreHelperDelegate {
    func sessionRestoreHelper(_ helper: SessionRestoreHelper, didRestoreSessionForTab tab: Tab) {
        tab.restoring = false

        if let tab = tabManager.selectedTab, tab.webView === tab.webView {
            updateUIForReaderHomeStateForTab(tab)
        }
    }
}

extension BrowserViewController: TabTrayDelegate {
    // This function animates and resets the tab chrome transforms when
    // the tab tray dismisses.
    func tabTrayDidDismiss(_ tabTray: TabTrayController) {
        resetBrowserChrome()
    }

    func tabTrayDidAddBookmark(_ tab: Tab) {
        guard let url = tab.url?.absoluteString, url.characters.count > 0 else { return }
        self.addBookmark(tab.tabState)
    }

    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListClientRecord? {
        guard let url = tab.url?.absoluteString, url.characters.count > 0 else { return nil }
        return profile.readingList?.createRecordWithURL(url, title: tab.title ?? url, addedBy: UIDevice.current.name).successValue
    }

    func tabTrayRequestsPresentationOf(_ viewController: UIViewController) {
        self.present(viewController, animated: false, completion: nil)
    }
}

// MARK: Browser Chrome Theming
extension BrowserViewController: Themeable {

    func applyTheme(_ themeName: String) {
        urlBar.applyTheme(themeName)
        toolbar?.applyTheme(themeName)
        readerModeBar?.applyTheme(themeName)

        topTabsViewController?.applyTheme(themeName)

        switch themeName {
        case Theme.NormalMode:
            header.blurStyle = .extraLight
            footerBackground?.blurStyle = .extraLight
        case Theme.PrivateMode:
            header.blurStyle = .dark
            footerBackground?.blurStyle = .dark
        default:
            log.debug("Unknown Theme \(themeName)")
        }
    }
}

// A small convienent class for wrapping a view with a blur background that can be modified
class BlurWrapper: UIView {
    var blurStyle: UIBlurEffectStyle = .extraLight {
        didSet {
            let newEffect = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            effectView.removeFromSuperview()
            effectView = newEffect
            insertSubview(effectView, belowSubview: wrappedView)
            effectView.snp.remakeConstraints { make in
                make.edges.equalTo(self)
            }
            effectView.isHidden = disableBlur
            switch blurStyle {
            case .extraLight, .light:
                background.backgroundColor = TopTabsUX.TopTabsBackgroundNormalColor
            case .extraDark, .dark:
                background.backgroundColor = TopTabsUX.TopTabsBackgroundPrivateColor
            default:
                assertionFailure("Unsupported blur style")
            }
        }
    }
    
    var disableBlur = false {
        didSet {
            effectView.isHidden = disableBlur
            background.isHidden = !disableBlur
        }
    }

    fileprivate var effectView: UIVisualEffectView
    fileprivate var wrappedView: UIView
    fileprivate lazy var background: UIView = {
        let background = UIView()
        background.isHidden = true
        return background
    }()

    init(view: UIView) {
        wrappedView = view
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        super.init(frame: CGRect.zero)

        addSubview(background)
        addSubview(effectView)
        addSubview(wrappedView)

        effectView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        wrappedView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        background.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol Themeable {
    func applyTheme(_ themeName: String)
}

extension BrowserViewController: FindInPageBarDelegate, FindInPageHelperDelegate {
    func findInPage(_ findInPage: FindInPageBar, didTextChange text: String) {
        find(text, function: "find")
    }

    func findInPage(_ findInPage: FindInPageBar, didFindNextWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findNext")
    }

    func findInPage(_ findInPage: FindInPageBar, didFindPreviousWithText text: String) {
        findInPageBar?.endEditing(true)
        find(text, function: "findPrevious")
    }

    func findInPageDidPressClose(_ findInPage: FindInPageBar) {
        updateFindInPageVisibility(visible: false)
    }

    fileprivate func find(_ text: String, function: String) {
        guard let webView = tabManager.selectedTab?.webView else { return }

        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\")
                          .replacingOccurrences(of: "\"", with: "\\\"")

        webView.evaluateJavaScript("__firefox__.\(function)(\"\(escaped)\")", completionHandler: nil)
    }

    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateCurrentResult currentResult: Int) {
        findInPageBar?.currentResult = currentResult
    }

    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateTotalResults totalResults: Int) {
        findInPageBar?.totalResults = totalResults
    }
}

extension BrowserViewController: JSPromptAlertControllerDelegate {
    func promptAlertControllerDidDismiss(_ alertController: JSPromptAlertController) {
        showQueuedAlertIfAvailable()
    }
}

private extension WKNavigationAction {
    /// Allow local requests only if the request is privileged.
    var isAllowed: Bool {
        guard let url = request.url else {
            return true
        }

        return !url.isWebPage(includeDataURIs: false) || !url.isLocal || request.isPrivileged
    }
}

extension BrowserViewController: TopTabsDelegate {
    func topTabsDidPressTabs() {
        urlBar.leaveOverlayMode(didCancel: true)
        self.urlBarDidPressTabs(urlBar)
    }
    
    func topTabsDidPressNewTab(_ isPrivate: Bool) {
        openBlankNewTab(isPrivate: isPrivate)
    }

    func topTabsDidTogglePrivateMode() {
        guard let selectedTab = tabManager.selectedTab else {
            return
        }
        urlBar.leaveOverlayMode()
        
        if selectedTab.isPrivate {
            if profile.prefs.boolForKey("settings.closePrivateTabs") ?? false {
                tabManager.removeAllPrivateTabsAndNotify(false)
                tabManager.showFocusPromoToast()
            }
        }
    }
    
    func topTabsDidChangeTab() {
        urlBar.leaveOverlayMode(didCancel: true)
    }
}
