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
import Account
import MobileCoreServices
import SDWebImage
import SwiftyJSON
import Telemetry
import MozillaAppServices
import Sentry

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

struct UrlToOpenModel {
    var url: URL?
    var isPrivate: Bool
}

/// Enum used to track flow for telemetry events
enum ReferringPage {
    case onboarding
    case appMenu
    case settings
    case none
}

class BrowserViewController: UIViewController {
    var firefoxHomeViewController: FirefoxHomeViewController?
    var libraryViewController: LibraryViewController?
    var libraryDrawerViewController: DrawerViewController?
    var webViewContainer: UIView!
    var urlBar: URLBarView!
    var urlBarHeightConstraint: Constraint!
    var clipboardBarDisplayHandler: ClipboardBarDisplayHandler?
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    var statusBarOverlay: UIView = UIView()
    fileprivate(set) var toolbar: TabToolbar?
    var searchController: SearchViewController?
    var screenshotHelper: ScreenshotHelper!
    fileprivate var homePanelIsInline = false
    var searchTelemetry: SearchTelemetry?
    var searchLoader: SearchLoader?
    let alertStackView = UIStackView() // All content that appears above the footer should be added to this view. (Find In Page/SnackBars)
    var findInPageBar: FindInPageBar?
    private var newTabUserResearch: NewTabUserResearch?
    var chronTabsUserResearch: ChronTabsUserResearch?
    lazy var mailtoLinkHandler = MailtoLinkHandler()
    var urlFromAnotherApp: UrlToOpenModel?
    var isCrashAlertShowing: Bool = false
    var currentMiddleButtonState: MiddleButtonState?
    fileprivate var customSearchBarButton: UIBarButtonItem?

    // popover rotation handling
    var displayedPopoverController: UIViewController?
    var updateDisplayedPopoverProperties: (() -> Void)?

    var openInHelper: OpenInHelper?

    // location label actions
    var pasteGoAction: AccessibleAction!
    var pasteAction: AccessibleAction!
    var copyAddressAction: AccessibleAction!

    weak var tabTrayController: TabTrayControllerV1?
    weak var tabTrayControllerV2: TabTrayV2ViewController?
    weak var tabTrayControllerV3: TabTrayV3ViewController?
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
    var hasTriedToPresentETPAlready = false
    var hasTriedToPresentDBCardAlready = false
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
    var isCmdClickForNewTab = false


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

    override var prefersStatusBarHidden: Bool {
        return false
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
        guard urlBar != nil else {
            return ThemeManager.instance.statusBarStyle
        }
        
        // top-tabs are always dark, so special-case this to light
        if urlBar.topTabsIsShowing {
            return .lightContent
        } else {
            return ThemeManager.instance.statusBarStyle
        }
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

    fileprivate func constraintsForLibraryDrawerView(_ make: SnapKit.ConstraintMaker) {
        guard libraryDrawerViewController?.view.superview != nil else { return }
        if self.topTabsVisible {
            make.top.equalTo(webViewContainer)
        } else {
            make.top.equalTo(view)
        }

        make.right.bottom.left.equalToSuperview()
    }

    @objc fileprivate func appMenuBadgeUpdate() {
        let hideImagesOn = NoImageModeHelper.isActivated(profile.prefs)
        let showWhatsNew = shouldShowWhatsNew() && !(AppInfo.whatsNewTopic?.isEmpty ?? true)
        let actionNeeded = RustFirefoxAccounts.shared.isActionNeeded
        let showWarningBadge = actionNeeded 
        let showMenuBadge = showWarningBadge ? false : hideImagesOn || showWhatsNew

        urlBar.warningMenuBadge(setVisible: showWarningBadge)
        urlBar.appMenuBadge(setVisible: showMenuBadge)
        toolbar?.warningMenuBadge(setVisible: showWarningBadge)
        toolbar?.appMenuBadge(setVisible: showMenuBadge)
    }

    func updateToolbarStateForTraitCollection(_ newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator? = nil) {
        let showToolbar = shouldShowFooterForTraitCollection(newCollection)
        let showTopTabs = shouldShowTopTabsForTraitCollection(newCollection)
        let shouldShowNewTabButton = false
        
        urlBar.topTabsIsShowing = showTopTabs
        urlBar.setShowToolbar(!showToolbar)
        toolbar?.addNewTabButton.isHidden = showToolbar
        toolbar?.removeFromSuperview()
        toolbar?.tabToolbarDelegate = nil
        toolbar = nil

        if showToolbar {
            toolbar = TabToolbar()
            footer.addSubview(toolbar!)
            toolbar?.tabToolbarDelegate = self
            toolbar?.applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            toolbar?.applyTheme()
            toolbar?.addNewTabButton.isHidden = true
            // This is for showing (+) add tab middle button with A/B test where we need to update both toolbar and url bar when (+) button is enabled.
            // Urlbar already has reader mode state but we still need to refresh it so that if reader mode is available we don't accidently show reload or stop button in url bar
            if shouldShowNewTabButton {
                toolbar?.updateMiddleButtonState(.newTab)
                let state = urlBar.locationView.readerModeState
                urlBar.updateReaderModeState(state)
            } else {
                toolbar?.updateMiddleButtonState(currentMiddleButtonState ?? .search)
            }
            updateTabCountUsingTabManager(self.tabManager)
        }

        appMenuBadgeUpdate()

        if showTopTabs {
            if topTabsViewController == nil {
                let topTabsViewController = TopTabsViewController(tabManager: tabManager)
                topTabsViewController.delegate = self
                addChild(topTabsViewController)
                topTabsViewController.view.frame = topTabsContainer.frame
                topTabsContainer.addSubview(topTabsViewController.view)
                topTabsViewController.view.snp.makeConstraints { make in
                    make.edges.equalTo(topTabsContainer)
                    make.height.equalTo(TopTabsUX.TopTabsViewHeight)
                }
                self.topTabsViewController = topTabsViewController
                topTabsViewController.applyTheme()
            }
            topTabsContainer.snp.updateConstraints { make in
                make.height.equalTo(TopTabsUX.TopTabsViewHeight)
            }
        } else {
            topTabsContainer.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            topTabsViewController?.view.removeFromSuperview()
            topTabsViewController?.removeFromParent()
            topTabsViewController = nil
        }

        view.setNeedsUpdateConstraints()
        firefoxHomeViewController?.view.setNeedsUpdateConstraints()

        if let tab = tabManager.selectedTab,
               let webView = tab.webView {
            updateURLBarDisplayURL(tab)
            navigationToolbar.updateBackStatus(webView.canGoBack)
            navigationToolbar.updateForwardStatus(webView.canGoForward)
        }

        libraryDrawerViewController?.view.snp.remakeConstraints(constraintsForLibraryDrawerView)
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
            self.updateDisplayedPopoverProperties = nil
            self.displayedPopoverController = nil
        }
    }

    @objc func tappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

   @objc  func appWillResignActiveNotification() {
        // Dismiss any popovers that might be visible
        displayedPopoverController?.dismiss(animated: false) {
            self.updateDisplayedPopoverProperties = nil
            self.displayedPopoverController = nil
        }

        // If we are displying a private tab, hide any elements in the tab that we wouldn't want shown
        // when the app is in the home switcher
        guard let privateTab = tabManager.selectedTab, privateTab.isPrivate else {
            return
        }

        view.bringSubviewToFront(webViewContainerBackdrop)
        webViewContainerBackdrop.alpha = 1
        webViewContainer.alpha = 0
        urlBar.locationContainer.alpha = 0
        firefoxHomeViewController?.view.alpha = 0
        topTabsViewController?.switchForegroundStatus(isInForeground: false)
        presentedViewController?.popoverPresentationController?.containerView?.alpha = 0
        presentedViewController?.view.alpha = 0
    }

    @objc func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.webViewContainer.alpha = 1
            self.urlBar.locationContainer.alpha = 1
            self.firefoxHomeViewController?.view.alpha = 1
            self.topTabsViewController?.switchForegroundStatus(isInForeground: true)
            self.presentedViewController?.popoverPresentationController?.containerView?.alpha = 1
            self.presentedViewController?.view.alpha = 1
            self.view.backgroundColor = UIColor.clear
        }, completion: { _ in
            self.webViewContainerBackdrop.alpha = 0
            self.view.sendSubviewToBack(self.webViewContainerBackdrop)
        })

        // Re-show toolbar which might have been hidden during scrolling (prior to app moving into the background)
        scrollController.showToolbars(animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActiveNotification), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        KeyboardHelper.defaultHelper.addDelegate(self)

        webViewContainerBackdrop = UIView()
        webViewContainerBackdrop.backgroundColor = UIColor.Photon.Ink90
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
        urlBar = URLBarView(profile: profile)
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
            if let url = self.tabManager.selectedTab?.canonicalURL?.displayURL ?? self.urlBar.currentURL {
                UIPasteboard.general.url = url
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
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        if !NightModeHelper.isActivated(profile.prefs) {
            if #available(iOS 13.0, *) {
                if ThemeManager.instance.systemThemeIsOn {
                    let userInterfaceStyle = traitCollection.userInterfaceStyle
                    ThemeManager.instance.current = userInterfaceStyle == .dark ? DarkTheme() : NormalTheme()
                }
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.appMenuBadgeUpdate), name: .FirefoxAccountStateChange, object: nil)
        
        // Setup New Tab user research for A/B testing
        newTabUserResearch = NewTabUserResearch()
        newTabUserResearch?.lpVariableObserver()
        urlBar.newTabUserResearch = newTabUserResearch
        // Setup chron tabs A/B test
        chronTabsUserResearch = ChronTabsUserResearch()
        chronTabsUserResearch?.lpVariableObserver()
        searchTelemetry = SearchTelemetry()
    }

    fileprivate func setupConstraints() {
        topTabsContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self.header)
            make.top.equalTo(urlBarTopTabsContainer)
        }

        urlBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(urlBarTopTabsContainer)
            self.urlBarHeightConstraint = make.height.equalTo(UIConstants.TopToolbarHeightMax).constraint
            make.top.equalTo(topTabsContainer.snp.bottom)
        }

        header.snp.makeConstraints { make in
            scrollController.headerTopConstraint = make.top.equalTo(self.view.safeArea.top).constraint
            make.left.right.equalTo(self.view)
        }

        webViewContainerBackdrop.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        statusBarOverlay.snp.remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(self.view.safeAreaInsets.top)
        }

        adjustURLBarHeightBasedOnLocationViewHeight()
    }

    fileprivate func adjustURLBarHeightBasedOnLocationViewHeight() {
        // Make sure that we have a height to actually base our calculations on
        guard urlBar.locationContainer.bounds.height != 0 else { return }
        let locationViewHeight = urlBar.locationView.bounds.height
        let heightWithPadding = locationViewHeight + 10

        // We have to deactivate the original constraint, and remake the constraint
        // or else funky conflicts happen
        urlBarHeightConstraint.deactivate()
        urlBar.snp.makeConstraints { make in
            let height =  heightWithPadding > UIConstants.TopToolbarHeightMax ? UIConstants.TopToolbarHeight : heightWithPadding
            self.urlBarHeightConstraint = make.height.equalTo(height).constraint
        }
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
                    self.tabManager.addTabsForURLs(receivedURLs, zombie: false)
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
        guard tabManager.hasTabsToRestoreAtStartup() else {
            tabManager.selectTab(tabManager.addTab())
            return
        }
        let alert = UIAlertController.restoreTabsAlert(
            okayCallback: { _ in
                self.isCrashAlertShowing = false
                self.tabManager.restoreTabs(true)
            },
            noCallback: { _ in
                self.isCrashAlertShowing = false
                self.tabManager.selectTab(self.tabManager.addTab())
                self.openUrlAfterRestore()
            }
        )
        self.present(alert, animated: true, completion: nil)
        isCrashAlertShowing = true
    }

    override func viewDidAppear(_ animated: Bool) {
        presentIntroViewController()
        presentDBOnboardingViewController()
        presentUpdateViewController()
        screenshotHelper.viewIsVisible = true
        screenshotHelper.takePendingScreenshots(tabManager.tabs)

        super.viewDidAppear(animated)

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

    func shouldShowWhatsNew() -> Bool {
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
        firefoxHomeViewController?.view.snp.remakeConstraints { make in
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
            make.width.equalTo(self.view.safeArea.width)
            if let keyboardHeight = keyboardState?.intersectionHeightForView(self.view), keyboardHeight > 0 {
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            } else if let toolbar = self.toolbar {
                make.bottom.lessThanOrEqualTo(toolbar.snp.top)
                make.bottom.lessThanOrEqualTo(self.view.safeArea.bottom)
            } else {
                make.bottom.equalTo(self.view.safeArea.bottom)
            }
        }
    }

    func showFirefoxHome(inline: Bool) {
        homePanelIsInline = inline
        if self.firefoxHomeViewController == nil {
            let firefoxHomeViewController = FirefoxHomeViewController(profile: profile)
            firefoxHomeViewController.homePanelDelegate = self
            self.firefoxHomeViewController = firefoxHomeViewController
            addChild(firefoxHomeViewController)
            view.addSubview(firefoxHomeViewController.view)
            firefoxHomeViewController.didMove(toParent: self)
        }

        firefoxHomeViewController?.applyTheme()

        // We have to run this animation, even if the view is already showing
        // because there may be a hide animation running and we want to be sure
        // to override its results.
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.firefoxHomeViewController?.view.alpha = 1
        }, completion: { finished in
            if finished {
                self.webViewContainer.accessibilityElementsHidden = true
                UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
            }
        })
        view.setNeedsUpdateConstraints()
        urlBar.locationView.reloadButton.reloadButtonState = .disabled
    }

    fileprivate func hideFirefoxHome() {
        guard let firefoxHomeViewController = self.firefoxHomeViewController else {
            return
        }

        self.firefoxHomeViewController = nil
        UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { () -> Void in
            firefoxHomeViewController.view.alpha = 0
        }, completion: { _ in
            firefoxHomeViewController.willMove(toParent: nil)
            firefoxHomeViewController.view.removeFromSuperview()
            firefoxHomeViewController.removeFromParent()
            self.webViewContainer.accessibilityElementsHidden = false
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)

            // Refresh the reading view toolbar since the article record may have changed
            if let readerMode = self.tabManager.selectedTab?.getContentScript(name: ReaderMode.name()) as? ReaderMode, readerMode.state == .active {
                self.showReaderModeBar(animated: false)
            }
        })
    }

    func updateInContentHomePanel(_ url: URL?) {
        let isAboutHomeURL = url.flatMap { InternalURL($0)?.isAboutHomeURL } ?? false
        if !urlBar.inOverlayMode {
            guard let url = url else {
                hideFirefoxHome()
                urlBar.locationView.reloadButton.reloadButtonState = .disabled
                return
            }
            if isAboutHomeURL {
                showFirefoxHome(inline: true)
            } else if !url.absoluteString.hasPrefix("\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)") {
                hideFirefoxHome()
                urlBar.locationView.reloadButton.reloadButtonState = .disabled
            }
        } else if isAboutHomeURL {
            showFirefoxHome(inline: false)
        }
    }

    func showLibrary(panel: LibraryPanelType? = nil) {
        if let presentedViewController = self.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
        }

        let libraryViewController = self.libraryViewController ?? LibraryViewController(profile: profile)
        libraryViewController.delegate = self
        self.libraryViewController = libraryViewController

        if panel != nil {
            libraryViewController.selectedPanel = panel
        }

        let libraryDrawerViewController = self.libraryDrawerViewController ?? DrawerViewController(childViewController: libraryViewController)
        self.libraryDrawerViewController = libraryDrawerViewController

        addChild(libraryDrawerViewController)
        view.addSubview(libraryDrawerViewController.view)
        libraryDrawerViewController.view.snp.remakeConstraints(constraintsForLibraryDrawerView)
    }

    fileprivate func createSearchControllerIfNeeded() {
        guard self.searchController == nil else {
            return
        }

        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        let searchController = SearchViewController(profile: profile, isPrivate: isPrivate)
        searchController.searchEngines = profile.searchEngines
        searchController.searchDelegate = self

        let searchLoader = SearchLoader(profile: profile, urlBar: urlBar)
        searchLoader.addListener(searchController)

        self.searchController = searchController
        self.searchLoader = searchLoader
    }

    func showSearchController() {
        createSearchControllerIfNeeded()

        guard let searchController = self.searchController else {
            return
        }

        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.view.snp.makeConstraints { make in
            make.top.equalTo(self.urlBar.snp.bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        firefoxHomeViewController?.view?.isHidden = true

        searchController.didMove(toParent: self)
    }

    func hideSearchController() {
        if let searchController = self.searchController {
            searchController.willMove(toParent: nil)
            searchController.view.removeFromSuperview()
            searchController.removeFromParent()
            firefoxHomeViewController?.view?.isHidden = false
        }
    }

    func destroySearchController() {
        hideSearchController()

        searchController = nil
        searchLoader = nil
    }

    func finishEditingAndSubmit(_ url: URL, visitType: VisitType, forTab tab: Tab) {
        urlBar.currentURL = url
        urlBar.leaveOverlayMode()

        if let nav = tab.loadRequest(URLRequest(url: url)) {
            self.recordNavigationInTab(tab, navigation: nav, visitType: visitType)
        }
    }

    func addBookmark(url: String, title: String? = nil, favicon: Favicon? = nil) {
        var title = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.count == 0 {
            title = url
        }

        let shareItem = ShareItem(url: url, title: title, favicon: favicon)
        profile.places.createBookmark(parentGUID: "mobile______", url: shareItem.url, title: shareItem.title)

        var userData = [QuickActions.TabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActions.TabTitleKey] = title
        }
        QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark, withUserData: userData, toApplication: .shared)
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
    
    func setupMiddleButtonStatus(isLoading: Bool) {
        let shouldShowNewTabButton = false
        
        // No tab
        guard let tab = tabManager.selectedTab else {
            navigationToolbar.updateMiddleButtonState(.search)
            currentMiddleButtonState = .search
            return
        }
        
        // Tab with starting page
        if tab.isURLStartingPage {
            navigationToolbar.updateMiddleButtonState(.search)
            currentMiddleButtonState = .search
            return
        }
        
        let state: MiddleButtonState = shouldShowNewTabButton ? .newTab : (isLoading ? .stop : .reload)
        navigationToolbar.updateMiddleButtonState(state)
        currentMiddleButtonState = state
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let webView = object as? WKWebView, let tab = tabManager[webView] else {
            assert(false)
            return
        }
        guard let kp = keyPath, let path = KVOConstants(rawValue: kp) else {
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
            return
        }

        if let helper = tab.getContentScript(name: ContextMenuHelper.name()) as? ContextMenuHelper {
            // This is zero-cost if already installed. It needs to be checked frequently (hence every event here triggers this function), as when a new tab is created it requires multiple attempts to setup the handler correctly.
             helper.replaceGestureHandlerIfNeeded()
        }

        switch path {
        case .estimatedProgress:
            guard tab === tabManager.selectedTab else { break }
            if let url = webView.url, !InternalURL.isValid(url: url) {
                urlBar.updateProgressBar(Float(webView.estimatedProgress))
                setupMiddleButtonStatus(isLoading: true)
            } else {
                urlBar.hideProgressBar()
                setupMiddleButtonStatus(isLoading: false)
            }
        case .loading:
            guard let loading = change?[.newKey] as? Bool else { break }
            setupMiddleButtonStatus(isLoading: loading)
        case .URL:
            // Special case for "about:blank" popups, if the webView.url is nil, keep the tab url as "about:blank"
            if tab.url?.absoluteString == "about:blank" && webView.url == nil {
                print(webView.url?.origin)
                break
            }

            // To prevent spoofing, only change the URL immediately if the new URL is on
            // the same origin as the current URL. Otherwise, do nothing and wait for
            // didCommitNavigation to confirm the page load.
            if tab.url?.origin == webView.url?.origin {
                tab.url = webView.url

                if tab === tabManager.selectedTab && !tab.restoring {
                    updateUIForReaderHomeStateForTab(tab)
                }
                // Catch history pushState navigation, but ONLY for same origin navigation,
                // for reasons above about URL spoofing risk.
                navigateInTab(tab: tab, webViewStatus: .url)
            }
        case .title:
            // Ensure that the tab title *actually* changed to prevent repeated calls
            // to navigateInTab(tab:).
            guard let title = tab.title else { break }
            if !title.isEmpty && title != tab.lastTitle {
                tab.lastTitle = title
                navigateInTab(tab: tab, webViewStatus: .title)
            }
        case .canGoBack:
            guard tab === tabManager.selectedTab, let canGoBack = change?[.newKey] as? Bool else {
                break
            }
            navigationToolbar.updateBackStatus(canGoBack)
        case .canGoForward:
            guard tab === tabManager.selectedTab, let canGoForward = change?[.newKey] as? Bool else {
                break
            }
            navigationToolbar.updateForwardStatus(canGoForward)
        default:
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
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
        urlBar.locationView.showLockIcon(forSecureContent: tab.webView?.hasOnlySecureContent ?? false)
        let isPage = tab.url?.displayURL?.isWebPage() ?? false
        navigationToolbar.updatePageStatus(isPage)
    }

    // MARK: Opening New Tabs
    func switchToPrivacyMode(isPrivate: Bool) {
         if let tabTrayController = self.tabTrayController, tabTrayController.tabDisplayManager.isPrivate != isPrivate {
            tabTrayController.changePrivacyMode(isPrivate)
        }
        topTabsViewController?.applyUIMode(isPrivate: isPrivate)
    }

    func switchToTabForURLOrOpen(_ url: URL, isPrivate: Bool = false) {
        guard !isCrashAlertShowing else {
            urlFromAnotherApp = UrlToOpenModel(url: url, isPrivate: isPrivate)
            return
        }
        popToBVC()
        if let tab = tabManager.getTabForURL(url) {
            tabManager.selectTab(tab)
        } else {
            openURLInNewTab(url, isPrivate: isPrivate)
        }
    }
    
    func switchToTabForWidgetURLOrOpen(_ url: URL, uuid: String,  isPrivate: Bool = false) {
        guard !isCrashAlertShowing else {
            urlFromAnotherApp = UrlToOpenModel(url: url, isPrivate: isPrivate)
            return
        }
        popToBVC()
        if let tab = tabManager.getTabForUUID(uuid: uuid) {
            tabManager.selectTab(tab)
        } else {
            openURLInNewTab(url, isPrivate: isPrivate)
        }
    }

    func openURLInNewTab(_ url: URL?, isPrivate: Bool = false) {
        if let selectedTab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(selectedTab)
        }
        let request: URLRequest?
        if let url = url {
            request = URLRequest(url: url)
        } else {
            request = nil
        }

        switchToPrivacyMode(isPrivate: isPrivate)
        tabManager.selectTab(tabManager.addTab(request, isPrivate: isPrivate))
    }

    func focusLocationTextField(forTab tab: Tab?, setSearchText searchText: String? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            // Without a delay, the text field fails to become first responder
            // Check that the newly created tab is still selected.
            // This let's the user spam the Cmd+T button without lots of responder changes.
            guard tab == self.tabManager.selectedTab else { return }
            self.urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
            if let text = searchText {
                self.urlBar.setLocation(text, search: true)
            }
        }
    }

    func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool = false, searchFor searchText: String? = nil) {
        popToBVC()
        openURLInNewTab(nil, isPrivate: isPrivate)
        let freshTab = tabManager.selectedTab
        if focusLocationField {
            focusLocationTextField(forTab: freshTab, setSearchText: searchText)
        }
    }

    func openSearchNewTab(isPrivate: Bool = false, _ text: String) {
        popToBVC()
        let engine = profile.searchEngines.defaultEngine
        if let searchURL = engine.searchURLForQuery(text) {
            openURLInNewTab(searchURL, isPrivate: isPrivate)
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

    func presentActivityViewController(_ url: URL, tab: Tab? = nil, sourceView: UIView?, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection) {
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

    @objc fileprivate func openSettings() {
        assert(Thread.isMainThread, "Opening settings requires being invoked on the main thread")

        let settingsTableViewController = AppSettingsTableViewController()
        settingsTableViewController.profile = profile
        settingsTableViewController.tabManager = tabManager
        settingsTableViewController.settingsDelegate = self

        let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
        controller.presentingModalViewControllerDelegate = self
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

    /// Enum to represent the WebView observation or delegate that triggered calling `navigateInTab`
    enum WebViewUpdateStatus {
        case title
        case url
        case finishedNavigation
    }
    
    func navigateInTab(tab: Tab, to navigation: WKNavigation? = nil, webViewStatus: WebViewUpdateStatus) {
        tabManager.expireSnackbars()

        guard let webView = tab.webView else {
            print("Cannot navigate in tab without a webView")
            return
        }

        if let url = webView.url {
            if tab === tabManager.selectedTab {
                urlBar.locationView.showLockIcon(forSecureContent: webView.hasOnlySecureContent)
            }

            if (!InternalURL.isValid(url: url) || url.isReaderModeURL), !url.isFileURL {
                postLocationChangeNotificationForTab(tab, navigation: navigation)

                webView.evaluateJavascriptInDefaultContentWorld("\(ReaderModeNamespace).checkReadability()")
            }

            TabEvent.post(.didChangeURL(url), for: tab)
        }
        
        // Represents WebView observation or delegate update that called this function
        switch webViewStatus {
        case .title, .url, .finishedNavigation:
            if tab !== tabManager.selectedTab, let webView = tab.webView {
                // To Screenshot a tab that is hidden we must add the webView,
                // then wait enough time for the webview to render.
                view.insertSubview(webView, at: 0)
                // This is kind of a hacky fix for Bug 1476637 to prevent webpages from focusing the
                // touch-screen keyboard from the background even though they shouldn't be able to.
                webView.resignFirstResponder()
                
                // We need a better way of identifying when webviews are finished rendering
                // There are cases in which the page will still show a loading animation or nothing when the screenshot is being taken,
                // depending on internet connection
                // Issue created: https://github.com/mozilla-mobile/firefox-ios/issues/7003
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    self.screenshotHelper.takeScreenshot(tab)
                    if webView.superview == self.view {
                        webView.removeFromSuperview()
                    }
                }
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection), ThemeManager.instance.systemThemeIsOn {
                let userInterfaceStyle = traitCollection.userInterfaceStyle
                ThemeManager.instance.current = userInterfaceStyle == .dark ? DarkTheme() : NormalTheme()
            }
        }
    }
}

extension BrowserViewController: ClipboardBarDisplayHandlerDelegate {
    func shouldDisplay(clipboardBar bar: ButtonToast) {
        show(toast: bar, duration: ClipboardBarToastUX.ToastDelay)
    }
}

extension BrowserViewController: QRCodeViewControllerDelegate {
    func didScanQRCodeWithURL(_ url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
        TelemetryWrapper.recordEvent(category: .action, method: .scan, object: .qrCodeURL)
    }

    func didScanQRCodeWithText(_ text: String) {
        TelemetryWrapper.recordEvent(category: .action, method: .scan, object: .qrCodeText)
        let content = TextContentDetector.detectTextContent(text)
        switch content {
        case .some(.link(let url)):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .some(.phoneNumber(let phoneNumber)):
            let url = URL(string: "tel:\(phoneNumber)")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        default:
            guard let tab = tabManager.selectedTab else { return }
            submitSearchText(text, forTab: tab)
        }
    }
}

extension BrowserViewController: SettingsDelegate {
    func settingsOpenURLInNewTab(_ url: URL) {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        self.openURLInNewTab(url, isPrivate: isPrivate)
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

        let errorHelper = ErrorPageHelper(certStore: profile.certStore)
        tab.addContentScript(errorHelper, name: ErrorPageHelper.name())

        let sessionRestoreHelper = SessionRestoreHelper(tab: tab)
        sessionRestoreHelper.delegate = self
        tab.addContentScript(sessionRestoreHelper, name: SessionRestoreHelper.name())

        let findInPageHelper = FindInPageHelper(tab: tab)
        findInPageHelper.delegate = self
        tab.addContentScript(findInPageHelper, name: FindInPageHelper.name())

        let noImageModeHelper = NoImageModeHelper(tab: tab)
        tab.addContentScript(noImageModeHelper, name: NoImageModeHelper.name())

        let downloadContentScript = DownloadContentScript(tab: tab)
        tab.addContentScript(downloadContentScript, name: DownloadContentScript.name())

        let printHelper = PrintHelper(tab: tab)
        tab.addContentScript(printHelper, name: PrintHelper.name())

        let nightModeHelper = NightModeHelper(tab: tab)
        tab.addContentScript(nightModeHelper, name: NightModeHelper.name())

        // XXX: Bug 1390200 - Disable NSUserActivity/CoreSpotlight temporarily
        // let spotlightHelper = SpotlightHelper(tab: tab)
        // tab.addHelper(spotlightHelper, name: SpotlightHelper.name())

        tab.addContentScript(LocalRequestHelper(), name: LocalRequestHelper.name())

        let blocker = FirefoxTabContentBlocker(tab: tab, prefs: profile.prefs)
        tab.contentBlocker = blocker
        tab.addContentScript(blocker, name: FirefoxTabContentBlocker.name())

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
        // If the Tab that had a SnackBar added to it is not currently
        // the selected Tab, do nothing right now. If/when the Tab gets
        // selected later, we will show the SnackBar at that time.
        guard tab == tabManager.selectedTab else {
            return
        }

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

extension BrowserViewController: LibraryPanelDelegate {
    func libraryPanelDidRequestToSignIn() {
        let fxaParams = FxALaunchParams(query: ["entrypoint": "homepanel"])
        presentSignInViewController(fxaParams) // TODO UX Right now the flow for sign in and create account is the same
    }

    func libraryPanelDidRequestToCreateAccount() {
        let fxaParams = FxALaunchParams(query: ["entrypoint": "homepanel"])
        presentSignInViewController(fxaParams) // TODO UX Right now the flow for sign in and create account is the same
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
        libraryDrawerViewController?.close()
    }

    func libraryPanel(didSelectURLString url: String, visitType: VisitType) {
        guard let url = URIFixup.getURL(url) ?? profile.searchEngines.defaultEngine.searchURLForQuery(url) else {
            Logger.browserLogger.warning("Invalid URL, and couldn't generate a search URL for it.")
            return
        }
        return self.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        let tab = self.tabManager.addTab(URLRequest(url: url), afterTab: self.tabManager.selectedTab, isPrivate: isPrivate)
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

extension BrowserViewController: HomePanelDelegate {
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType) {
        showLibrary(panel: panel)
        view.endEditing(true)
    }

    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool) {
        guard let tab = tabManager.selectedTab else { return }
        if isGoogleTopSite {
            tab.urlType = .googleTopSite
            searchTelemetry?.shouldSetGoogleTopSiteSearch = true
        }
        finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
    }

    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        let tab = self.tabManager.addTab(URLRequest(url: url), afterTab: self.tabManager.selectedTab, isPrivate: isPrivate)
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
        guard let tab = tabManager.selectedTab else { return }
        searchTelemetry?.shouldSetUrlTypeSearch = true
        finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
    }

    func searchViewController(_ searchViewController: SearchViewController, didLongPressSuggestion suggestion: String) {
        self.urlBar.setLocation(suggestion, search: true)
    }

    func presentSearchSettingsController() {
        let searchSettingsTableViewController = SearchSettingsTableViewController()
        searchSettingsTableViewController.model = self.profile.searchEngines
        searchSettingsTableViewController.profile = self.profile
        // Update saerch icon when the searchengine changes
        searchSettingsTableViewController.updateSearchIcon = {
            self.urlBar.updateSearchEngineImage()
            self.searchController?.reloadSearchEngines()
            self.searchController?.reloadData()
        }
        let navController = ModalSettingsNavigationController(rootViewController: searchSettingsTableViewController)
        self.present(navController, animated: true, completion: nil)
    }

    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool) {
        self.urlBar.setLocation(text, search: search)
    }
}

extension BrowserViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        libraryDrawerViewController?.close(immediately: true)

        // Reset the scroll position for the ActivityStreamPanel so that it
        // is always presented scrolled to the top when switching tabs.
        if !isRestoring, selected != previous,
            let activityStreamPanel = firefoxHomeViewController {
            activityStreamPanel.scrollToTop()
        }

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

            if previous == nil || tab.isPrivate != previous?.isPrivate {
                applyTheme()

                let ui: [PrivateModeUI?] = [toolbar, topTabsViewController, urlBar]
                ui.forEach { $0?.applyUIMode(isPrivate: tab.isPrivate) }
            }

            readerModeCache = tab.isPrivate ? MemoryReaderModeCache.sharedInstance : DiskReaderModeCache.sharedInstance
            if let privateModeButton = topTabsViewController?.privateModeButton, previous != nil && previous?.isPrivate != tab.isPrivate {
                privateModeButton.setSelected(tab.isPrivate, animated: true)
            }
            ReaderModeHandlers.readerModeCache = readerModeCache

            scrollController.tab = tab
            webViewContainer.addSubview(webView)
            webView.snp.makeConstraints { make in
                make.left.right.top.bottom.equalTo(self.webViewContainer)
            }

            // This is a terrible workaround for a bad iOS 12 bug where PDF
            // content disappears any time the view controller changes (i.e.
            // the user taps on the tabs tray). It seems the only way to get
            // the PDF to redraw is to either reload it or revisit it from
            // back/forward list. To try and avoid hitting the network again
            // for the same PDF, we revisit the current back/forward item and
            // restore the previous scrollview zoom scale and content offset
            // after a short 100ms delay. *facepalm*
            //
            // https://bugzilla.mozilla.org/show_bug.cgi?id=1516524
            if #available(iOS 12.0, *) {
                if tab.mimeType == MIMEType.PDF {
                    let previousZoomScale = webView.scrollView.zoomScale
                    let previousContentOffset = webView.scrollView.contentOffset

                    if let currentItem = webView.backForwardList.currentItem {
                        webView.go(to: currentItem)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                        webView.scrollView.setZoomScale(previousZoomScale, animated: false)
                        webView.scrollView.setContentOffset(previousContentOffset, animated: false)
                    }
                }
            }

            webView.accessibilityLabel = .WebViewAccessibilityLabel
            webView.accessibilityIdentifier = "contentView"
            webView.accessibilityElementsHidden = false

            if webView.url == nil {
                // The web view can go gray if it was zombified due to memory pressure.
                // When this happens, the URL is nil, so try restoring the page upon selection.
                tab.reload()
            }
        }

        updateTabCountUsingTabManager(tabManager)

        removeAllBars()
        if let bars = selected?.bars {
            for bar in bars {
                showBar(bar, animated: true)
            }
        }

        updateFindInPageVisibility(visible: false, tab: previous)
        setupMiddleButtonStatus(isLoading: selected?.loading ?? false)
        navigationToolbar.updateBackStatus(selected?.canGoBack ?? false)
        navigationToolbar.updateForwardStatus(selected?.canGoForward ?? false)
        if let url = selected?.webView?.url, !InternalURL.isValid(url: url) {
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

        if topTabsVisible {
            topTabsDidChangeTab()
        }

        updateInContentHomePanel(selected?.url as URL?)
        if let tab = selected, NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage {
            if tab.url == nil, !tab.restoring {
                urlBar.tabLocationViewDidTapLocation(urlBar.locationView)
            } else {
                urlBar.leaveOverlayMode()
            }
        }
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {
        // If we are restoring tabs then we update the count once at the end
        if !isRestoring {
            updateTabCountUsingTabManager(tabManager)
        }
        tab.tabDelegate = self
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        if let url = tab.url, !(InternalURL(url)?.isAboutURL ?? false), !tab.isPrivate {
            profile.recentlyClosedTabs.addTab(url as URL, title: tab.title, faviconURL: tab.displayFavicon?.url)
        }
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        updateTabCountUsingTabManager(tabManager)
        openUrlAfterRestore()
    }
    
    func openUrlAfterRestore() {
        guard let url = urlFromAnotherApp?.url else { return }
        openURLInNewTab(url, isPrivate: urlFromAnotherApp?.isPrivate ?? false)
        urlFromAnotherApp = nil
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
            make.bottom.equalTo(self.webViewContainer?.snp.bottom ?? 0)
        })
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        let tabTrayV3PrivateMode = tabTrayControllerV3?.viewModel.isInPrivateMode
        let tabTrayV2PrivateMode = tabTrayControllerV2?.viewModel.isInPrivateMode
        let tabTrayV1PrivateMode = tabTrayController?.tabDisplayManager.isPrivate
        guard let toast = toast, !(tabTrayV1PrivateMode ?? (tabTrayV2PrivateMode ?? (tabTrayV3PrivateMode ?? false))) else {
            return
        }
        show(toast: toast, afterWaiting: ButtonToastUX.ToastDelay)
    }

    func updateTabCountUsingTabManager(_ tabManager: TabManager, animated: Bool = true) {
        if let selectedTab = tabManager.selectedTab {
            let count = selectedTab.isPrivate ? tabManager.privateTabs.count : tabManager.normalTabs.count
            toolbar?.updateTabCount(count, animated: animated)
            urlBar.updateTabCount(count, animated: !urlBar.inOverlayMode)
            topTabsViewController?.updateTabCount(count, animated: animated)
        }
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

extension BrowserViewController {
    func presentIntroViewController(_ alwaysShow: Bool = false) {
        if alwaysShow || profile.prefs.intForKey(PrefsKeys.IntroSeen) == nil {
            showProperIntroVC()
        }
    }
    
    func presentETPCoverSheetViewController(_ force: Bool = false) {
        guard !hasTriedToPresentETPAlready else {
            return
        }
        hasTriedToPresentETPAlready = true
        let cleanInstall = UpdateViewModel.isCleanInstall(userPrefs: profile.prefs)
        let shouldShow = ETPViewModel.shouldShowETPCoverSheet(userPrefs: profile.prefs, isCleanInstall: cleanInstall)
        guard force || shouldShow else {
            return
        }
        let etpCoverSheetViewController = ETPCoverSheetViewController()
        if topTabsVisible {
            etpCoverSheetViewController.preferredContentSize = CGSize(width: ViewControllerConsts.PreferredSize.UpdateViewController.width, height: ViewControllerConsts.PreferredSize.UpdateViewController.height)
            etpCoverSheetViewController.modalPresentationStyle = .formSheet
        } else {
            etpCoverSheetViewController.modalPresentationStyle = .fullScreen
        }
        etpCoverSheetViewController.viewModel.startBrowsing = {
            etpCoverSheetViewController.dismiss(animated: true) {
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                _ = self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        etpCoverSheetViewController.viewModel.goToSettings = {
            etpCoverSheetViewController.dismiss(animated: true) {
                let settingsTableViewController = ContentBlockerSettingViewController(prefs: self.profile.prefs)
                settingsTableViewController.profile = self.profile
                settingsTableViewController.tabManager = self.tabManager
                settingsTableViewController.settingsDelegate = self
                self.presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: settingsTableViewController, topTabsVisible: self.topTabsVisible)
            }
        }
        present(etpCoverSheetViewController, animated: true, completion: nil)
    }
    
    // Default browser onboarding
    func presentDBOnboardingViewController(_ force: Bool = false) {
        guard #available(iOS 14.0, *) else { return }
        guard !hasTriedToPresentDBCardAlready || force else { return }
        hasTriedToPresentDBCardAlready = true
        let shouldShow = DefaultBrowserOnboardingViewModel.shouldShowDefaultBrowserOnboarding(userPrefs: profile.prefs)
        guard force || shouldShow else {
            return
        }
        let dBOnboardingViewController = DefaultBrowserOnboardingViewController()
        if topTabsVisible {
            dBOnboardingViewController.preferredContentSize = CGSize(width: ViewControllerConsts.PreferredSize.DBOnboardingViewController.width, height: ViewControllerConsts.PreferredSize.DBOnboardingViewController.height)
            dBOnboardingViewController.modalPresentationStyle = .formSheet
        } else {
            dBOnboardingViewController.modalPresentationStyle = .popover
        }
        dBOnboardingViewController.viewModel.goToSettings = {
            self.firefoxHomeViewController?.dismissDefaultBrowserCard()
            dBOnboardingViewController.dismiss(animated: true) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
            }
        }
        present(dBOnboardingViewController, animated: true, completion: nil)
    }
    
    @discardableResult func presentUpdateViewController(_ force: Bool = false, animated: Bool = true) -> Bool {
        let cleanInstall = UpdateViewModel.isCleanInstall(userPrefs: profile.prefs)
        let coverSheetSupportedAppVersion = UpdateViewModel.coverSheetSupportedAppVersion
        if force || UpdateViewModel.shouldShowUpdateSheet(userPrefs: profile.prefs, isCleanInstall: cleanInstall, supportedAppVersions: coverSheetSupportedAppVersion) {
            let updateViewController = UpdateViewController()
            
            updateViewController.viewModel.startBrowsing = {
                updateViewController.dismiss(animated: true) {
                if self.navigationController?.viewControllers.count ?? 0 > 1 {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
            
            if topTabsVisible {
                updateViewController.preferredContentSize = CGSize(width: ViewControllerConsts.PreferredSize.UpdateViewController.width, height: ViewControllerConsts.PreferredSize.UpdateViewController.height)
                updateViewController.modalPresentationStyle = .formSheet
            } else {
                updateViewController.modalPresentationStyle = .fullScreen
            }
            
            // On iPad we present it modally in a controller
            present(updateViewController, animated: animated) {
                // On first run (and forced) open up the homepage in the background.
                if let homePageURL = NewTabHomePageAccessors.getHomePage(self.profile.prefs), let tab = self.tabManager.selectedTab, DeviceInfo.hasConnectivity() {
                    tab.loadRequest(URLRequest(url: homePageURL))
                }
            }

            return true
        }
        
        return false
    }
    
    private func showProperIntroVC() {
        let introViewController = IntroViewController()
        introViewController.didFinishClosure = { controller, fxaLoginFlow in
            self.profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
            controller.dismiss(animated: true) {
                if self.navigationController?.viewControllers.count ?? 0 > 1 {
                    _ = self.navigationController?.popToRootViewController(animated: true)
                }
                if let flow = fxaLoginFlow {
                    let fxaParams = FxALaunchParams(query: ["entrypoint": "firstrun"])
                    self.presentSignInViewController(fxaParams, flowType: flow, referringPage: .onboarding)
                }
            }
        }
        self.introVCPresentHelper(introViewController: introViewController)
    }
    
    private func introVCPresentHelper(introViewController: UIViewController) {
        // On iPad we present it modally in a controller
        if topTabsVisible {
            introViewController.preferredContentSize = CGSize(width: ViewControllerConsts.PreferredSize.IntroViewController.width, height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            introViewController.modalPresentationStyle = .formSheet
        } else {
            introViewController.modalPresentationStyle = .fullScreen
        }
        present(introViewController, animated: true) {
            // On first run (and forced) open up the homepage in the background.
            if let homePageURL = NewTabHomePageAccessors.getHomePage(self.profile.prefs), let tab = self.tabManager.selectedTab, DeviceInfo.hasConnectivity() {
                tab.loadRequest(URLRequest(url: homePageURL))
            }
        }
    }

    /// This function is called to determine if FxA sign in flow or settings page should be shown
    /// - Parameters:
    ///     - deepLinkParams: FxALaunchParams from deeplink query
    ///     - flowType: FxAPageType is used to determine if email login, qr code login, or user settings page should be presented
    ///     - referringPage: ReferringPage enum is used to handle telemetry events correctly for the view event and the FxA sign in tap events, need to know which route we took to get to them
    func getSignInOrFxASettingsVC(_ deepLinkParams: FxALaunchParams? = nil, flowType: FxAPageType, referringPage: ReferringPage) -> UIViewController {
        // Show the settings page if we have already signed in. If we haven't then show the signin page
        let parentType: FxASignInParentType
        let object: TelemetryWrapper.EventObject
        guard profile.hasSyncableAccount() else {
            switch referringPage {
            case .appMenu, .none:
                parentType = .appMenu
                object = .appMenu
            case .onboarding:
                parentType = .onboarding
                object = .onboarding
            case .settings:
                parentType = .settings
                object = .settings
            }

            let signInVC = FirefoxAccountSignInViewController(profile: profile, parentType: parentType, deepLinkParams: deepLinkParams)
            TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view, object: object)
            return signInVC
        }

        let settingsTableViewController = SyncContentSettingsViewController()
        settingsTableViewController.profile = profile
        return settingsTableViewController
    }

    func presentSignInViewController(_ fxaOptions: FxALaunchParams? = nil, flowType: FxAPageType = .emailLoginFlow, referringPage: ReferringPage = .none) {
        let vcToPresent = getSignInOrFxASettingsVC(fxaOptions, flowType: flowType, referringPage: referringPage)
        presentThemedViewController(navItemLocation: .Left, navItemText: .Close, vcBeingPresented: vcToPresent, topTabsVisible: UIDevice.current.userInterfaceIdiom == .pad)
    }

    @objc func dismissSignInViewController() {
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
            screenshotHelper.takeDelayedScreenshot(currentTab)

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
                let openNewTabAction = UIAlertAction(title: Strings.ContextMenuOpenInNewTab, style: .default) { _ in
                    addTab(url, false)
                }
                actionSheetController.addAction(openNewTabAction, accessibilityIdentifier: "linkContextMenu.openInNewTab")
            }

            let openNewPrivateTabAction = UIAlertAction(title: Strings.ContextMenuOpenInNewPrivateTab, style: .default) { _ in
                addTab(url, true)
            }
            actionSheetController.addAction(openNewPrivateTabAction, accessibilityIdentifier: "linkContextMenu.openInNewPrivateTab")

            let bookmarkAction = UIAlertAction(title: Strings.ContextMenuBookmarkLink, style: .default) { _ in
                self.addBookmark(url: url.absoluteString, title: elements.title)
                SimpleToast().showAlertWithText(Strings.AppMenuAddBookmarkConfirmMessage, bottomContainer: self.webViewContainer)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .contextMenu)
            }
            actionSheetController.addAction(bookmarkAction, accessibilityIdentifier: "linkContextMenu.bookmarkLink")

            let downloadAction = UIAlertAction(title: Strings.ContextMenuDownloadLink, style: .default) { _ in
                // This checks if download is a blob, if yes, begin blob download process
                if !DownloadContentScript.requestBlobDownload(url: url, tab: currentTab) {
                    //if not a blob, set pendingDownloadWebView and load the request in the webview, which will trigger the WKWebView navigationResponse delegate function and eventually downloadHelper.open()
                    self.pendingDownloadWebView = currentTab.webView
                    let request = URLRequest(url: url)
                    currentTab.webView?.load(request)
                }
            }
            actionSheetController.addAction(downloadAction, accessibilityIdentifier: "linkContextMenu.download")

            let copyAction = UIAlertAction(title: Strings.ContextMenuCopyLink, style: .default) { _ in
                UIPasteboard.general.url = url as URL
            }
            actionSheetController.addAction(copyAction, accessibilityIdentifier: "linkContextMenu.copyLink")

            let shareAction = UIAlertAction(title: Strings.ContextMenuShareLink, style: .default) { _ in
                self.presentActivityViewController(url as URL, sourceView: self.view, sourceRect: CGRect(origin: touchPoint, size: touchSize), arrowDirection: .any)
            }
            actionSheetController.addAction(shareAction, accessibilityIdentifier: "linkContextMenu.share")
        }

        if let url = elements.image {
            if dialogTitle == nil {
                dialogTitle = elements.title ?? url.absoluteString
            }

            let saveImageAction = UIAlertAction(title: Strings.ContextMenuSaveImage, style: .default) { _ in
                self.getImageData(url) { data in
                    guard let image = UIImage(data: data) else { return }
                    self.writeToPhotoAlbum(image: image)
                }
            }
            actionSheetController.addAction(saveImageAction, accessibilityIdentifier: "linkContextMenu.saveImage")

            let copyAction = UIAlertAction(title: Strings.ContextMenuCopyImage, style: .default) { _ in
                // put the actual image on the clipboard
                // do this asynchronously just in case we're in a low bandwidth situation
                let pasteboard = UIPasteboard.general
                pasteboard.url = url as URL
                let changeCount = pasteboard.changeCount
                let application = UIApplication.shared
                var taskId = UIBackgroundTaskIdentifier(rawValue: 0)
                taskId = application.beginBackgroundTask(expirationHandler: {
                    application.endBackgroundTask(taskId)
                })

                makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.default).dataTask(with: url) { (data, response, error) in
                    guard let _ = validatedHTTPResponse(response, statusCode: 200..<300) else {
                        application.endBackgroundTask(taskId)
                        return
                    }

                    // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                    // fetching the image; otherwise, in low-bandwidth situations,
                    // we might be overwriting something that the user has subsequently added.
                    if changeCount == pasteboard.changeCount, let imageData = data, error == nil {
                        pasteboard.addImageWithData(imageData, forURL: url)
                    }

                    application.endBackgroundTask(taskId)
                }.resume()

            }
            actionSheetController.addAction(copyAction, accessibilityIdentifier: "linkContextMenu.copyImage")

            let copyImageLinkAction = UIAlertAction(title: Strings.ContextMenuCopyImageLink, style: .default) { _ in
                UIPasteboard.general.url = url as URL
            }
            actionSheetController.addAction(copyImageLinkAction, accessibilityIdentifier: "linkContextMenu.copyImageLink")
        }

        let setupPopover = { [unowned self] in
            // If we're showing an arrow popup, set the anchor to the long press location.
            if let popoverPresentationController = actionSheetController.popoverPresentationController {
                popoverPresentationController.sourceView = self.view
                popoverPresentationController.sourceRect = CGRect(origin: touchPoint, size: touchSize)
                popoverPresentationController.permittedArrowDirections = .any
                popoverPresentationController.delegate = self
            }
        }
        setupPopover()

        if actionSheetController.popoverPresentationController != nil {
            displayedPopoverController = actionSheetController
            updateDisplayedPopoverProperties = setupPopover
        }

        if let dialogTitle = dialogTitle {
            if let _ = dialogTitle.asURL {
                actionSheetController.title = dialogTitle.ellipsize(maxLength: ActionSheetTitleMaxLength)
            } else {
                actionSheetController.title = dialogTitle
            }
        }

        let cancelAction = UIAlertAction(title: Strings.CancelString, style: UIAlertAction.Style.cancel, handler: nil)
        actionSheetController.addAction(cancelAction)
        self.present(actionSheetController, animated: true, completion: nil)
    }

    fileprivate func getImageData(_ url: URL, success: @escaping (Data) -> Void) {
        makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.default).dataTask(with: url) { (data, response, error) in
            if let _ = validatedHTTPResponse(response, statusCode: 200..<300), let data = data {
                success(data)
            }
        }.resume()
    }

    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer) {
        displayedPopoverController?.dismiss(animated: true) {
            self.displayedPopoverController = nil
        }
    }
    
    //Support for CMD+ Click on link to open in a new tab
     override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
         super.pressesBegan(presses, with: event)
         if #available(iOS 13.4, *) {
             guard let key = presses.first?.key, (key.keyCode == .keyboardLeftGUI || key.keyCode == .keyboardRightGUI) else { return } //GUI buttons = CMD buttons on ipad/mac
             self.isCmdClickForNewTab = true
         }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        if #available(iOS 13.4, *) {
            guard let key = presses.first?.key, (key.keyCode == .keyboardLeftGUI || key.keyCode == .keyboardRightGUI) else { return }
            self.isCmdClickForNewTab = false
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

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animate(withDuration: state.animationDuration) {
            UIView.setAnimationCurve(state.animationCurve)
            self.alertStackView.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {

    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateViewConstraints()

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

        clipboardBarDisplayHandler?.didRestoreSession()
    }
}

extension BrowserViewController: TabTrayDelegate {
    // This function animates and resets the tab chrome transforms when
    // the tab tray dismisses.
    func tabTrayDidDismiss(_ tabTray: TabTrayControllerV1) {
        resetBrowserChrome()
    }

    func tabTrayDidAddTab(_ tabTray: TabTrayControllerV1, tab: Tab) {}

    func tabTrayDidAddBookmark(_ tab: Tab) {
        guard let url = tab.url?.absoluteString, !url.isEmpty else { return }
        let tabState = tab.tabState
        addBookmark(url: url, title: tabState.title, favicon: tabState.favicon)
        TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .tabTray)
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
        guard self.isViewLoaded else { return }
        let ui: [Themeable?] = [urlBar, toolbar, readerModeBar, topTabsViewController, firefoxHomeViewController, searchController, libraryViewController, libraryDrawerViewController, tabTrayControllerV2]
        ui.forEach { $0?.applyTheme() }
        statusBarOverlay.backgroundColor = shouldShowTopTabsForTraitCollection(traitCollection) ? UIColor.Photon.Grey80 : urlBar.backgroundColor
        setNeedsStatusBarAppearanceUpdate()

        (presentedViewController as? Themeable)?.applyTheme()

        // Update the `background-color` of any blank webviews.
        let webViews = tabManager.tabs.compactMap({ $0.webView as? TabWebView })
        webViews.forEach({ $0.applyTheme() })

        let tabs = tabManager.tabs
        tabs.forEach {
            $0.applyTheme()
            urlBar.locationView.tabDidChangeContentBlocking($0)
        }
        
        guard let contentScript = self.tabManager.selectedTab?.getContentScript(name: ReaderMode.name()) else { return }
        appyThemeForPreferences(profile.prefs, contentScript: contentScript)
    }
}

extension BrowserViewController: JSPromptAlertControllerDelegate {
    func promptAlertControllerDidDismiss(_ alertController: JSPromptAlertController) {
        showQueuedAlertIfAvailable()
    }
}

extension BrowserViewController: TopTabsDelegate {
    func topTabsDidPressTabs() {
        libraryDrawerViewController?.close(immediately: true)
        urlBar.leaveOverlayMode(didCancel: true)
        self.urlBarDidPressTabs(urlBar)
    }

    func topTabsDidPressNewTab(_ isPrivate: Bool) {
        libraryDrawerViewController?.close(immediately: true)
        openBlankNewTab(focusLocationField: false, isPrivate: isPrivate)
    }

    func topTabsDidTogglePrivateMode() {
        libraryDrawerViewController?.close(immediately: true)
        guard let _ = tabManager.selectedTab else {
            return
        }
        urlBar.leaveOverlayMode()
    }

    func topTabsDidChangeTab() {
        libraryDrawerViewController?.close()
        urlBar.leaveOverlayMode(didCancel: true)
    }
}

extension BrowserViewController: DevicePickerViewControllerDelegate, InstructionsViewControllerDelegate {
    func instructionsViewControllerDidClose(_ instructionsViewController: InstructionsViewController) {
        self.popToBVC()
    }

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        self.popToBVC()
    }

    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        guard let tab = tabManager.selectedTab, let url = tab.canonicalURL?.displayURL?.absoluteString else { return }
        let shareItem = ShareItem(url: url, title: tab.title, favicon: tab.displayFavicon)
        guard shareItem.isShareable else {
            let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.popToBVC()})
            present(alert, animated: true, completion: nil)
            return
        }
        profile.sendItem(shareItem, toDevices: devices).uponQueue(.main) { _ in
            self.popToBVC()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SimpleToast().showAlertWithText(Strings.AppMenuTabSentConfirmMessage, bottomContainer: self.webViewContainer)
            }
        }
    }
}

// MARK: - reopen last closed tab

extension BrowserViewController {

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if AppConstants.MOZ_SHAKE_TO_RESTORE {
                homePanelDidRequestToRestoreClosedTab(motion)
        }
    }

    func homePanelDidRequestToRestoreClosedTab(_ motion: UIEvent.EventSubtype) {
        guard motion == .motionShake, !topTabsVisible, !urlBar.inOverlayMode,
            let lastClosedURL = profile.recentlyClosedTabs.tabs.first?.url,
            let selectedTab = tabManager.selectedTab else { return }

        let alertTitleText = Strings.ReopenLastTabAlertTitle
        let reopenButtonText = Strings.ReopenLastTabButtonText
        let cancelButtonText = Strings.ReopenLastTabCancelText

        func reopenLastTab(_ action: UIAlertAction) {
            let request = URLRequest(url: lastClosedURL)
            let closedTab = tabManager.addTab(request, afterTab: selectedTab, isPrivate: false)
            tabManager.selectTab(closedTab)
        }

        let alert = AlertController(title: alertTitleText, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: reopenButtonText, style: .default, handler: reopenLastTab), accessibilityIdentifier: "BrowserViewController.ReopenLastTabAlert.ReopenButton")
        alert.addAction(UIAlertAction(title: cancelButtonText, style: .cancel, handler: nil), accessibilityIdentifier: "BrowserViewController.ReopenLastTabAlert.CancelButton")

        self.present(alert, animated: true, completion: nil)
    }
}

extension BrowserViewController {
    public static func foregroundBVC() -> BrowserViewController {
//        if #available(iOS 13.0, *) {
//            for scene in UIApplication.shared.connectedScenes {
//                if scene.activationState == .foregroundActive, let sceneDelegate = ((scene as? UIWindowScene)?.delegate as? UIWindowSceneDelegate) {
//                    return sceneDelegate.window!!.rootViewController as! BrowserViewController
//                }
//            }
//        }
        
        return (UIApplication.shared.delegate as! AppDelegate).browserViewController
    }
}
