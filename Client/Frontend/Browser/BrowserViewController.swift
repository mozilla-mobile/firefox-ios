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
import MobileCoreServices
import SDWebImage
import SwiftyJSON
import Telemetry
import Sentry
import Deferred

private let KVOs: [KVOConstants] = [
    .estimatedProgress,
    .loading,
    .canGoBack,
    .canGoForward,
    .URL,
    .title,
]

private let ActionSheetTitleMaxLength = 120

private struct BrowserViewControllerUX {
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
    var statusBarOverlay: UIView!
    fileprivate(set) var toolbar: TabToolbar?
    var searchController: SearchViewController?
    fileprivate var screenshotHelper: ScreenshotHelper!
    fileprivate var homePanelIsInline = false
    fileprivate var searchLoader: SearchLoader?
    fileprivate let alertStackView = UIStackView() // All content that appears above the footer should be added to this view. (Find In Page/SnackBars)
    fileprivate var findInPageBar: FindInPageBar?

    lazy var mailtoLinkHandler: MailtoLinkHandler = MailtoLinkHandler()

    lazy fileprivate var customSearchEngineButton: UIButton = {
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "AddSearch")?.withRenderingMode(.alwaysTemplate), for: [])
        searchButton.addTarget(self, action: #selector(addCustomSearchEngineForFocusedElement), for: .touchUpInside)
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

    var pendingToast: Toast? // A toast that might be waiting for BVC to appear before displaying
    var downloadToast: DownloadToast? // A toast that is showing the combined download progress

    // Tracking navigation items to record history types.
    // TODO: weak references?
    var ignoredNavigation = Set<WKNavigation>()
    var typedNavigation = [WKNavigation: VisitType]()
    var navigationToolbar: TabToolbarProtocol {
        return toolbar ?? urlBar
    }

    var topTabsViewController: TopTabsViewController?
    let topTabsContainer = UIView()

    // Keep track of allowed `URLRequest`s from `webView(_:decidePolicyFor:decisionHandler:)` so
    // that we can obtain the originating `URLRequest` when a `URLResponse` is received. This will
    // allow us to re-trigger the `URLRequest` if the user requests a file to be downloaded.
    var pendingRequests = [String: URLRequest]()

    // This is set when the user taps "Download Link" from the context menu. We then force a
    // download of the next request through the `WKNavigationDelegate` that matches this web view.
    weak var pendingDownloadWebView: WKWebView?

    let downloadQueue = DownloadQueue()

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
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        dismissVisibleMenus()

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
        downloadQueue.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(displayThemeChanged), name: .DisplayThemeChanged, object: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.statusBarStyle
    }

    @objc func displayThemeChanged(notification: Notification) {
        applyTheme()
    }

    func shouldShowFooterForTraitCollection(_ previousTraitCollection: UITraitCollection) -> Bool {
        return previousTraitCollection.verticalSizeClass != .compact && previousTraitCollection.horizontalSizeClass != .regular
    }

    func shouldShowTopTabsForTraitCollection(_ newTraitCollection: UITraitCollection) -> Bool {
        return newTraitCollection.verticalSizeClass == .regular && newTraitCollection.horizontalSizeClass == .regular
    }

    func toggleSnackBarVisibility(show: Bool) {
        if show {
            UIView.animate(withDuration: 0.1, animations: { self.alertStackView.isHidden = false })
        } else {
            alertStackView.isHidden = true
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
            toolbar?.applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            toolbar?.applyTheme()
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
                self.statusBarOverlay.backgroundColor = self.shouldShowTopTabsForTraitCollection(self.traitCollection) ? UIColor.Photon.Grey80 : self.urlBar.backgroundColor
                self.setNeedsStatusBarAppearanceUpdate()
            }
            }, completion: nil)
    }

    func dismissVisibleMenus() {
        displayedPopoverController?.dismiss(animated: true)
        if let _ = self.presentedViewController as? PhotonActionSheet {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    @objc func appDidEnterBackgroundNotification() {
        displayedPopoverController?.dismiss(animated: false) {
            self.displayedPopoverController = nil
        }
    }

    @objc func tappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

   @objc  func appWillResignActiveNotification() {
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

    @objc func appDidBecomeActiveNotification() {
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
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActiveNotification), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActiveNotification), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: .UIApplicationDidEnterBackground, object: nil)
        KeyboardHelper.defaultHelper.addDelegate(self)

        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.Photon.Grey50
        webViewContainerBackdrop.alpha = 0
        view.addSubview(webViewContainerBackdrop)

        webViewContainer = UIView()
        view.addSubview(webViewContainer)

        // Temporary work around for covering the non-clipped web view content
        statusBarOverlay = UIView()
        view.addSubview(statusBarOverlay)

        topTouchArea = UIButton()
        topTouchArea.isAccessibilityElement = false
        topTouchArea.addTarget(self, action: #selector(tappedTopArea), for: .touchUpInside)
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
        pasteGoAction = AccessibleAction(name: Strings.PasteAndGoTitle, handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.general.string {
                self.urlBar(self.urlBar, didSubmitText: pasteboardContents)
                return true
            }
            return false
        })
        pasteAction = AccessibleAction(name: Strings.PasteTitle, handler: { () -> Bool in
            if let pasteboardContents = UIPasteboard.general.string {
                // Enter overlay mode and make the search controller appear.
                self.urlBar.enterOverlayMode(pasteboardContents, pasted: true, search: true)

                return true
            }
            return false
        })
        copyAddressAction = AccessibleAction(name: Strings.CopyAddressTitle, handler: { () -> Bool in
            if let url = self.urlBar.currentURL {
                UIPasteboard.general.url = url as URL
            }
            return true
        })

        view.addSubview(alertStackView)
        footer = UIView()
        view.addSubview(footer)
        alertStackView.axis = .vertical
        alertStackView.alignment = .center

        clipboardBarDisplayHandler = ClipboardBarDisplayHandler(prefs: profile.prefs, tabManager: tabManager)
        clipboardBarDisplayHandler?.delegate = self

        scrollController.urlBar = urlBar
        scrollController.readerModeBar = readerModeBar
        scrollController.header = header
        scrollController.footer = footer
        scrollController.snackBars = alertStackView

        self.updateToolbarStateForTraitCollection(self.traitCollection)

        setupConstraints()

        // Setup UIDropInteraction to handle dragging and dropping
        // links into the view from other apps.
        if #available(iOS 11, *) {
            let dropInteraction = UIDropInteraction(delegate: self)
            view.addInteraction(dropInteraction)
        }
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
                let urls = cursor.compactMap { $0?.url.asURL }.filter { !receivedURLs.contains($0) }
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
            self.view.alpha = (profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil) ? 1.0 : 0.0
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
        guard canRestoreTabs() else {
            self.tabManager.addTabAndSelect()
            return
        }
        let alert = UIAlertController.restoreTabsAlert(
            okayCallback: { _ in
                self.tabManager.restoreTabs()
            },
            noCallback: { _ in
                self.tabManager.addTabAndSelect()
            }
        )
        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func canRestoreTabs() -> Bool {
        guard let tabsToRestore = TabManager.tabsToRestore() else { return false }
        return !tabsToRestore.isEmpty
    }

    override func viewDidAppear(_ animated: Bool) {
        presentIntroViewController()

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
            show(toast: toast, afterWaiting: ButtonToastUX.ToastDelay)
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
                view?.transform = .identity
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

        alertStackView.snp.remakeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view.snp.width)
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

        homePanelController.applyTheme()

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
                if let readerMode = self.tabManager.selectedTab?.getContentScript(name: ReaderMode.name()) as? ReaderMode, readerMode.state == .active {
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
            } else if url.isErrorPageURL || !url.isLocalUtility || url.isReaderModeURL {
                hideHomePanelController()
            }
        }
    }

    fileprivate func showSearchController() {
        if searchController != nil {
            return
        }

        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        searchController = SearchViewController(profile: profile, isPrivate: isPrivate)
        searchController!.searchEngines = profile.searchEngines
        searchController!.searchDelegate = self

        searchLoader = SearchLoader(profile: profile, urlBar: urlBar)
        searchLoader?.addListener(searchController!)

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
            searchLoader = nil
        }
    }

    func finishEditingAndSubmit(_ url: URL, visitType: VisitType) {
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
        _ = profile.bookmarks.shareItem(shareItem)
        var userData = [QuickActions.TabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActions.TabTitleKey] = title
        }
        QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
            withUserData: userData,
            toApplication: UIApplication.shared)
    }

    override func accessibilityPerformEscape() -> Bool {
        if urlBar.inOverlayMode {
            urlBar.didClickCancel()
            return true
        } else if let selectedTab = tabManager.selectedTab, selectedTab.canGoBack {
            selectedTab.goBack()
            return true
        }
        return false
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView else {
            assert(false)
            return
        }
        guard let kp = keyPath, let path = KVOConstants(rawValue: kp) else {
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
            return
        }

        switch path {
        case .estimatedProgress:
            guard webView == tabManager.selectedTab?.webView,
                let progress = change?[.newKey] as? Float else { break }
            if !(webView.url?.isLocalUtility ?? false) {
                urlBar.updateProgressBar(progress)
            } else {
                urlBar.hideProgressBar()
            }
        case .loading:
            guard let loading = change?[.newKey] as? Bool else { break }

            if webView == tabManager.selectedTab?.webView {
                navigationToolbar.updateReloadStatus(loading)
            }

            if !loading {
                runScriptsOnWebView(webView)
            }
        case .URL:
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
        case .title:
            guard let tab = tabManager[webView] else { break }

            // Ensure that the tab title *actually* changed to prevent repeated calls
            // to navigateInTab(tab:).
            guard let title = tab.title else { break }
            if !title.isEmpty && title != tab.lastTitle {
                navigateInTab(tab: tab)
            }
        case .canGoBack:
            guard webView == tabManager.selectedTab?.webView,
                let canGoBack = change?[.newKey] as? Bool else { break }

            navigationToolbar.updateBackStatus(canGoBack)
        case .canGoForward:
            guard webView == tabManager.selectedTab?.webView,
                let canGoForward = change?[.newKey] as? Bool else { break }

            navigationToolbar.updateForwardStatus(canGoForward)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
    }

    fileprivate func runScriptsOnWebView(_ webView: WKWebView) {
        guard let url = webView.url, url.isWebPage(), !url.isLocal else {
            return
        }
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
                NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
            } else {
                hideReaderModeBar(animated: false)
                NotificationCenter.default.removeObserver(self, name: .DynamicFontChanged, object: nil)
            }

            updateInContentHomePanel(url as URL)
        }
    }

    /// Updates the URL bar text and button states.
    /// Call this whenever the page URL changes.
    fileprivate func updateURLBarDisplayURL(_ tab: Tab) {
        urlBar.currentURL = tab.url?.displayURL

        let isPage = tab.url?.displayURL?.isWebPage() ?? false
        navigationToolbar.updatePageStatus(isPage)
    }

    // MARK: Opening New Tabs
    func switchToPrivacyMode(isPrivate: Bool) {
        let tabTrayController = self.tabTrayController ?? TabTrayController(tabManager: tabManager, profile: profile, tabTrayDelegate: self)
        if tabTrayController.privateMode != isPrivate {
            tabTrayController.changePrivacyMode(isPrivate)
        }
        self.tabTrayController = tabTrayController

        topTabsViewController?.applyUIMode(isPrivate: isPrivate)
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
    }

    func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false, searchFor searchText: String? = nil) {
        popToBVC()
        openURLInNewTab(nil, isPrivate: isPrivate, isPrivileged: true)
        let freshTab = tabManager.selectedTab

        if focusLocationField {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                // Without a delay, the text field fails to become first responder
                // Check that the newly created tab is still selected.
                // This let's the user spam the Cmd+T button without lots of responder changes.
                guard freshTab == self.tabManager.selectedTab else { return }
                self.urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
                if let text = searchText {
                    self.urlBar.setLocation(text, search: true)
                }
            }
        }
    }

    func openSearchNewTab(isPrivate: Bool = false, _ text: String) {
        popToBVC()
        let engine = profile.searchEngines.defaultEngine
        if let searchURL = engine.searchURLForQuery(text) {
            openURLInNewTab(searchURL, isPrivate: isPrivate, isPrivileged: true)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            print("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
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
            urlBar.didClickCancel()
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
        LeanPlumClient.shared.track(event: .userSharedWebpage)
    }

    func updateFindInPageVisibility(visible: Bool, tab: Tab? = nil) {
        if visible {
            if findInPageBar == nil {
                let findInPageBar = FindInPageBar()
                self.findInPageBar = findInPageBar
                findInPageBar.delegate = self
                alertStackView.addArrangedSubview(findInPageBar)

                findInPageBar.snp.makeConstraints { make in
                    make.height.equalTo(UIConstants.ToolbarHeight)
                    make.leading.trailing.equalTo(alertStackView)
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
            let tab = tab ?? tabManager.selectedTab
            guard let webView = tab?.webView else { return }
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
        controller.modalPresentationStyle = .formSheet
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
        notificationCenter.post(name: .OnLocationChange, object: self, userInfo: info)
    }

    func navigateInTab(tab: Tab, to navigation: WKNavigation? = nil) {
        tabManager.expireSnackbars()

        guard let webView = tab.webView else {
            print("Cannot navigate in tab without a webView")
            return
        }

        if let url = webView.url {
            if !url.isErrorPageURL, !url.isAboutHomeURL, !url.isFileURL {
                postLocationChangeNotificationForTab(tab, navigation: navigation)

                // Fire the readability check. This is here and not in the pageShow event handler in ReaderMode.js anymore
                // because that event wil not always fire due to unreliable page caching. This will either let us know that
                // the currently loaded page can be turned into reading mode or if the page already is in reading mode. We
                // ignore the result because we are being called back asynchronous when the readermode status changes.
                webView.evaluateJavaScript("\(ReaderModeNamespace).checkReadability()", completionHandler: nil)

                // Re-run additional scripts in webView to extract updated favicons and metadata.
                runScriptsOnWebView(webView)
            }

            TabEvent.post(.didChangeURL(url), for: tab)
        }

        if tab === tabManager.selectedTab {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
            // must be followed by LayoutChanged, as ScreenChanged will make VoiceOver
            // cursor land on the correct initial element, but if not followed by LayoutChanged,
            // VoiceOver will sometimes be stuck on the element, not allowing user to move
            // forward/backward. Strange, but LayoutChanged fixes that.
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        } else if let webView = tab.webView {
            // To Screenshot a tab that is hidden we must add the webView,
            // then wait enough time for the webview to render.
            view.insertSubview(webView, at: 0)
            // This is kind of a hacky fix for Bug 1476637 to prevent webpages from focusing the
            // touch-screen keyboard from the background even though they shouldn't be able to.
            webView.resignFirstResponder()

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                self.screenshotHelper.takeScreenshot(tab)
                if webView.superview == self.view {
                    webView.removeFromSuperview()
                }
            }
        }

        // Remember whether or not a desktop site was requested
        tab.desktopSite = webView.customUserAgent?.isEmpty == false
    }
}

extension BrowserViewController: ClipboardBarDisplayHandlerDelegate {
    func shouldDisplay(clipboardBar bar: ButtonToast) {
        show(toast: bar, duration: ClipboardBarToastUX.ToastDelay)
    }
}

extension BrowserViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        openBlankNewTab(focusLocationField: false)
        finishEditingAndSubmit(url, visitType: VisitType.typed)
        UnifiedTelemetry.recordEvent(category: .action, method: .scan, object: .qrCodeURL)
    }

    func didScanQRCodeWithText(_ text: String) {
        openBlankNewTab(focusLocationField: false)
        submitSearchText(text)
        UnifiedTelemetry.recordEvent(category: .action, method: .scan, object: .qrCodeText)
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

        guard let tab = tabManager.selectedTab, let urlString = tab.url?.absoluteString else { return }

        let deferredBookmarkStatus: Deferred<Maybe<Bool>> = fetchBookmarkStatus(for: urlString)
        let deferredPinnedTopSiteStatus: Deferred<Maybe<Bool>> = fetchPinnedTopSiteStatus(for: urlString)

        // Wait for both the bookmark status and the pinned status
        deferredBookmarkStatus.both(deferredPinnedTopSiteStatus).uponQueue(.main) {
            let isBookmarked = $0.successValue ?? false
            let isPinned = $1.successValue ?? false
            let pageActions = self.getTabActions(tab: tab, buttonView: button, presentShareMenu: actionMenuPresenter,
                                                 findInPage: findInPageAction, presentableVC: self, isBookmarked: isBookmarked,
                                                 isPinned: isPinned, success: successCallback)
            self.presentSheetWith(title: Strings.PageActionMenuTitle, actions: pageActions, on: self, from: button)
        }
    }

    func urlBarDidLongPressPageOptions(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        guard let url = tab.canonicalURL?.displayURL, self.presentedViewController == nil else {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        presentActivityViewController(url, tab: tab, sourceView: button, sourceRect: button.bounds, arrowDirection: .up)
    }

    func urlBarDidTapShield(_ urlBar: URLBarView, from button: UIButton) {
        if #available(iOS 11.0, *), let tab = self.tabManager.selectedTab {
            let trackingProtectionMenu = self.getTrackingSubMenu(for: tab)
            guard !trackingProtectionMenu.isEmpty else { return }
            self.presentSheetWith(actions: trackingProtectionMenu, on: self, from: urlBar)
        }
    }

    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        showTabTray()
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        if let tab = tabManager.selectedTab {
            if let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode {
                switch readerMode.state {
                case .available:
                    enableReaderMode()
                    UnifiedTelemetry.recordEvent(category: .action, method: .tap, object: .readerModeOpenButton)
                    LeanPlumClient.shared.track(event: .useReaderView)
                case .active:
                    disableReaderMode()
                    UnifiedTelemetry.recordEvent(category: .action, method: .tap, object: .readerModeCloseButton)
                case .unavailable:
                    break
                }
            }
        }
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
               let url = tab.url?.displayURL
            else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Could not add page to Reading list", comment: "Accessibility message e.g. spoken by VoiceOver after adding current webpage to the Reading List failed."))
                return false
        }

        let result = profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)

        switch result.value {
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
        let urlActions = self.getLongPressLocationBarActions(with: urlBar)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        if #available(iOS 11.0, *), let tab = self.tabManager.selectedTab {
            let trackingProtectionMenu = self.getTrackingMenu(for: tab, presentingOn: urlBar)
            self.presentSheetWith(actions: [urlActions, trackingProtectionMenu], on: self, from: urlBar)
        } else {
            self.presentSheetWith(actions: [urlActions], on: self, from: urlBar)
        }
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        if let selectedTab = tabManager.selectedTab, homePanelController == nil {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController?.searchQuery = text
            searchLoader?.query = text
        }
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.index(of: " ") else {
            submitSearchText(text)
            return
        }

        let possibleKeyword = String(trimmedText[..<possibleKeywordQuerySeparatorSpace])
        let possibleQuery = String(trimmedText[trimmedText.index(after: possibleKeywordQuerySeparatorSpace)...])

        profile.bookmarks.getURLForKeywordSearch(possibleKeyword).uponQueue(.main) { result in
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
        guard let profile = profile as? BrowserProfile else {
            return
        }

        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil)
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }
            showHomePanelController(inline: false)
        }

        LeanPlumClient.shared.track(event: .interactWithURLBar)
    }

    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView) {
        hideSearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
    }

    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView) {
        dismissVisibleMenus()
    }
}

extension BrowserViewController: TabToolbarDelegate, PhotonActionSheetProtocol {
    func tabToolbarDidPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goBack()
    }

    func tabToolbarDidLongPressBack(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.reload()
    }

    func tabToolbarDidLongPressReload(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard let tab = tabManager.selectedTab else {
            return
        }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else {
            return
        }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: [urlActions], on: self, from: button, suppressPopover: shouldSuppress)
    }

    func tabToolbarDidPressStop(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.stop()
    }

    func tabToolbarDidPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        tabManager.selectedTab?.goForward()
    }

    func tabToolbarDidLongPressForward(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        showBackForwardList()
    }

    func tabToolbarDidPressMenu(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        // ensure that any keyboards or spinners are dismissed before presenting the menu
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        var actions: [[PhotonActionSheetItem]] = []

        if let syncAction = syncMenuButton(showFxA: presentSignInViewController) {
            actions.append(syncAction)
        }
        actions.append(getHomePanelActions())
        actions.append(getOtherPanelActions(vcDelegate: self))
        // force a modal if the menu is being displayed in compact split screen
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: actions, on: self, from: button, suppressPopover: shouldSuppress)
    }

    func tabToolbarDidPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        showTabTray()
    }

    func tabToolbarDidLongPressTabs(_ tabToolbar: TabToolbarProtocol, button: UIButton) {
        guard self.presentedViewController == nil else {
            return
        }
        let controller = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: Strings.NewTabTitle, style: .default, handler: { _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false)
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.newTab")
        controller.addAction(UIAlertAction(title: Strings.NewPrivateTabTitle, style: .default, handler: { _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: true)
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.newPrivateTab")
        controller.addAction(UIAlertAction(title: Strings.CloseTabTitle, style: .destructive, handler: { _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTab(tab)
            }
        }), accessibilityIdentifier: "toolbarTabButtonLongPress.closeTab")
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label for Cancel button"), style: .cancel, handler: nil), accessibilityIdentifier: "toolbarTabButtonLongPress.cancel")
        controller.popoverPresentationController?.sourceView = toolbar ?? urlBar
        controller.popoverPresentationController?.sourceRect = button.frame
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        present(controller, animated: true, completion: nil)
    }

    func showBackForwardList() {
        if let backForwardList = tabManager.selectedTab?.webView?.backForwardList {
            let backForwardViewController = BackForwardListViewController(profile: profile, backForwardList: backForwardList)
            backForwardViewController.tabManager = tabManager
            backForwardViewController.bvc = self
            backForwardViewController.modalPresentationStyle = .overCurrentContext
            backForwardViewController.backForwardTransitionDelegate = BackForwardListAnimator()
            self.present(backForwardViewController, animated: true, completion: nil)
        }
    }
}

extension BrowserViewController: TabDelegate {

    func tab(_ tab: Tab, didCreateWebView webView: WKWebView) {
        webView.frame = webViewContainer.frame
        // Observers that live as long as the tab. Make sure these are all cleared in willDeleteWebView below!
        KVOs.forEach { webView.addObserver(self, forKeyPath: $0.rawValue, options: .new, context: nil) }
        webView.scrollView.addObserver(self.scrollController, forKeyPath: KVOConstants.contentSize.rawValue, options: .new, context: nil)
        webView.uiDelegate = self

        let formPostHelper = FormPostHelper(tab: tab)
        tab.addContentScript(formPostHelper, name: FormPostHelper.name())

        let readerMode = ReaderMode(tab: tab)
        readerMode.delegate = self
        tab.addContentScript(readerMode, name: ReaderMode.name())

        // only add the logins helper if the tab is not a private browsing tab
        if !tab.isPrivate {
            let logins = LoginsHelper(tab: tab, profile: profile)
            tab.addContentScript(logins, name: LoginsHelper.name())
        }

        let contextMenuHelper = ContextMenuHelper(tab: tab)
        contextMenuHelper.delegate = self
        tab.addContentScript(contextMenuHelper, name: ContextMenuHelper.name())

        let errorHelper = ErrorPageHelper()
        tab.addContentScript(errorHelper, name: ErrorPageHelper.name())

        let sessionRestoreHelper = SessionRestoreHelper(tab: tab)
        sessionRestoreHelper.delegate = self
        tab.addContentScript(sessionRestoreHelper, name: SessionRestoreHelper.name())

        let findInPageHelper = FindInPageHelper(tab: tab)
        findInPageHelper.delegate = self
        tab.addContentScript(findInPageHelper, name: FindInPageHelper.name())

        let noImageModeHelper = NoImageModeHelper(tab: tab)
        tab.addContentScript(noImageModeHelper, name: NoImageModeHelper.name())

        let printHelper = PrintHelper(tab: tab)
        tab.addContentScript(printHelper, name: PrintHelper.name())

        let customSearchHelper = CustomSearchHelper(tab: tab)
        tab.addContentScript(customSearchHelper, name: CustomSearchHelper.name())

        let nightModeHelper = NightModeHelper(tab: tab)
        tab.addContentScript(nightModeHelper, name: NightModeHelper.name())

        // XXX: Bug 1390200 - Disable NSUserActivity/CoreSpotlight temporarily
        // let spotlightHelper = SpotlightHelper(tab: tab)
        // tab.addHelper(spotlightHelper, name: SpotlightHelper.name())

        tab.addContentScript(LocalRequestHelper(), name: LocalRequestHelper.name())

        let historyStateHelper = HistoryStateHelper(tab: tab)
        historyStateHelper.delegate = self
        tab.addContentScript(historyStateHelper, name: HistoryStateHelper.name())

        if #available(iOS 11, *) {
            if let blocker = tab.contentBlocker as? ContentBlockerHelper {
                blocker.setupTabTrackingProtection()
                tab.addContentScript(blocker, name: ContentBlockerHelper.name())
            }
        }

        tab.addContentScript(FocusHelper(tab: tab), name: FocusHelper.name())
    }

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {
        tab.cancelQueuedAlerts()
        KVOs.forEach { webView.removeObserver(self, forKeyPath: $0.rawValue) }
        webView.scrollView.removeObserver(self.scrollController, forKeyPath: KVOConstants.contentSize.rawValue)
        webView.uiDelegate = nil
        webView.scrollView.delegate = nil
        webView.removeFromSuperview()
    }

    fileprivate func findSnackbar(_ barToFind: SnackBar) -> Int? {
        let bars = alertStackView.arrangedSubviews
        for (index, bar) in bars.enumerated() where bar === barToFind {
            return index
        }
        return nil
    }

    func showBar(_ bar: SnackBar, animated: Bool) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.alertStackView.insertArrangedSubview(bar, at: 0)
            self.view.layoutIfNeeded()
        })
    }

    func removeBar(_ bar: SnackBar, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            bar.removeFromSuperview()
        })
    }

    func removeAllBars() {
        alertStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
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

    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String) {
        openSearchNewTab(isPrivate: tab.isPrivate, selection)
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
        let fxaParams = FxALaunchParams(query: ["entrypoint": "homepanel"])
        presentSignInViewController(fxaParams) // TODO UX Right now the flow for sign in and create account is the same
    }

    func homePanelViewControllerDidRequestToSignIn(_ homePanelViewController: HomePanelViewController) {
        let fxaParams = FxALaunchParams(query: ["entrypoint": "homepanel"])
        presentSignInViewController(fxaParams) // TODO UX Right now the flow for sign in and create account is the same
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
        self.show(toast: toast)
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

    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool) {
        self.urlBar.setLocation(text, search: search)
    }
}

extension BrowserViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?) {
        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        if let wv = previous?.webView {
            wv.endEditing(true)
            wv.accessibilityLabel = nil
            wv.accessibilityElementsHidden = true
            wv.accessibilityIdentifier = nil
            wv.removeFromSuperview()
        }

        if let tab = selected, let webView = tab.webView {
            updateURLBarDisplayURL(tab)

            if tab.isPrivate != previous?.isPrivate {
                applyTheme()

                let ui: [PrivateModeUI?] = [toolbar, topTabsViewController, urlBar]
                ui.forEach { $0?.applyUIMode(isPrivate: tab.isPrivate) }
            }

            readerModeCache = tab.isPrivate ? MemoryReaderModeCache.sharedInstance : DiskReaderModeCache.sharedInstance
            if let privateModeButton = topTabsViewController?.privateModeButton, previous != nil && previous?.isPrivate != tab.isPrivate {
                privateModeButton.setSelected(tab.isPrivate, animated: true)
            }
            ReaderModeHandlers.readerModeCache = readerModeCache

            scrollController.tab = selected
            webViewContainer.addSubview(webView)
            webView.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(self.webViewContainer)
            }
            webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
            webView.accessibilityIdentifier = "contentView"
            webView.accessibilityElementsHidden = false

            if webView.url == nil {
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

        updateFindInPageVisibility(visible: false, tab: previous)

        navigationToolbar.updateReloadStatus(selected?.loading ?? false)
        navigationToolbar.updateBackStatus(selected?.canGoBack ?? false)
        navigationToolbar.updateForwardStatus(selected?.canGoForward ?? false)
        if !(selected?.webView?.url?.isLocalUtility ?? false) {
            self.urlBar.updateProgressBar(Float(selected?.estimatedProgress ?? 0))
        }

        if let readerMode = selected?.getContentScript(name: ReaderMode.name()) as? ReaderMode {
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
        if let tab = selected, tab.url == nil, !tab.restoring, NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage {
            self.urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
        }
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
        if let url = tab.url, !url.isAboutURL && !tab.isPrivate {
            profile.recentlyClosedTabs.addTab(url as URL, title: tab.title, faviconURL: tab.displayFavicon?.url)
        }
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab) {
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func show(toast: Toast, afterWaiting delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore, duration: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter) {
        if let downloadToast = toast as? DownloadToast {
            self.downloadToast = downloadToast
        }

        // If BVC isnt visible hold on to this toast until viewDidAppear
        if self.view.window == nil {
            self.pendingToast = toast
            return
        }

        toast.showToast(viewController: self, delay: delay, duration: duration, makeConstraints: { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.webViewContainer)
        })
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        guard let toast = toast, !tabTrayController.privateMode else {
            return
        }
        show(toast: toast, afterWaiting: ButtonToastUX.ToastDelay)
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

/// List of schemes that are allowed to be opened in new tabs.
private let schemesAllowedToBeOpenedAsPopups = ["http", "https", "javascript", "data", "about"]

extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }

        guard navigationAction.isAllowed, shouldRequestBeOpenedAsPopup(navigationAction.request) else {
            print("Denying popup from request: \(navigationAction.request)")
            return nil
        }

        if let currentTab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(currentTab)
        }

        // If the page uses `window.open()` or `[target="_blank"]`, open the page in a new tab.
        // IMPORTANT!!: WebKit will perform the `URLRequest` automatically!! Attempting to do
        // the request here manually leads to incorrect results!!
        let newTab = tabManager.addPopupForParentTab(parentTab, configuration: configuration)

        return newTab.webView
    }

    fileprivate func shouldRequestBeOpenedAsPopup(_ request: URLRequest) -> Bool {
        // Treat `window.open("")` the same as `window.open("about:blank")`.
        if request.url?.absoluteString.isEmpty ?? false {
            return true
        }

        if let scheme = request.url?.scheme?.lowercased(), schemesAllowedToBeOpenedAsPopups.contains(scheme) {
            return true
        }

        return false
    }

    fileprivate func shouldDisplayJSAlertForWebView(_ webView: WKWebView) -> Bool {
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return ((tabManager.selectedTab == nil ? false : tabManager.selectedTab!.webView == webView)) && (self.presentedViewController == nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let messageAlert = MessageAlert(message: message, frame: frame, completionHandler: completionHandler)
        if shouldDisplayJSAlertForWebView(webView) {
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
        if shouldDisplayJSAlertForWebView(webView) {
            present(confirmAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(confirmAlert)
        } else {
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let textInputAlert = TextInputAlert(message: prompt, frame: frame, completionHandler: completionHandler, defaultText: defaultText)
        if shouldDisplayJSAlertForWebView(webView) {
            present(textInputAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(textInputAlert)
        } else {
            completionHandler(nil)
        }
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

    func readerMode(_ readerMode: ReaderMode, didParseReadabilityResult readabilityResult: ReadabilityResult, forTab tab: Tab) {
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
        return .none
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
                if let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode {
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
            readerModeBar.applyTheme()

            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let record = profile.readingList.getRecordWithURL(url).value.successValue {
                readerModeBar.unread = record.unread
                readerModeBar.added = true
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
            scrollController.readerModeBar = self.readerModeBar
        }

        updateReaderModeBar()

        self.updateViewConstraints()
    }

    func hideReaderModeBar(animated: Bool) {
        if let readerModeBar = self.readerModeBar {
            readerModeBar.removeFromSuperview()
            self.readerModeBar = nil
            self.updateViewConstraints()
            scrollController.readerModeBar = self.readerModeBar
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

    @objc func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }

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
            if let readerMode = tabManager.selectedTab?.getContentScript(name: "ReaderMode") as? ReaderMode, readerMode.state == ReaderModeState.active {
                var readerModeStyle = DefaultReaderModeStyle
                if let dict = profile.prefs.dictionaryForKey(ReaderModeProfileKeyStyle) {
                    if let style = ReaderModeStyle(dict: dict as [String: AnyObject]) {
                        readerModeStyle = style
                    }
                }

                let readerModeStyleViewController = ReaderModeStyleViewController()
                readerModeStyleViewController.delegate = self
                readerModeStyleViewController.readerModeStyle = readerModeStyle
                readerModeStyleViewController.modalPresentationStyle = .popover

                let setupPopover = { [unowned self] in
                    if let popoverPresentationController = readerModeStyleViewController.popoverPresentationController {
                        popoverPresentationController.backgroundColor = UIColor.Photon.White100
                        popoverPresentationController.delegate = self
                        popoverPresentationController.sourceView = readerModeBar
                        popoverPresentationController.sourceRect = CGRect(x: readerModeBar.frame.width/2, y: UIConstants.ToolbarHeight, width: 1, height: 1)
                        popoverPresentationController.permittedArrowDirections = .up
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
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let record = profile.readingList.getRecordWithURL(url).value.successValue {
                profile.readingList.updateRecord(record, unread: false) // TODO Check result, can this fail?
                readerModeBar.unread = false
            }

        case .markAsUnread:
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString, let record = profile.readingList.getRecordWithURL(url).value.successValue {
                profile.readingList.updateRecord(record, unread: true) // TODO Check result, can this fail?
                readerModeBar.unread = true
            }

        case .addToReadingList:
            if let tab = tabManager.selectedTab,
               let rawURL = tab.url, rawURL.isReaderModeURL,
               let url = rawURL.decodeReaderModeURL {
                    profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name) // TODO Check result, can this fail?
                    readerModeBar.added = true
                    readerModeBar.unread = true
            }

        case .removeFromReadingList:
            if let url = self.tabManager.selectedTab?.url?.displayURL?.absoluteString,
               let record = profile.readingList.getRecordWithURL(url).value.successValue {
                    profile.readingList.deleteRecord(record) // TODO Check result, can this fail?
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

        if force || profile.prefs.intForKey(PrefsKeys.IntroSeen) == nil {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            // On iPad we present it modally in a controller
            if topTabsVisible {
                introViewController.preferredContentSize = CGSize(width: IntroUX.Width, height: IntroUX.Height)
                introViewController.modalPresentationStyle = .formSheet
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
        self.profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)

        introViewController.dismiss(animated: true) {
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                _ = self.navigationController?.popToRootViewController(animated: true)
            }

            if requestToLogin {
                let fxaParams = FxALaunchParams(query: ["entrypoint": "firstrun"])
                self.presentSignInViewController(fxaParams)
            }
        }
    }

    func presentSignInViewController(_ fxaOptions: FxALaunchParams? = nil) {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let vcToPresent: UIViewController
        if profile.hasAccount(), let status = profile.getAccount()?.actionNeeded, status == .none {
            let settingsTableViewController = SyncContentSettingsViewController()
            settingsTableViewController.profile = profile
            vcToPresent = settingsTableViewController
        } else {
            let signInVC = FxAContentViewController(profile: profile, fxaOptions: fxaOptions)
            signInVC.delegate = self
            vcToPresent = signInVC
        }
        vcToPresent.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSignInViewController))
        let settingsNavigationController = SettingsNavigationController(rootViewController: vcToPresent)
		settingsNavigationController.modalPresentationStyle = .formSheet
        settingsNavigationController.navigationBar.isTranslucent = false
        self.present(settingsNavigationController, animated: true, completion: nil)
    }

    @objc func dismissSignInViewController() {
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

        let actionSheetController = AlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        var dialogTitle: String?

        if let url = elements.link, let currentTab = tabManager.selectedTab {
            dialogTitle = url.absoluteString
            let isPrivate = currentTab.isPrivate

            let addTab = { (rURL: URL, isPrivate: Bool) in
                    let tab = self.tabManager.addTab(URLRequest(url: rURL as URL), afterTab: currentTab, isPrivate: isPrivate)
                    LeanPlumClient.shared.track(event: .openedNewTab, withParameters: ["Source": "Long Press Context Menu"])
                    guard !self.topTabsVisible else {
                        return
                    }
                    // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
                    let toast = ButtonToast(labelText: Strings.ContextMenuButtonToastNewTabOpenedLabelText, buttonText: Strings.ContextMenuButtonToastNewTabOpenedButtonText, completion: { buttonPressed in
                        if buttonPressed {
                            self.tabManager.selectTab(tab)
                        }
                    })
                    self.show(toast: toast)
            }

            if !isPrivate {
                let newTabTitle = NSLocalizedString("Open in New Tab", comment: "Context menu item for opening a link in a new tab")
                let openNewTabAction =  UIAlertAction(title: newTabTitle, style: .default) { _ in
                    addTab(url, false)
                }
                actionSheetController.addAction(openNewTabAction, accessibilityIdentifier: "linkContextMenu.openInNewTab")
            }

            let openNewPrivateTabTitle = NSLocalizedString("Open in New Private Tab", tableName: "PrivateBrowsing", comment: "Context menu option for opening a link in a new private tab")
            let openNewPrivateTabAction =  UIAlertAction(title: openNewPrivateTabTitle, style: .default) { _ in
                addTab(url, true)
            }
            actionSheetController.addAction(openNewPrivateTabAction, accessibilityIdentifier: "linkContextMenu.openInNewPrivateTab")

            let downloadTitle = NSLocalizedString("Download Link", comment: "Context menu item for downloading a link URL")
            let downloadAction = UIAlertAction(title: downloadTitle, style: .default) { _ in
                self.pendingDownloadWebView = currentTab.webView
                currentTab.webView?.evaluateJavaScript("window.__firefox__.download('\(url.absoluteString)', '\(UserScriptManager.securityToken)')")
                UnifiedTelemetry.recordEvent(category: .action, method: .tap, object: .downloadLinkButton)
            }
            actionSheetController.addAction(downloadAction, accessibilityIdentifier: "linkContextMenu.download")

            let copyTitle = NSLocalizedString("Copy Link", comment: "Context menu item for copying a link URL to the clipboard")
            let copyAction = UIAlertAction(title: copyTitle, style: .default) { _ in
                UIPasteboard.general.url = url as URL
            }
            actionSheetController.addAction(copyAction, accessibilityIdentifier: "linkContextMenu.copyLink")

            let shareTitle = NSLocalizedString("Share Link", comment: "Context menu item for sharing a link URL")
            let shareAction = UIAlertAction(title: shareTitle, style: .default) { _ in
                self.presentActivityViewController(url as URL, sourceView: self.view, sourceRect: CGRect(origin: touchPoint, size: touchSize), arrowDirection: .any)
            }
            actionSheetController.addAction(shareAction, accessibilityIdentifier: "linkContextMenu.share")
        }

        if let url = elements.image {
            if dialogTitle == nil {
                dialogTitle = url.absoluteString
            }

            let photoAuthorizeStatus = PHPhotoLibrary.authorizationStatus()
            let saveImageTitle = NSLocalizedString("Save Image", comment: "Context menu item for saving an image")
            let saveImageAction = UIAlertAction(title: saveImageTitle, style: .default) { _ in
                if photoAuthorizeStatus == .authorized || photoAuthorizeStatus == .notDetermined {
                    self.getImage(url as URL) {
                        UIImageWriteToSavedPhotosAlbum($0, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                } else {
                    let accessDenied = UIAlertController(title: NSLocalizedString("Firefox would like to access your Photos", comment: "See http://mzl.la/1G7uHo7"), message: NSLocalizedString("This allows you to save the image to your Camera Roll.", comment: "See http://mzl.la/1G7uHo7"), preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: Strings.CancelString, style: .default, handler: nil)
                    accessDenied.addAction(dismissAction)
                    let settingsAction = UIAlertAction(title: NSLocalizedString("Open Settings", comment: "See http://mzl.la/1G7uHo7"), style: .default ) { _ in
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:])
                    }
                    accessDenied.addAction(settingsAction)
                    self.present(accessDenied, animated: true, completion: nil)
                }
            }
            actionSheetController.addAction(saveImageAction, accessibilityIdentifier: "linkContextMenu.saveImage")

            let copyImageTitle = NSLocalizedString("Copy Image", comment: "Context menu item for copying an image to the clipboard")
            let copyAction = UIAlertAction(title: copyImageTitle, style: .default) { _ in
                // put the actual image on the clipboard
                // do this asynchronously just in case we're in a low bandwidth situation
                let pasteboard = UIPasteboard.general
                pasteboard.url = url as URL
                let changeCount = pasteboard.changeCount
                let application = UIApplication.shared
                var taskId: UIBackgroundTaskIdentifier = 0
                taskId = application.beginBackgroundTask (expirationHandler: {
                    application.endBackgroundTask(taskId)
                })

                Alamofire.request(url).validate(statusCode: 200..<300).response { response in
                    // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                    // fetching the image; otherwise, in low-bandwidth situations,
                    // we might be overwriting something that the user has subsequently added.
                    if changeCount == pasteboard.changeCount, let imageData = response.data, response.error == nil {
                        pasteboard.addImageWithData(imageData, forURL: url)
                    }

                    application.endBackgroundTask(taskId)
                }
            }
            actionSheetController.addAction(copyAction, accessibilityIdentifier: "linkContextMenu.copyImage")
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
        let cancelAction = UIAlertAction(title: Strings.CancelString, style: UIAlertActionStyle.cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        self.present(actionSheetController, animated: true, completion: nil)
    }

    fileprivate func getImage(_ url: URL, success: @escaping (UIImage) -> Void) {
        Alamofire.request(url).validate(statusCode: 200..<300).response { response in
            if let data = response.data, let image = data.isGIF ? UIImage.imageFromGIFDataThreadSafe(data) : UIImage.imageFromDataThreadSafe(data) {
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
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error == nil {
            LeanPlumClient.shared.track(event: .saveImage)
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
            self.customSearchEngineButton.tintColor = UIColor.Photon.Grey50
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
        _ = Try(withTry: {
            inputAssistant.trailingBarButtonGroups.last?.barButtonItems.append(item)
        }) { (exception) in
            Sentry.shared.send(message: "Failed adding custom search button to input assistant", tag: .general, severity: .error, description: "\(exception ??? "nil")")
        }
    }

    @objc func addCustomSearchEngineForFocusedElement() {
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
            self.customSearchEngineButton.tintColor = UIColor.Photon.Grey50
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
            self.customSearchEngineButton.tintColor = UIColor.Photon.Grey50
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
            self.alertStackView.layoutIfNeeded()
        }

        guard let webView = tabManager.selectedTab?.webView else {
            return
        }
        webView.evaluateJavaScript("__firefox__.searchQueryForField()") { (result, _) in
            guard let _ = result as? String else {
                return
            }
            self.addCustomSearchButtonToWebView(webView)
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
            self.alertStackView.layoutIfNeeded()
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

    func tabTrayDidAddTab(_ tabTray: TabTrayController, tab: Tab) {}

    func tabTrayDidAddBookmark(_ tab: Tab) {
        guard let url = tab.url?.absoluteString, !url.isEmpty else { return }
        self.addBookmark(tab.tabState)
    }

    func tabTrayDidAddToReadingList(_ tab: Tab) -> ReadingListItem? {
        guard let url = tab.url?.absoluteString, !url.isEmpty else { return nil }
        return profile.readingList.createRecordWithURL(url, title: tab.title ?? url, addedBy: UIDevice.current.name).value.successValue
    }

    func tabTrayRequestsPresentationOf(_ viewController: UIViewController) {
        self.present(viewController, animated: false, completion: nil)
    }
}

// MARK: Browser Chrome Theming
extension BrowserViewController: Themeable {
    func applyTheme() {
        let ui: [Themeable?] = [urlBar, toolbar, readerModeBar, topTabsViewController]
        ui.forEach { $0?.applyTheme() }
        statusBarOverlay.backgroundColor = shouldShowTopTabsForTraitCollection(traitCollection) ? UIColor.Photon.Grey80 : urlBar.backgroundColor
        setNeedsStatusBarAppearanceUpdate()

        homePanelController?.applyTheme()
    }
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
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
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
        guard let _ = tabManager.selectedTab else {
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
        guard let tab = tabManager.selectedTab, let url = tab.canonicalURL?.displayURL?.absoluteString else { return }
        let shareItem = ShareItem(url: url, title: tab.title, favicon: tab.displayFavicon)
        guard shareItem.isShareable else {
            let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.popToBVC()})
            present(alert, animated: true, completion: nil)
            return
        }
        profile.sendItems([shareItem], toClients: clients).uponQueue(.main) { _ in
            self.popToBVC()
        }
    }
}

