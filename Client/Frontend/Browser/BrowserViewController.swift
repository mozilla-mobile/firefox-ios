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
import SDWebImage
import SwiftyJSON
import Telemetry
import Sentry

private let KVOLoading = "loading"
private let KVOEstimatedProgress = "estimatedProgress"
private let KVOURL = "URL"
private let KVOTitle = "title"
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
    var urlBar: URLBarView!
    var clipboardBarDisplayHandler: ClipboardBarDisplayHandler?
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    let webViewContainerToolbar = UIView()
    var statusBarOverlay: UIView!
    fileprivate(set) var toolbar: TabToolbar?
    fileprivate var searchController: SearchViewController?
    fileprivate var screenshotHelper: ScreenshotHelper!
    fileprivate var homePanelIsInline = false
    fileprivate var searchLoader: SearchLoader!
    fileprivate let snackBars = UIView()
    fileprivate var findInPageBar: FindInPageBar?
    fileprivate let findInPageContainer = UIView()

    lazy var mailtoLinkHandler: MailtoLinkHandler = MailtoLinkHandler()

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

    var openInHelper: OpenInHelper?

    // location label actions
    fileprivate var pasteGoAction: AccessibleAction!
    fileprivate var pasteAction: AccessibleAction!
    fileprivate var copyAddressAction: AccessibleAction!

    fileprivate weak var tabTrayController: TabTrayController!
    let profile: Profile
    let tabManager: TabManager

    // These views wrap the urlbar and toolbar to provide background effects on them
    var header: UIView!
    var footer: UIView!
    fileprivate var topTouchArea: UIButton!
    let urlBarTopTabsContainer = UIView(frame: CGRect.zero)
    var topTabsVisible: Bool {
        return topTabsViewController != nil
    }
    // Backdrop used for displaying greyed background for private tabs
    var webViewContainerBackdrop: UIView!

    var scrollController = TabScrollingController()

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
        
        if let _ = self.presentedViewController as? PhotonActionSheet {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
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
    }

    fileprivate func didInit() {
        screenshotHelper = ScreenshotHelper(controller: self)
        tabManager.addDelegate(self)
        tabManager.addNavigationDelegate(self)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        let isIpad = shouldShowTopTabsForTraitCollection(traitCollection)
        return (isPrivate || isIpad) ? UIStatusBarStyle.lightContent : UIStatusBarStyle.default
    }

    func shouldShowFooterForTraitCollection(_ previousTraitCollection: UITraitCollection) -> Bool {
        return previousTraitCollection.verticalSizeClass != .compact && previousTraitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabsForTraitCollection(_ newTraitCollection: UITraitCollection) -> Bool {
        return newTraitCollection.verticalSizeClass == .regular && newTraitCollection.horizontalSizeClass == .regular
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

        urlBar.topTabsIsShowing = showTopTabs
        urlBar.setShowToolbar(!showToolbar)
        toolbar?.removeFromSuperview()
        toolbar?.tabToolbarDelegate = nil
        toolbar = nil

        if showToolbar {
            toolbar = TabToolbar()
            footer.addSubview(toolbar!)
            toolbar?.tabToolbarDelegate = self
            let theme = (tabManager.selectedTab?.isPrivate ?? false) ? Theme.PrivateMode : Theme.NormalMode
            toolbar?.applyTheme(theme)
            updateTabCountUsingTabManager(self.tabManager)
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
        } else {
            topTabsContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            topTabsViewController?.view.removeFromSuperview()
            topTabsViewController?.removeFromParentViewController()
            topTabsViewController = nil
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
            if self.isViewLoaded {
                self.statusBarOverlay.backgroundColor = self.shouldShowTopTabsForTraitCollection(self.traitCollection) ? UIColor(rgb: 0x272727) : self.urlBar.backgroundColor
                self.setNeedsStatusBarAppearanceUpdate()
            }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELBookmarkStatusDidChange(_:)), name: NSNotification.Name(rawValue: BookmarkStatusChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappWillResignActiveNotification), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappDidBecomeActiveNotification), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BrowserViewController.SELappDidEnterBackgroundNotification), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        KeyboardHelper.defaultHelper.addDelegate(self)

        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.gray
        webViewContainerBackdrop.alpha = 0
        view.addSubview(webViewContainerBackdrop)

        webViewContainer = UIView()
        webViewContainer.addSubview(webViewContainerToolbar)
        view.addSubview(webViewContainer)

        // Temporary work around for covering the non-clipped web view content
        statusBarOverlay = UIView()
        view.addSubview(statusBarOverlay)

        topTouchArea = UIButton()
        topTouchArea.isAccessibilityElement = false
        topTouchArea.addTarget(self, action: #selector(BrowserViewController.SELtappedTopArea), for: UIControlEvents.touchUpInside)
        view.addSubview(topTouchArea)

        // Setup the URL bar, wrapped in a view to get transparency effect
        urlBar = URLBarView()
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.tabToolbarDelegate = self
        header = urlBarTopTabsContainer
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
                // Enter overlay mode and make the search controller appear.
                self.urlBar.enterOverlayMode(pasteboardContents, pasted: true, search: true)

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

        searchLoader = SearchLoader(profile: profile, urlBar: urlBar)

        footer = UIView()
        self.view.addSubview(footer)
        self.view.addSubview(snackBars)
        snackBars.backgroundColor = UIColor.clear
        self.view.addSubview(findInPageContainer)

        if AppConstants.MOZ_CLIPBOARD_BAR {
            clipboardBarDisplayHandler = ClipboardBarDisplayHandler(prefs: profile.prefs, tabManager: tabManager)
            clipboardBarDisplayHandler?.delegate = self
        }
        
        scrollController.urlBar = urlBar
        scrollController.header = header
        scrollController.footer = footer
        scrollController.snackBars = snackBars
        scrollController.webViewContainerToolbar = webViewContainerToolbar

        self.updateToolbarStateForTraitCollection(self.traitCollection)

        setupConstraints()
    }

    fileprivate func setupConstraints() {
        topTabsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.header)
            make.top.equalTo(urlBarTopTabsContainer)
        }
        
        urlBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(urlBarTopTabsContainer)
            make.height.equalTo(UIConstants.TopToolbarHeight)
            make.top.equalTo(topTabsContainer.snp.bottom)
        }

        header.snp.makeConstraints { make in
            scrollController.headerTopConstraint = make.top.equalTo(self.topLayoutGuide.snp.bottom).constraint
            make.left.right.equalTo(self.view)
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
        super.viewDidLayoutSubviews()
        statusBarOverlay.snp.remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(self.topLayoutGuide.length)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        // Make the web view the first responder so that it can show the selection menu.
        return tabManager.selectedTab?.webView?.becomeFirstResponder() ?? false
    }

    func loadQueuedTabs(receivedURLs: [URL]? = nil) {
        // Chain off of a trivial deferred in order to run on the background queue.
        succeed().upon() { res in
            self.dequeueQueuedTabs(receivedURLs: receivedURLs ?? [])
        }
    }

    fileprivate func dequeueQueuedTabs(receivedURLs: [URL]) {
        assert(!Thread.current.isMainThread, "This must be called in the background.")
        self.profile.queue.getQueuedTabs() >>== { cursor in

            // This assumes that the DB returns rows in some kind of sane order.
            // It does in practice, so WFM.
            if cursor.count > 0 {

                // Filter out any tabs received by a push notification to prevent dupes.
                let urls = cursor.flatMap { $0?.url.asURL }.filter { !receivedURLs.contains($0) }
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
                
            // Then, open any received URLs from push notifications.
            if !receivedURLs.isEmpty {
                DispatchQueue.main.async {
                    let unopenedReceivedURLs = receivedURLs.filter { self.tabManager.getTabForURL($0) == nil }

                    self.tabManager.addTabsForURLs(unopenedReceivedURLs, zombie: false)

                    if let lastURL = receivedURLs.last, let tab = self.tabManager.getTabForURL(lastURL) {
                        self.tabManager.selectTab(tab)
                    }
                }
            }
        }
    }

    // Because crashedLastLaunch is sticky, it does not get reset, we need to remember its
    // value so that we do not keep asking the user to restore their tabs.
    var displayedRestoreTabsAlert = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // On iPhone, if we are about to show the On-Boarding, blank out the tab so that it does
        // not flash before we present. This change of alpha also participates in the animation when
        // the intro view is dismissed.
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.alpha = (profile.prefs.intForKey(IntroViewControllerSeenProfileKey) != nil) ? 1.0 : 0.0
        }

        if !displayedRestoreTabsAlert && !cleanlyBackgrounded() && crashedLastLaunch() {
            displayedRestoreTabsAlert = true
            showRestoreTabsAlert()
        } else {
            tabManager.restoreTabs()
        }

        updateTabCountUsingTabManager(tabManager, animated: false)
        clipboardBarDisplayHandler?.checkIfShouldDisplayBar()
    }

    fileprivate func crashedLastLaunch() -> Bool {
        return Sentry.crashedLastLaunch
    }

    fileprivate func cleanlyBackgrounded() -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return false
        }
        return appDelegate.applicationCleanlyBackgrounded
    }

    fileprivate func showRestoreTabsAlert() {
        if !canRestoreTabs() {
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

    fileprivate func canRestoreTabs() -> Bool {
        guard let tabsToRestore = TabManager.tabsToRestore() else { return false }
        return tabsToRestore.count > 0
    }

    override func viewDidAppear(_ animated: Bool) {
        presentIntroViewController()
        self.webViewContainerToolbar.isHidden = false

        screenshotHelper.viewIsVisible = true
        screenshotHelper.takePendingScreenshots(tabManager.tabs)

        super.viewDidAppear(animated)

        if shouldShowWhatsNewTab() {
            // Only display if the SUMO topic has been configured in the Info.plist (present and not empty)
            if let whatsNewTopic = AppInfo.whatsNewTopic, whatsNewTopic != "" {
                if let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
                    self.openURLInNewTab(whatsNewURL, isPrivileged: false)
                    profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
                }
            }
        }

        if let toast = self.pendingToast {
            self.pendingToast = nil
            show(buttonToast: toast, afterWaiting: ButtonToastUX.ToastDelay)
        }
        showQueuedAlertIfAvailable()
    }

    // THe logic for shouldShowWhatsNewTab is as follows: If we do not have the LatestAppVersionProfileKey in
    // the profile, that means that this is a fresh install and we do not show the What's New. If we do have
    // that value, we compare it to the major version of the running app. If it is different then this is an
    // upgrade, downgrades are not possible, so we can show the What's New page.

    fileprivate func shouldShowWhatsNewTab() -> Bool {
        guard let latestMajorAppVersion = profile.prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first else {
            return false // Clean install, never show What's New
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
    }

    func resetBrowserChrome() {
        // animate and reset transform for tab chrome
        urlBar.updateAlphaForSubviews(1)
        footer.alpha = 1

        [header, footer, readerModeBar].forEach { view in
                view?.transform = CGAffineTransform.identity
        }
        statusBarOverlay.isHidden = false
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
            make.edges.equalTo(self.footer)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }

        footer.snp.remakeConstraints { make in
            scrollController.footerBottomConstraint = make.bottom.equalTo(self.view.snp.bottom).constraint
            make.leading.trailing.equalTo(self.view)
        }

        updateSnackBarConstraints()
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
        homePanelIsInline = inline

        if homePanelController == nil {
            let homePanelController = HomePanelViewController()
            homePanelController.profile = profile
            homePanelController.delegate = self
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
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        homePanelController.applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)
        let panelNumber = tabManager.selectedTab?.url?.fragment

        // splitting this out to see if we can get better crash reports when this has a problem
        var newSelectedButtonIndex = 0
        if let numberArray = panelNumber?.components(separatedBy: "=") {
            if let last = numberArray.last, let lastInt = Int(last) {
                newSelectedButtonIndex = lastInt
            }
        }
        homePanelController.selectedPanel = HomePanelType(rawValue: newSelectedButtonIndex)

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
            guard let url = url else {
                hideHomePanelController()
                return
            }
            if url.isAboutHomeURL {
                showHomePanelController(inline: true)
            } else if !url.isLocalUtility || url.isReaderModeURL {
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
        guard let path = keyPath else { assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")"); return }
        switch path {
        case KVOEstimatedProgress:
            guard webView == tabManager.selectedTab?.webView,
                let progress = change?[NSKeyValueChangeKey.newKey] as? Float else { break }
            if !(webView.url?.isLocalUtility ?? false) {
                urlBar.updateProgressBar(progress)
            } else {
                urlBar.hideProgressBar()
            }
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
        case KVOTitle:
            guard let tab = tabManager[webView] else { break }
            
            // Ensure that the tab title *actually* changed to prevent repeated calls
            // to navigateInTab(tab:).
            guard let title = tab.title else { break }
            if !title.isEmpty && title != tab.lastTitle {
                navigateInTab(tab: tab)
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
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
    }

    fileprivate func runScriptsOnWebView(_ webView: WKWebView) {
        webView.evaluateJavaScript("__firefox__.favicons.getFavicons()", completionHandler: nil)
        webView.evaluateJavaScript("__firefox__.metadata.extractMetadata()", completionHandler: nil)

        if #available(iOS 11, *) {
            if NoImageModeHelper.isActivated(profile.prefs) {
                webView.evaluateJavaScript("__firefox__.NoImageMode.setEnabled(true)", completionHandler: nil)
            }
        }
    }

    func updateUIForReaderHomeStateForTab(_ tab: Tab) {
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
                    print("Error getting bookmark status: \(result.failureValue ??? "nil").")
                    return
                }
                tab?.isBookmarked = bookmarked
            }
        }
    }
    // MARK: Opening New Tabs

    func switchToPrivacyMode(isPrivate: Bool ) {
//        applyTheme(isPrivate ? Theme.PrivateMode : Theme.NormalMode)

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
        _ = tabManager.addTabAndSelect(request, isPrivate: isPrivate)
        if url == nil && NewTabAccessors.getNewTabPage(profile.prefs) == .blankPage {
            urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
        }
    }

    func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false) {
        popToBVC()
        openURLInNewTab(nil, isPrivate: isPrivate, isPrivileged: true)
        
        if focusLocationField {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                // Without a delay, the text field fails to become first responder
                self.urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
            }
        }
    }

    fileprivate func popToBVC() {
        guard let currentViewController = navigationController?.topViewController else {
                return
        }
        currentViewController.dismiss(animated: true, completion: nil)
        if currentViewController != self {
            _ = self.navigationController?.popViewController(animated: true)
        } else if urlBar.inOverlayMode {
            urlBar.SELdidClickCancel()
        }
    }

    // MARK: User Agent Spoofing

    func resetSpoofedUserAgentIfRequired(_ webView: WKWebView, newURL: URL) {
        // Reset the UA when a different domain is being loaded
        if webView.url?.host != newURL.host {
            webView.customUserAgent = nil
        }
    }

    func restoreSpoofedUserAgentIfRequired(_ webView: WKWebView, newRequest: URLRequest) {
        // Restore any non-default UA from the request's header
        let ua = newRequest.value(forHTTPHeaderField: "User-Agent")
        webView.customUserAgent = ua != UserAgent.defaultUserAgent() ? ua : nil
    }

    fileprivate func presentActivityViewController(_ url: URL, tab: Tab? = nil, sourceView: UIView?, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection) {
        let helper = ShareExtensionHelper(url: url, tab: tab)

        let controller = helper.createActivityViewController({ [unowned self] completed, _ in
            // After dismissing, check to see if there were any prompts we queued up
            self.showQueuedAlertIfAvailable()

            // Usually the popover delegate would handle nil'ing out the references we have to it
            // on the BVC when displaying as a popover but the delegate method doesn't seem to be
            // invoked on iOS 10. See Bug 1297768 for additional details.
            self.displayedPopoverController = nil
            self.updateDisplayedPopoverProperties = nil
        })

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect
            popoverPresentationController.permittedArrowDirections = arrowDirection
            popoverPresentationController.delegate = self
        }

        present(controller, animated: true, completion: nil)

        LeanplumIntegration.sharedInstance.track(eventName: .userSharedWebpage)
    }

    func updateFindInPageVisibility(visible: Bool) {
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

    func navigateInTab(tab: Tab, to navigation: WKNavigation? = nil) {
        tabManager.expireSnackbars()

        guard let webView = tab.webView else {
            print("Cannot navigate in tab without a webView")
            return
        }

        if let url = webView.url, !url.isErrorPageURL && !url.isAboutHomeURL {
            tab.lastExecutedTime = Date.now()

            postLocationChangeNotificationForTab(tab, navigation: navigation)
            
            // Fire the readability check. This is here and not in the pageShow event handler in ReaderMode.js anymore
            // because that event wil not always fire due to unreliable page caching. This will either let us know that
            // the currently loaded page can be turned into reading mode or if the page already is in reading mode. We
            // ignore the result because we are being called back asynchronous when the readermode status changes.
            webView.evaluateJavaScript("\(ReaderModeNamespace).checkReadability()", completionHandler: nil)

            // Re-run additional scripts in webView to extract updated favicons and metadata.
            runScriptsOnWebView(webView)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
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
    
    // MARK: open in helper utils
    func addViewForOpenInHelper(_ openInHelper: OpenInHelper) {
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
    
    func removeOpenInView() {
        guard let _ = self.openInHelper else { return }
        webViewContainerToolbar.subviews.forEach { $0.removeFromSuperview() }
        
        webViewContainerToolbar.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        
        self.openInHelper = nil
    }
}

extension BrowserViewController: ClipboardBarDisplayHandlerDelegate {
    func shouldDisplay(clipboardBar bar: ButtonToast) {
        show(buttonToast: bar, duration: ClipboardBarToastUX.ToastDelay)
    }
}

extension BrowserViewController: QRCodeViewControllerDelegate {
    func scanSuccessOpenNewTabWithData(data: String) {
        self.openBlankNewTab(focusLocationField: false)
        self.urlBar(self.urlBar, didSubmitText: data)
    }
}

extension BrowserViewController: SettingsDelegate {
    func settingsOpenURLInNewTab(_ url: URL) {
        self.openURLInNewTab(url, isPrivileged: false)
    }
}

extension BrowserViewController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool) {
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
    
    func showTabTray() {
        webViewContainerToolbar.isHidden = true
        updateFindInPageVisibility(visible: false)
        
        let tabTrayController = TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)
        
        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        
        navigationController?.pushViewController(tabTrayController, animated: true)
        self.tabTrayController = tabTrayController
    }

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }
    
    func urlBarDidPressQRButton(_ urlBar: URLBarView) {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = self
        let controller = QRCodeNavigationController(rootViewController: qrCodeViewController)
        self.present(controller, animated: true, completion: nil)
    }

    func urlBarDidPressPageOptions(_ urlBar: URLBarView, from button: UIButton) {
        
        let actionMenuPresenter: (URL, Tab, UIView, UIPopoverArrowDirection) -> Void  = { (url, tab, view, _) in
            self.presentActivityViewController(url, tab: tab, sourceView: view, sourceRect: view.bounds, arrowDirection: .up)
        }
        
        let findInPageAction = {
            self.updateFindInPageVisibility(visible: true)
        }
        
        let successCallback: (String) -> Void = { (successMessage) in
            SimpleToast().showAlertWithText(successMessage, bottomContainer: self.webViewContainer)
        }
        
        guard let tab = tabManager.selectedTab, tab.url != nil else { return }
        
        // The logic of which actions appear when isnt final.
        let pageActions = getTabActions(tab: tab, buttonView: button, presentShareMenu: actionMenuPresenter,
                                        findInPage: findInPageAction, presentableVC: self, success: successCallback)

        presentSheetWith(actions: pageActions, on: self, from: button)
    }
    
    func urlBarDidLongPressPageOptions(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        guard let url = tab.canonicalURL?.displayURL else { return }
        presentActivityViewController(url, tab: tab, sourceView: button, sourceRect: button.bounds, arrowDirection: .up)
    }
    
    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        showTabTray()
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getHelper(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .available:
                    enableReaderMode()

                    LeanplumIntegration.sharedInstance.track(eventName: .useReaderView)
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
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading List. Maybe it’s already there?", comment: "Accessibility message e.g. spoken by VoiceOver after the user wanted to add current page to the Reading List and this was not done, likely because it already was in the Reading List, but perhaps also because of real failures."))
            print("readingList.createRecordWithURL(url: \"\(url.absoluteString)\", ...) failed with error: \(error)")
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

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.currentInitialURL
        if searchURL?.isErrorPageURL ?? true {
            searchURL = url
        }
        if let query = profile.searchEngines.queryForSearchURL(searchURL as URL?) {
            return (query, true)
        } else {
            return (url?.absoluteString, false)
        }
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
                let escapedQuery = possibleQuery.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
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
            Telemetry.default.recordSearch(location: .actionBar, searchEngine: engine.engineID ?? "other")
            finishEditingAndSubmit(searchURL, visitType: VisitType.typed)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            print("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
        }
    }

    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView) {
        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }
            showHomePanelController(inline: false)
        }

        LeanplumIntegration.sharedInstance.track(eventName: .interactWithURLBar)
    }

    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView) {
        hideSearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
    }
}

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
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
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil))
        if #available(iOS 11, *) {
            if let helper = tab.contentBlocker as? ContentBlockerHelper {
                let state = helper.userOverrideForTrackingProtection
                if state != .disallowUserOverride {
                    let title = state == .forceDisabled ? Strings.TrackingProtectionReloadWith : Strings.TrackingProtectionReloadWithout
                    controller.addAction(UIAlertAction(title: title, style: .default, handler: {_ in
                        helper.overridePrefsAndReloadTab(enableTrackingProtection: state == .forceDisabled)
                    }))
                }
            }
        }
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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        var actions: [[PhotonActionSheetItem]] = []

        actions.append(getHomePanelActions())
        actions.append(getOtherPanelActions(vcDelegate: self))
        // force a modal if the menu is being displayed in compact split screen
        let shouldSupress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: actions, on: self, from: button, supressPopover: shouldSupress)
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showTabTray()
    }
    
    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.NewTabTitle, style: .default, handler: { _ in
            self.tabManager.addTabAndSelect(isPrivate: false)
        }))
        controller.addAction(UIAlertAction(title: Strings.NewPrivateTabTitle, style: .default, handler: { _ in
            self.tabManager.addTabAndSelect(isPrivate: true)
        }))
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil))
        controller.popoverPresentationController?.sourceView = toolbar ?? urlBar
        controller.popoverPresentationController?.sourceRect = button.frame
        present(controller, animated: true, completion: nil)
    }

    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.bvc = self
            backForwardViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
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
        tab.webView?.addObserver(self, forKeyPath: KVOTitle, options: .new, context: nil)

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

        let nightModeHelper = NightModeHelper(tab: tab)
        tab.addHelper(nightModeHelper, name: NightModeHelper.name())

        // XXX: Bug 1390200 - Disable NSUserActivity/CoreSpotlight temporarily
        // let spotlightHelper = SpotlightHelper(tab: tab)
        // tab.addHelper(spotlightHelper, name: SpotlightHelper.name())

        tab.addHelper(LocalRequestHelper(), name: LocalRequestHelper.name())

        let historyStateHelper = HistoryStateHelper(tab: tab)
        historyStateHelper.delegate = self
        tab.addHelper(historyStateHelper, name: HistoryStateHelper.name())
        
        if #available(iOS 11, *) {
            (tab.contentBlocker as? ContentBlockerHelper)?.setupForWebView()
        }

        let metadataHelper = MetadataParserHelper(tab: tab, profile: profile)
        tab.addHelper(metadataHelper, name: MetadataParserHelper.name())
    }

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {
        tab.cancelQueuedAlerts()

        webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
        webView.removeObserver(self, forKeyPath: KVOLoading)
        webView.removeObserver(self, forKeyPath: KVOCanGoBack)
        webView.removeObserver(self, forKeyPath: KVOCanGoForward)
        webView.scrollView.removeObserver(self.scrollController, forKeyPath: KVOContentSize)
        webView.removeObserver(self, forKeyPath: KVOURL)
        webView.removeObserver(self, forKeyPath: KVOTitle)

        webView.uiDelegate = nil
        webView.scrollView.delegate = nil
        webView.removeFromSuperview()
    }

    fileprivate func findSnackbar(_ barToFind: SnackBar) -> Int? {
        let bars = snackBars.subviews
        for (index, bar) in bars.enumerated() where bar === barToFind {
            return index
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
                make.leading.trailing.equalTo(self.view)
                self.snackBars.layer.borderWidth = 0
            } else {
                make.centerX.equalTo(self.view)
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
        presentSignInViewController() // TODO UX Right now the flow for sign in and create account is the same
    }

    func homePanelViewControllerDidRequestToSignIn(_ homePanelViewController: HomePanelViewController) {
        presentSignInViewController() // TODO UX Right now the flow for sign in and create account is the same
    }

    func homePanelViewControllerDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        let tab = self.tabManager.addTab(PrivilegedRequest(url: url) as URLRequest, afterTab: self.tabManager.selectedTab, isPrivate: isPrivate)
        // If we are showing toptabs a user can just use the top tab bar
        // If in overlay mode switching doesnt correctly dismiss the homepanels
        guard !topTabsVisible, !self.urlBar.inOverlayMode else {
            return
        }
        // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
        let toast = ButtonToast(labelText: Strings.ContextMenuButtonToastNewTabOpenedLabelText, buttonText: Strings.ContextMenuButtonToastNewTabOpenedButtonText, completion: { buttonPressed in
            if buttonPressed {
                self.tabManager.selectTab(tab)
            }
        })
        self.show(buttonToast: toast)
    }
}

extension BrowserViewController: SearchViewControllerDelegate {
    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL) {
        finishEditingAndSubmit(url, visitType: VisitType.typed)
    }

    func searchViewController(_ searchViewController: SearchViewController, didLongPressSuggestion suggestion: String) {
        self.urlBar.setLocation(suggestion, search: true)
    }

    func presentSearchSettingsController() {
        let settingsNavigationController = SearchSettingsTableViewController()
        settingsNavigationController.model = self.profile.searchEngines
        settingsNavigationController.profile = self.profile
        let navController = ModalSettingsNavigationController(rootViewController: settingsNavigationController)

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
            if tab.isPrivate != previous?.isPrivate {
                applyTheme(tab.isPrivate ? Theme.PrivateMode : Theme.NormalMode)
            }
            if tab.isPrivate {
                readerModeCache = MemoryReaderModeCache.sharedInstance
                
            } else {
                readerModeCache = DiskReaderModeCache.sharedInstance
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
                                print("Error getting bookmark status: \($0.failureValue ??? "nil").")
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
        if !(selected?.webView?.url?.isLocalUtility ?? false) {
            self.urlBar.updateProgressBar(Float(selected?.estimatedProgress ?? 0))
        }

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

    func show(buttonToast: ButtonToast, afterWaiting delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore, duration: DispatchTimeInterval = SimpleToastUX.ToastDismissAfter) {
        // If BVC isnt visible hold on to this toast until viewDidAppear
        if self.view.window == nil {
            self.pendingToast = buttonToast
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.view.addSubview(buttonToast)
            buttonToast.snp.makeConstraints { make in
                make.left.right.equalTo(self.view)
                make.bottom.equalTo(self.webViewContainer)
            }
            buttonToast.showToast(duration: duration)
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
            toolbar?.updateTabCount(count, animated: animated)
            urlBar.updateTabCount(count, animated: !urlBar.inOverlayMode)
            topTabsViewController?.updateTabCount(count, animated: animated)
        }
    }
}

/// List of schemes that are allowed to open a popup window
private let SchemesAllowedToOpenPopups = ["http", "https", "javascript", "data"]

extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }

        if !navigationAction.isAllowed {
            print("Denying unprivileged request: \(navigationAction.request)")
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
            print("WebContent process has crashed. Trying to reloadFromOrigin to restart it.")
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
             openInHelper.openInView = navigationToolbar.menuButton
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
        let encodedStyle: [String: Any] = style.encodeAsDictionary()
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
            if let style = ReaderModeStyle(dict: dict as [String: AnyObject]) {
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
                    if let style = ReaderModeStyle(dict: dict as [String: AnyObject]) {
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
    @discardableResult func presentIntroViewController(_ force: Bool = false, animated: Bool = true) -> Bool {
        if let deeplink = self.profile.prefs.stringForKey("AdjustDeeplinkKey"), let url = URL(string: deeplink) {
            self.launchFxAFromDeeplinkURL(url)
            return true
        }
        
        if force || profile.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            // On iPad we present it modally in a controller
            if topTabsVisible {
                introViewController.preferredContentSize = CGSize(width: IntroViewControllerUX.Width, height: IntroViewControllerUX.Height)
                introViewController.modalPresentationStyle = UIModalPresentationStyle.formSheet
            }
            present(introViewController, animated: animated) {
                // On first run (and forced) open up the homepage in the background.
                if let homePageURL = HomePageAccessors.getHomePage(self.profile.prefs), let tab = self.tabManager.selectedTab, DeviceInfo.hasConnectivity() {
                    tab.loadRequest(URLRequest(url: homePageURL))
                }
            }

            return true
        }

        return false
    }
    
    func launchFxAFromDeeplinkURL(_ url: URL) {
        self.profile.prefs.removeObjectForKey("AdjustDeeplinkKey")
        var query = url.getQuery()
        query["entrypoint"] = "adjust_deepklink_ios"
        let fxaParams: FxALaunchParams
        fxaParams = FxALaunchParams(query: query)
        self.presentSignInViewController(fxaParams)
    }

    func introViewControllerDidFinish(_ introViewController: IntroViewController, requestToLogin: Bool) {
        self.profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
        introViewController.dismiss(animated: true) { finished in
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
            
            if requestToLogin {
                self.presentSignInViewController()
            }
        }
    }

    func presentSignInViewController(_ fxaOptions: FxALaunchParams? = nil) {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let vcToPresent: UIViewController
        if profile.hasAccount() {
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = profile
            settingsTableViewController.tabManager = tabManager
            vcToPresent = settingsTableViewController
        } else {
            let signInVC = FxAContentViewController(profile: profile, fxaOptions: fxaOptions)
            signInVC.delegate = self            
            signInVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(BrowserViewController.dismissSignInViewController))
            vcToPresent = signInVC
        }

        let settingsNavigationController = SettingsNavigationController(rootViewController: vcToPresent)
		settingsNavigationController.modalPresentationStyle = .formSheet
        settingsNavigationController.navigationBar.isTranslucent = false
        self.present(settingsNavigationController, animated: true, completion: nil)
    }

    func dismissSignInViewController() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension BrowserViewController: FxAContentViewControllerDelegate {
    func contentViewControllerDidSignIn(_ viewController: FxAContentViewController, withFlags flags: FxALoginFlags) {
        if flags.verified {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func contentViewControllerDidCancel(_ viewController: FxAContentViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BrowserViewController: ContextMenuHelperDelegate {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UIGestureRecognizer) {
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
                    let tab = self.tabManager.addTab(URLRequest(url: rURL as URL), afterTab: currentTab, isPrivate: isPrivate)
                    LeanplumIntegration.sharedInstance.track(eventName: .openedNewTab, withParameters: ["Source": "Long Press Context Menu" as AnyObject])
                    guard !self.topTabsVisible else {
                        return
                    }
                    // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
                    let toast = ButtonToast(labelText: Strings.ContextMenuButtonToastNewTabOpenedLabelText, buttonText: Strings.ContextMenuButtonToastNewTabOpenedButtonText, completion: { buttonPressed in
                        if buttonPressed {
                            self.tabManager.selectTab(tab)
                        }
                    })
                    self.show(buttonToast: toast)
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
                UIPasteboard.general.url = url as URL
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
                    self.getImage(url as URL) {
                        UIImageWriteToSavedPhotosAlbum($0, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                } else {
                    let accessDenied = UIAlertController(title: NSLocalizedString("Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7"), message: NSLocalizedString("This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7"), preferredStyle: UIAlertControllerStyle.alert)
                    let dismissAction = UIAlertAction(title: UIConstants.CancelString, style: UIAlertActionStyle.default, handler: nil)
                    accessDenied.addAction(dismissAction)
                    let settingsAction = UIAlertAction(title: NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7"), style: UIAlertActionStyle.default ) { (action: UIAlertAction!) -> Void in
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:])
                    }
                    accessDenied.addAction(settingsAction)
                    self.present(accessDenied, animated: true, completion: nil)
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

    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer) {
        displayedPopoverController?.dismiss(animated: true) {
            self.displayedPopoverController = nil
        }
    }
}

extension BrowserViewController {
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            LeanplumIntegration.sharedInstance.track(eventName: .saveImage)
        }
    }
}

extension BrowserViewController: HistoryStateHelperDelegate {
    func historyStateHelper(_ historyStateHelper: HistoryStateHelper, didPushOrReplaceStateInTab tab: Tab) {
        navigateInTab(tab: tab)
        tabManager.storeChanges()
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
            SDWebImageManager.shared().loadImage(with: iconURL, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                guard let image = image else {
                    let alert = ThirdPartySearchAlerts.failedToAddThirdPartySearch()
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.profile.searchEngines.addSearchEngine(OpenSearchEngine(engineID: nil, shortName: shortName, image: image, searchTemplate: searchQuery, suggestTemplate: nil, isCustomEngine: true))
                let Toast = SimpleToast()
                Toast.showAlertWithText(Strings.ThirdPartySearchEngineAdded, bottomContainer: self.webViewContainer)
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
        let ui: [Themeable?] = [urlBar, toolbar, readerModeBar, topTabsViewController]
        ui.forEach { $0?.applyTheme(themeName) }
        statusBarOverlay.backgroundColor = shouldShowTopTabsForTraitCollection(traitCollection) ? UIColor(rgb: 0x272727) : urlBar.backgroundColor
        setNeedsStatusBarAppearanceUpdate()
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

extension BrowserViewController: TopTabsDelegate {
    func topTabsDidPressTabs() {
        urlBar.leaveOverlayMode(didCancel: true)
        self.urlBarDidPressTabs(urlBar)
    }
    
    func topTabsDidPressNewTab(_ isPrivate: Bool) {
        openBlankNewTab(focusLocationField: false, isPrivate: isPrivate)
    }

    func topTabsDidTogglePrivateMode() {
        guard let selectedTab = tabManager.selectedTab else {
            return
        }
        urlBar.leaveOverlayMode()
    }
    
    func topTabsDidChangeTab() {
        urlBar.leaveOverlayMode(didCancel: true)
    }
}

extension BrowserViewController: ClientPickerViewControllerDelegate, InstructionsViewControllerDelegate {
    func instructionsViewControllerDidClose(_ instructionsViewController: InstructionsViewController) {
        self.popToBVC()
    }

    func clientPickerViewControllerDidCancel(_ clientPickerViewController: ClientPickerViewController) {
        self.popToBVC()
    }

    func clientPickerViewController(_ clientPickerViewController: ClientPickerViewController, didPickClients clients: [RemoteClient]) {
        guard let tab = tabManager.selectedTab,
            let url = tab.canonicalURL?.displayURL?.absoluteString else { return }
        let shareItem = ShareItem(url: url, title: tab.title, favicon: tab.displayFavicon)
        guard shareItem.isShareable else {
            let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.popToBVC()})
            present(alert, animated: true, completion: nil)
            return
        }
        profile.sendItems([shareItem], toClients: clients).uponQueue(DispatchQueue.main) { _ in
            self.popToBVC()
        }
    }
}

