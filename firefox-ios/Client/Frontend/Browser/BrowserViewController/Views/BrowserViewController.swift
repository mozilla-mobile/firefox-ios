// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Photos
import UIKit
import WebKit
import Shared
import Storage
import SnapKit
import Account
import MobileCoreServices
import Common
import Redux
import WebEngine
import WidgetKit
import ActivityKit

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import struct MozillaAppServices.Login
import enum MozillaAppServices.BookmarkRoots
import enum MozillaAppServices.VisitType

class BrowserViewController: UIViewController,
                             SearchBarLocationProvider,
                             Themeable,
                             LibraryPanelDelegate,
                             RecentlyClosedPanelDelegate,
                             QRCodeViewControllerDelegate,
                             StoreSubscriber,
                             BrowserFrameInfoProvider,
                             CanRemoveQuickActionBookmark,
                             LibraryPanelBookmarkDelegate,
                             AddressToolbarContainerDelegate,
                             BrowserStatusBarScrollDelegate {
    typealias SubscriberStateType = BrowserViewControllerState

    // MARK: - Properties

    var windowUUID: WindowUUID { return tabManager.windowUUID }
    var browserDelegate: BrowserDelegate?
    var notificationCenter: NotificationProtocol
    var profile: Profile
    var tabManager: TabManager
    var searchEnginesManager: SearchEnginesManager
    var overlayManager: OverlayModeManager
    var logger: Logger

    // MARK: - Redux state

    var browserViewControllerState: BrowserViewControllerState

    // MARK: - UI

    var contentContainer: ContentContainer!
    var urlBarView: URLBarViewProtocol { return isToolbarRefactorEnabled ? addressToolbarContainer : legacyUrlBar! }
    var legacyUrlBar: URLBarView?
    var clipboardBarDisplayHandler: ClipboardBarDisplayHandler?
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    var statusBarOverlay: StatusBarOverlay!
    var topTouchArea: UIView!
    var bottomContentStackView: UIStackView!
    var bottomContainer: BottomContainer!
    var overKeyboardContainer: OverKeyboardContainer!
    var header: UIStackView!
    var webViewContainer: UIView!
    var toolbar: TabToolbar!
    var searchController: SearchViewController?
    var screenshotHelper: ScreenshotHelper!
    var homePanelController: HomePanelViewController?
    var libraryPanelController: LibraryPanelViewController?
    var libraryViewController: LibraryViewController?
    var webPagePreview: WebPagePreview!
    var topTabsViewController: TopTabsViewController?
    var navigationToolbarContainer: NavigationToolbarContainer!
    var addressToolbarContainer: AddressToolbarContainer!

    // MARK: - Constraints

    var legacyUrlBarHeightConstraint: Constraint?
    var topTouchAreaHeightConstraint: Constraint?
    var keyboardBackdropWidthConstraint: Constraint?
    var keyboardBackdropHeightConstraint: Constraint?

    // MARK: - Helpers and managers

    var downloadHelper: DownloadHelper?
    var zoomPageBar: ZoomPageBar?
    var addressBarPanGestureHandler: AddressBarPanGestureHandler?
    var microsurvey: MicrosurveyPromptView?
    var currentMiddleButtonState: MiddleButtonState?
    var mobileConfigHelper: OpenMobileConfigHelper?
    var keyboardBackdrop: UIView?
    var pendingToast: Toast? // A toast that might be waiting for BVC to appear before displaying
    var downloadToast: DownloadToast? // A toast that is showing the combined download progress
    var downloadProgressManager: DownloadProgressManager?
    let tabsPanelTelemetry: TabsPanelTelemetry

    private var _downloadLiveActivityWrapper: Any?

    @available(iOS 17, *)
    private var downloadLiveActivityWrapper: DownloadLiveActivityWrapper? {
        get { _downloadLiveActivityWrapper as? DownloadLiveActivityWrapper }
        set { _downloadLiveActivityWrapper = newValue }
    }

    lazy var screenshotHelper = ScreenshotHelper(controller: self)

    private lazy var searchTelemetry = SearchTelemetry()

    private lazy var contextMenuHelper = ContextMenuHelper(
        profile: profile,
        toastContainer: contentContainer
    )

    private lazy var scrollController = BrowserScrollingController(
        windowUUID: windowUUID,
        header: header,
        overKeyboardContainer: overKeyboardContainer,
        bottomContainer: bottomContainer
    )

    private lazy var privacyWindowHelper = PrivacyWindowHelper()

    // MARK: - Lifecycle

    init(profile: Profile,
         tabManager: TabManager,
         searchEnginesManager: SearchEnginesManager,
         windowUUID: WindowUUID) {
        self.profile = profile
        self.tabManager = tabManager
        self.searchEnginesManager = searchEnginesManager
        self.overlayManager = OverlayModeManager()
        self.readerModeCache = DiskReaderModeCache.sharedInstance
        self.notificationCenter = NotificationCenter.default
        self.logger = DefaultLogger.shared
        self.browserViewControllerState = BrowserViewControllerState(windowUUID: windowUUID)
        self.tabsPanelTelemetry = TabsPanelTelemetry()

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // On iPhone, if we are about to show the On-Boarding, blank out the browser so that it does
        // not flash before we present. This change of alpha also participates in the animation when
        // the intro view is dismissed.
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.alpha = (profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil) ? 1.0 : 0.0
        }

        if !displayedRestoreTabsAlert && crashedLastLaunch() {
            displayedRestoreTabsAlert = true
            showRestoreTabsAlert()
        }

        updateToolbarStateForTraitCollection(self.traitCollection, withTransition: coordinator)
        updateStatusBarOverlayColor()
    }

    private var displayedRestoreTabsAlert = false

    override func viewDidAppear(_ animated: Bool) {
        presentIntroViewController()

        screenshotHelper.viewIsVisible = true
        screenshotHelper.takePendingScreenshots(tabManager.tabs)

        super.viewDidAppear(animated)

        if shouldShowWhatsNewTab() {
            // Ideally, this would be launched from the AppDelegate or SceneDelegate if we want to support
            // multiple scenes. However, we need a reference to the BVC to present the What's New.
            // For now, this will be presented from the BVC on viewDidAppear.
            presentWhatsNew()
        }

        if let toast = self.pendingToast {
            self.pendingToast = nil
            show(toast: toast, duration: nil)
        }

        showQueuedAlertIfAvailable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        screenshotHelper.viewIsVisible = false
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        statusBarOverlay.snp.remakeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(view.safeAreaInsets.top)
        }
    }

    func shouldShowWhatsNewTab() -> Bool {
        guard featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildAndUser) else { return false }

        let showWhatsNew = WhatsNewViewModel.shouldShowWhatsNew(userPrefs: profile.prefs)
        return showWhatsNew
    }

    func presentWhatsNew() {
        let whatsNewViewController = WhatsNewViewController(windowUUID: windowUUID)
        whatsNewViewController.profile = profile

        let controller = DismissableNavigationViewController(rootViewController: whatsNewViewController)
        controller.onViewDismissed = {
            WhatsNewViewModel.setWhatsNewHasBeenShown(userPrefs: self.profile.prefs)
        }
        self.present(controller, animated: true, completion: nil)
    }

    func didInit() {
        let defaultRequest = URLRequest(url: URL(string: "about:blank")!)
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let webView = TabWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self

        readerModeCache = DiskReaderModeCache.sharedInstance

        webViewContainer = UIView()
        webViewContainer.addSubview(webView)

        // Temporary work around for covering the non-clipped web view content
        statusBarOverlay = StatusBarOverlay()

        topTouchArea = UIView()

        // Setup the URL bar, wrapped in a view to get transparency effect
        bottomContentStackView = UIStackView()
        bottomContentStackView.distribution = .fillEqually
        bottomContentStackView.alignment = .center
        bottomContentStackView.layoutMargins = UIEdgeInsets(
            top: 0,
            left: UIConstants.ToolbarHeight,
            bottom: 0,
            right: UIConstants.ToolbarHeight
        )
        bottomContentStackView.isLayoutMarginsRelativeArrangement = true
        bottomContentStackView.insetsLayoutMarginsFromSafeArea = false

        bottomContainer = BottomContainer()
        overKeyboardContainer = OverKeyboardContainer()
        header = UIStackView()
        header.axis = .vertical
        header.clipsToBounds = true

        contentContainer = ContentContainer(frame: .zero)

        // Setup the toolbar
        toolbar = TabToolbar()
        toolbar.tabToolbarDelegate = self
        toolbar.applyUIMode(isPrivate: false, theme: currentTheme())

        navigationToolbarContainer = NavigationToolbarContainer()
        addressToolbarContainer = AddressToolbarContainer()

        var toolbarHelper: ToolbarHelperInterface = ToolbarHelper()

        updateToolbarStateForTraitCollection(self.traitCollection)

        setupConstraints()

        // Setup UIDropInteraction to handle dragging and dropping
        // links into the view from other apps.
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        if readerMode.state == .active && !contentContainer.hasHomepage {
            showReaderModeBar(animated: false)
        } else {
            hideReaderModeBar(animated: false)
        }

        dismissModalsIfStartAtHome()
    }

    private func showToastType(toast: ToastType) {
        func showToast() {
            SimpleToast().showAlertWithText(
                toast.title,
                bottomContainer: contentContainer,
                theme: currentTheme()
            )
        }
        switch toast {
        case .clearCookies,
                .addToReadingList,
                .removeShortcut,
                .removeFromReadingList:
            showToast()
        case .addBookmark(let urlString):
            if isBookmarkRefactorEnabled {
                showBookmarkToast(urlString: urlString, action: .add)
            } else {
                showToast()
            }
        default:
            let viewModel = ButtonToastViewModel(
                labelText: toast.title,
                buttonText: toast.buttonText)
            let uuid = windowUUID
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme(),
                                    completion: { buttonPressed in
                if let action = toast.reduxAction(for: uuid), buttonPressed {
                    store.dispatchLegacy(action)
                }
            })

            show(toast: toast)
        }
    }

    private func handleMicrosurvey(state: BrowserViewControllerState) {
        if !state.microsurveyState.showPrompt {
            guard microsurvey != nil else { return }
            removeMicrosurveyPrompt()
        } else if state.microsurveyState.showSurvey {
            guard let model = state.microsurveyState.model else {
                logger.log("Microsurvey model should not be nil", level: .warning, category: .redux)
                return
            }
            navigationHandler?.showMicrosurvey(model: model)
        } else if state.microsurveyState.showPrompt {
            guard microsurvey == nil else { return }
            createMicrosurveyPrompt(with: state.microsurveyState)
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupEssentialUI()
        subscribeToRedux()
        enqueueTabRestoration()

        Task(priority: .background) { [weak self] in
            // App startup telemetry accesses RustLogins to queryLogins, shouldn't be on the app startup critical path
            self?.trackStartupTelemetry()
        }
    }

    private func setupEssentialUI() {
        addSubviews()
        setupConstraints()
        setupNotifications()

        overlayManager.setURLBar(urlBarView: urlBarView)

        if toolbarHelper.shouldShowTopTabs(for: traitCollection) {
            setupTopTabsViewController()
        }

        // Update theme of already existing views
        let theme = currentTheme()
        contentContainer.backgroundColor = theme.colors.layer1
        header.applyTheme(theme: theme)
        overKeyboardContainer.applyTheme(theme: theme)
        bottomContainer.applyTheme(theme: theme)
        bottomContentStackView.applyTheme(theme: theme)
        statusBarOverlay.scrollDelegate = self
        statusBarOverlay.hasTopTabs = toolbarHelper.shouldShowTopTabs(for: traitCollection)
        statusBarOverlay.applyTheme(theme: theme)
        topTabsViewController?.applyTheme()

        KeyboardHelper.defaultHelper.addDelegate(self)
        listenForThemeChange(view)
        setupAccessibleActions()

        clipboardBarDisplayHandler = ClipboardBarDisplayHandler(prefs: profile.prefs,
                                                                tabManager: tabManager)
        clipboardBarDisplayHandler?.delegate = self

        navigationToolbarContainer.toolbarDelegate = self
        scrollController.header = header
        scrollController.overKeyboardContainer = overKeyboardContainer
        scrollController.bottomContainer = bottomContainer

        // Setup UIDropInteraction to handle dragging and dropping
        // links into the view from other apps.
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
    }

    private func setupTopTabsViewController() {
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        topTabsViewController.delegate = self
        addChild(topTabsViewController)
        header.addArrangedViewToTop(topTabsViewController.view)
        topTabsViewController.didMove(toParent: self)
        self.topTabsViewController = topTabsViewController
    }

    private func setupAccessibleActions() {
        // UIAccessibilityCustomAction subclass holding an AccessibleAction instance does not work,
        // thus unable to generate AccessibleActions and UIAccessibilityCustomActions "on-demand" and need


        // to store them in an array.
        let newTabAction = UIAccessibilityCustomAction(name: .LegacyTabTrayNewTabAccessibilityLabel) { _ in
            self.openBlankNewTab(focusLocationField: false)
            return true
        }

        let closeTabAction = UIAccessibilityCustomAction(name: .TabAccessibilityCloseActionLabel) { _ in
            if let tab = self.tabManager.selectedTab {
                self.tabManager.removeTab(tab)
            }
            return true
        }

        view.accessibilityCustomActions = [newTabAction, closeTabAction]
    }

    private func subscribeToRedux() {
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return BrowserViewControllerState(
                    appState: appState,
                    uuid: uuid
                )
            })
        })

        let action = ScreenAction(windowUUID: uuid,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .browserViewController)
        store.dispatch(action)
    }

    private func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .browserViewController)
        store.dispatch(action)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // During split screen launching on iPad, this callback gets fired before viewDidLoad gets a chance to
        // set things up. Make sure to only update the toolbar state if the view controller has been initialized.
        guard isViewLoaded else { return }

        updateToolbarStateForTraitCollection(traitCollection, withTransition: coordinator)
        displayedPopoverController?.dismiss(animated: true, completion: nil)
        displayedPopoverController = nil

        if topTabsViewController != nil {
            topTabsViewController?.scrollToCurrentTab(false, centerCell: false)
            if toolbarHelper.shouldShowTopTabs(for: traitCollection) {
                topTabsViewController?.applyTheme()
            }
        }

        DispatchQueue.main.async {
            self.statusBarOverlay.hasTopTabs = self.toolbarHelper.shouldShowTopTabs(for: self.traitCollection)
        }
    }

    func dismissVisibleMenus() {
        displayedPopoverController?.dismiss(animated: true)
        displayedPopoverController = nil
    }

    @objc
    func appDidEnterBackgroundNotification() {
        displayedPopoverController?.dismiss(animated: false)
        displayedPopoverController = nil
    }

    @objc
    func tappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

    @objc
    func appWillResignActiveNotification() {
        // Dismiss any popovers that might be visible
        displayedPopoverController?.dismiss(animated: false, completion: nil)
        displayedPopoverController = nil

        // If we are displying a private tab, hide any elements in the tab that we wouldn't want shown
        // when the app is in the home switcher
        guard let privateTab = tabManager.selectedTab, privateTab.isPrivate else { return }

        webViewContainer.isHidden = true
        webViewContainer.alpha = 0
        urlBarView.locationContainer.isHidden = true
        topTabsViewController?.switchForegroundStatus(isInForeground: false)
        presentedViewController?.popoverPresentationController?.sourceView = nil
    }

    @objc
    func appDidBecomeActiveNotification() {
        // Re-show any components that might have been hidden because they were being displayed
        // as part of a private mode tab
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions(), animations: {
            self.webViewContainer.isHidden = false
            self.webViewContainer.alpha = 1
            self.urlBarView.locationContainer.isHidden = false
            self.view.backgroundColor = UIColor.clear
        }, completion: nil)
        topTabsViewController?.switchForegroundStatus(isInForeground: true)

        // Re-show toolbar which might have been hidden during scrolling (prior to app moving into the background)
        scrollController.showToolbars(animated: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        dismissVisibleMenus()

        coordinator.animate(alongsideTransition: { context in
            self.scrollController.updateMinimumZoom()
            self.topTabsViewController?.scrollToCurrentTab(false, centerCell: true)
            if let popover = self.displayedPopoverController {
                popover.dismiss(animated: true, completion: nil)
                self.displayedPopoverController = nil
            }
        }, completion: { _ in
            self.scrollController.setMinimumZoom()
        })
    }

    func dismissModalsIfStartAtHome() {
        if NewTabAccessors.getHomePage(self.profile.prefs) == .homePage {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }

    func resetBrowserChrome() {
        // animate and reset transform for tab chrome
        urlBarView.updateAlphaForSubviews(1)
        bottomContainer.transform = CGAffineTransform.identity
        header.transform = CGAffineTransform.identity
        statusBarOverlay.isHidden = false
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        topTouchAreaHeightConstraint?.update(offset: BrowserViewControllerUX.ShowHeaderTapAreaHeight)
        legacyUrlBarHeightConstraint?.update(offset: UIConstants.TopToolbarHeightMax)
        keyboardBackdropWidthConstraint?.update(offset: -keyboardBackdrop?.frame.width ?? 0)
        keyboardBackdropHeightConstraint?.update(offset: -keyboardBackdrop?.frame.height ?? 0)

        // Setup the bottom toolbar
        toolbar.snp.remakeConstraints { make in
            make.edges.equalTo(bottomContainer)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }

        navigationToolbarContainer.snp.remakeConstraints { make in
            make.edges.equalTo(bottomContainer)
            make.height.equalTo(UIConstants.BottomToolbarHeight)
        }
    }

    private func showHomePanelController(inline: Bool, homePanelDelegate: HomePanelDelegate, libraryPanelDelegate: LibraryPanelDelegate) {
        homePanelController = HomePanelViewController(profile: profile,
                                                      panelDelegate: homePanelDelegate,
                                                      tabManager: tabManager,
                                                      urlBar: urlBarView)

        homePanelController?.homePanelDelegate = homePanelDelegate
        homePanelController?.libraryPanelDelegate = libraryPanelDelegate
        homePanelController?.applyTheme()
        addChild(homePanelController!)
        let panelView = homePanelController!.view!

        if inline {
            contentContainer.addSubview(panelView)
            panelView.snp.makeConstraints { make in
                make.edges.equalTo(self.contentContainer)
            }
        } else {
            view.addSubview(panelView)
            panelView.snp.makeConstraints { make in
                make.edges.equalTo(self.view)
            }
        }

        homePanelController!.didMove(toParent: self)
    }

    private func hideHomePanelController() {
        if let controller = homePanelController {
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            homePanelController = nil
        }
    }

    private func updateToolbarStateForTraitCollection(_ newCollection: UITraitCollection, withTransition coordinator: UIViewControllerTransitionCoordinator? = nil) {
        let showNavToolbar = toolbarHelper.shouldShowNavigationToolbar(for: newCollection)
        let showTopTabs = toolbarHelper.shouldShowTopTabs(for: newCollection)

        urlBarView.topTabsIsShowing = showTopTabs
        urlBarView.setShowToolbar(!showNavToolbar)

        if showTopTabs {
            if topTabsViewController == nil {
                let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
                topTabsViewController.delegate = self
                addChild(topTabsViewController)
                header.addArrangedViewToTop(topTabsViewController.view)
                topTabsViewController.didMove(toParent: self)
                self.topTabsViewController = topTabsViewController
            }
            topTabsViewController?.applyTheme()
        } else {
            if let topTabsViewController = topTabsViewController {
                topTabsViewController.willMove(toParent: nil)
                header.removeArrangedView(topTabsViewController.view)
                topTabsViewController.removeFromParent()
                self.topTabsViewController = nil
            }
        }

        if !showNavToolbar {
            toolbar.removeFromSuperview()
            toolbar.tabToolbarDelegate = nil
            toolbar.applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false, theme: currentTheme())
        } else {
            toolbar.tabToolbarDelegate = self
            toolbar.applyUIMode(isPrivate: tabManager.selectedTab?.isPrivate ?? false, theme: currentTheme())
        }

        view.setNeedsUpdateConstraints()
        if let home = homePanelController, home.view.superview == view {
            home.view.snp.remakeConstraints { make in
                make.edges.equalTo(self.view)
            }
        }

        if let coordinator = coordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    func updateStatusBarOverlayColor() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        statusBarOverlay.backgroundColor = isPrivate ? UIColor.Photon.Ink90 : currentTheme().colors.layer1
    }

    func switchToolbarIfNeeded() {
        guard !shouldHideToolbar() else {
            addressToolbarContainer.isHidden = true
            return
        }
        var updateNeeded = false

        // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
        if isToolbarRefactorEnabled {
            addressToolbarContainer.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        }

        if isToolbarRefactorEnabled, addressToolbarContainer.superview == nil, let legacyUrlBar {
            // Show toolbar refactor
            updateNeeded = true
            overKeyboardContainer.removeArrangedView(legacyUrlBar, animated: false)
            header.removeArrangedView(legacyUrlBar, animated: false)
            bottomContainer.removeArrangedView(toolbar, animated: false)

            addAddressToolbar()
        } else if !isToolbarRefactorEnabled && (legacyUrlBar == nil || legacyUrlBar?.superview == nil) {
            // Show legacy toolbars
            updateNeeded = true

            overKeyboardContainer.removeArrangedView(addressToolbarContainer, animated: false)
            header.removeArrangedView(addressToolbarContainer, animated: false)
            bottomContainer.removeArrangedView(navigationToolbarContainer, animated: false)

            if isSwipingTabsEnabled {
                addressBarPanGestureHandler?.disablePanGestureRecognizer()
            }
            createLegacyUrlBar()

            legacyUrlBar?.snp.makeConstraints { make in
                legacyUrlBarHeightConstraint = make.height.equalTo(UIConstants.TopToolbarHeightMax).constraint
            }
        }

        if updateNeeded {
            let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar
            bottomContainer.addArrangedViewToBottom(toolbarToShow, animated: false)
            overlayManager.setURLBar(urlBarView: urlBarView)
            updateToolbarStateForTraitCollection(traitCollection)
            updateViewConstraints()
        }
    }

    private func createLegacyUrlBar() {
        guard !isToolbarRefactorEnabled else { return }

        let urlBar = URLBarView(profile: profile, windowUUID: windowUUID)
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.tabToolbarDelegate = self
        urlBar.applyTheme(theme: currentTheme())
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: currentTheme())
        urlBar.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)

        self.legacyUrlBar = urlBar
    }

    private func addAddressToolbar() {
        guard isToolbarRefactorEnabled, !shouldHideToolbar() else {
            return
        }

        addressToolbarContainer.configure(
            windowUUID: windowUUID,
            profile: profile,
            searchEnginesManager: searchEnginesManager,
            delegate: self,
            isUnifiedSearchEnabled: isUnifiedSearchEnabled
        )
        addressToolbarContainer.applyTheme(theme: currentTheme())
        addressToolbarContainer.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)

        guard isSwipingTabsEnabled else { return }
        addressBarPanGestureHandler = AddressBarPanGestureHandler(
            addressToolbarContainer: addressToolbarContainer,
            contentContainer: contentContainer,
            webPagePreview: webPagePreview,
            statusBarOverlay: statusBarOverlay,
            tabManager: tabManager,
            windowUUID: windowUUID,
            screenshotHelper: screenshotHelper
        )
    }

    func addSubviews() {
        if isSwipingTabsEnabled, isToolbarRefactorEnabled {
            view.addSubviews(webPagePreview)
        }
        view.addSubviews(contentContainer)

        view.addSubview(topTouchArea)

        // Work around for covering the non-clipped web view content
        view.addSubview(statusBarOverlay)

        // Setup the URL bar, wrapped in a view to get transparency effect
        if isToolbarRefactorEnabled {
            addAddressToolbar()
        } else {
            createLegacyUrlBar()
        }

        view.addSubview(header)
        view.addSubview(bottomContentStackView)

        let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar

        bottomContainer.addArrangedSubview(toolbarToShow)
        view.addSubview(bottomContainer)

        // add overKeyboardContainer after bottomContainer so the address toolbar shadow
        // for bottom toolbar doesn't get clipped
        view.addSubview(overKeyboardContainer)

        if isSwipingTabsEnabled {
            // Add Homepage to view hierarchy so it is possible to take screenshot from it
            showEmbeddedHomepage(inline: false, isPrivate: false)
            browserDelegate?.setHomepageVisibility(isVisible: false)
            addressBarPanGestureHandler?.homepageScreenshotToolProvider = { [weak self] in
                return self?.browserDelegate?.homepageScreenshotTool()
            }
        }
    }

    private func enqueueTabRestoration() {
        guard isDeeplinkOpening == false else { return }

        if let sessionData = OldTabSessionStore.shared.getSessionData(for: windowUUID),
           !sessionData.isEmpty {
            tabManager.restore(sessionData, clearPrivateTabs: shouldClearPrivateTabs(), tabDisplayType: .TabGrid)
            OldTabSessionStore.shared.clearSessionData(for: windowUUID)
        } else {
            tabManager.selectTab(tabManager.addTab())
        }
    }

    private func shouldClearPrivateTabs() -> Bool {
        return !PrivateBrowsingManager.shared.isPrivateBrowsingEnabled
    }

    func setupConstraints() {
        topTouchArea.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            topTouchAreaHeightConstraint = make.height.equalTo(BrowserViewControllerUX.ShowHeaderTapAreaHeight).constraint
        }

        contentContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)

            if isToolbarRefactorEnabled {
                make.top.equalTo(header.snp.bottom)
                make.bottom.equalTo(bottomContainer.snp.top)
            } else {
                make.top.equalTo(legacyUrlBar?.snp.bottom ?? header.snp.bottom)
                make.bottom.equalTo(bottomContainer.snp.top)
            }
        }

        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalTo(view)
        }

        bottomContentStackView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.top.equalTo(bottomContainer.snp.bottom)
        }

        bottomContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        overKeyboardContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view)
        }

        if isSwipingTabsEnabled, isToolbarRefactorEnabled {
            webPagePreview.snp.makeConstraints { make in
                make.edges.equalTo(view)
            }
        }
    }

    private func setupNotifications() {
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onReduceTransparencyStatusDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onDownloadProgressDidChange),
            name: .DownloadProgressChanged,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onDownloadDidFinish),
            name: .DownloadDidFinish,
            object: nil)
    }

    deinit {
        unsubscribeFromRedux()
        notificationCenter.removeObserver(self)
    }

    @objc
    private func onDownloadProgressDidChange(_ notification: Notification) {
        guard let notiWindowUUID = notification.userInfo?["windowUUID"] as? String,
              notiWindowUUID == self.windowUUID.uuidString else {return}
        self.downloadToast?.updateProgress(notification)
    }

    @objc
    private func onDownloadDidFinish(_ notification: Notification) {
        guard let notiWindowUUID = notification.userInfo?["windowUUID"] as? String,
              notiWindowUUID == self.windowUUID.uuidString else {return}
        self.downloadToast?.dismiss(true)
        self.stopDownload(buttonPressed: true)
    }

    @objc
    private func onReduceTransparencyStatusDidChange(_ notification: Notification) {
        updateBlurViews()

        store.dispatchLegacy(
            ToolbarAction(
                isTranslucent: toolbarHelper.shouldBlur(),
                windowUUID: windowUUID,
                actionType: ToolbarActionType.translucencyDidChange
            )
        )
    }

    // TODO: FXIOS-12632 Refactor how we determine when to hide / show toolbar
    /// If we are showing the homepage search bar, then we should hide the address toolbar
    private func shouldHideToolbar() -> Bool {
        let shouldShowSearchBar = store.state.screenState(
            HomepageState.self,
            for: .homepage,
            window: windowUUID
        )?.searchState.shouldShowSearchBar ?? false
        guard shouldShowSearchBar else { return false }
        return true
    }

    private func switchToolbarIfNeeded() {
        guard !shouldHideToolbar() else {
            addressToolbarContainer.isHidden = true
            return
        }
        var updateNeeded = false

        // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
        if isToolbarRefactorEnabled {
            addressToolbarContainer.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        }

        if isToolbarRefactorEnabled, addressToolbarContainer.superview == nil, let legacyUrlBar {
            // Show toolbar refactor
            updateNeeded = true
            overKeyboardContainer.removeArrangedView(legacyUrlBar, animated: false)
            header.removeArrangedView(legacyUrlBar, animated: false)
            bottomContainer.removeArrangedView(toolbar, animated: false)

            addAddressToolbar()
        } else if !isToolbarRefactorEnabled && (legacyUrlBar == nil || legacyUrlBar?.superview == nil) {
            // Show legacy toolbars
            updateNeeded = true

            overKeyboardContainer.removeArrangedView(addressToolbarContainer, animated: false)
            header.removeArrangedView(addressToolbarContainer, animated: false)
            bottomContainer.removeArrangedView(navigationToolbarContainer, animated: false)

            if isSwipingTabsEnabled {
                addressBarPanGestureHandler?.disablePanGestureRecognizer()
            }
            createLegacyUrlBar()

            legacyUrlBar?.snp.makeConstraints { make in
                legacyUrlBarHeightConstraint = make.height.equalTo(UIConstants.TopToolbarHeightMax).constraint
            }
        }

        if updateNeeded {
            let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar
            bottomContainer.addArrangedViewToBottom(toolbarToShow, animated: false)
            overlayManager.setURLBar(urlBarView: urlBarView)
            updateToolbarStateForTraitCollection(traitCollection)
            updateViewConstraints()
        }
    }

    private func createLegacyUrlBar() {
        guard !isToolbarRefactorEnabled else { return }

        let urlBar = URLBarView(profile: profile, windowUUID: windowUUID)
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.tabToolbarDelegate = self
        urlBar.applyTheme(theme: currentTheme())
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: currentTheme())
        urlBar.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)

        self.legacyUrlBar = urlBar
    }

    private func addAddressToolbar() {
        guard isToolbarRefactorEnabled, !shouldHideToolbar() else {
            return
        }

        addressToolbarContainer.configure(
            windowUUID: windowUUID,
            profile: profile,
            searchEnginesManager: searchEnginesManager,
            delegate: self,
            isUnifiedSearchEnabled: isUnifiedSearchEnabled
        )
        addressToolbarContainer.applyTheme(theme: currentTheme())
        addressToolbarContainer.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)

        guard isSwipingTabsEnabled else { return }
        addressBarPanGestureHandler = AddressBarPanGestureHandler(
            addressToolbarContainer: addressToolbarContainer,
            contentContainer: contentContainer,
            webPagePreview: webPagePreview,
            statusBarOverlay: statusBarOverlay,
            tabManager: tabManager,
            windowUUID: windowUUID,
            screenshotHelper: screenshotHelper
        )
    }

    func addSubviews() {
        if isSwipingTabsEnabled, isToolbarRefactorEnabled {
            view.addSubviews(webPagePreview)
        }
        view.addSubviews(contentContainer)

        view.addSubview(topTouchArea)

        // Work around for covering the non-clipped web view content
        view.addSubview(statusBarOverlay)

        // Setup the URL bar, wrapped in a view to get transparency effect
        if isToolbarRefactorEnabled {
            addAddressToolbar()
        } else {
            createLegacyUrlBar()
        }

        view.addSubview(header)
        view.addSubview(bottomContentStackView)

        let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar

        bottomContainer.addArrangedSubview(toolbarToShow)
        view.addSubview(bottomContainer)

        // add overKeyboardContainer after bottomContainer so the address toolbar shadow
        // for bottom toolbar doesn't get clipped
        view.addSubview(overKeyboardContainer)

        if isSwipingTabsEnabled {
            // Add Homepage to view hierarchy so it is possible to take screenshot from it
            showEmbeddedHomepage(inline: false, isPrivate: false)
            browserDelegate?.setHomepageVisibility(isVisible: false)
            addressBarPanGestureHandler?.homepageScreenshotToolProvider = { [weak self] in
                return self?.browserDelegate?.homepageScreenshotTool()
            }
        }
    }

    private func enqueueTabRestoration() {
        guard isDeeplinkOpening == false else { return }

        if let sessionData = OldTabSessionStore.shared.getSessionData(for: windowUUID),
           !sessionData.isEmpty {
            tabManager.restore(sessionData, clearPrivateTabs: shouldClearPrivateTabs(), tabDisplayType: .TabGrid)
            OldTabSessionStore.shared.clearSessionData(for: windowUUID)
        } else {
            tabManager.selectTab(tabManager.addTab())
        }
    }

    private func shouldClearPrivateTabs() -> Bool {
        return !PrivateBrowsingManager.shared.isPrivateBrowsingEnabled
    }

    func setupConstraints() {
        topTouchArea.snp.makeConstraints { make in
            make.top.left.right.equalTo(view)
            topTouchAreaHeightConstraint = make.height.equalTo(BrowserViewControllerUX.ShowHeaderTapAreaHeight).constraint
        }

        contentContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)

            if isToolbarRefactorEnabled {
                make.top.equalTo(header.snp.bottom)
                make.bottom.equalTo(bottomContainer.snp.top)
            } else {
                make.top.equalTo(legacyUrlBar?.snp.bottom ?? header.snp.bottom)
                make.bottom.equalTo(bottomContainer.snp.top)
            }
        }

        header.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalTo(view)
        }

        bottomContentStackView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(view)
            make.top.equalTo(bottomContainer.snp.bottom)
        }

        bottomContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        overKeyboardContainer.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(view)
        }

        if isSwipingTabsEnabled, isToolbarRefactorEnabled {
            webPagePreview.snp.makeConstraints { make in
                make.edges.equalTo(view)
            }
        }
    }

    private func setupNotifications() {
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onReduceTransparencyStatusDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onDownloadProgressDidChange),
            name: .DownloadProgressChanged,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(onDownloadDidFinish),
            name: .DownloadDidFinish,
            object: nil)
    }

    deinit {
        unsubscribeFromRedux()
        notificationCenter.removeObserver(self)
    }

    @objc
    private func onDownloadProgressDidChange(_ notification: Notification) {
        guard let notiWindowUUID = notification.userInfo?["windowUUID"] as? String,
              notiWindowUUID == self.windowUUID.uuidString else {return}
        self.downloadToast?.updateProgress(notification)
    }

    @objc
    private func onDownloadDidFinish(_ notification: Notification) {
        guard let notiWindowUUID = notification.userInfo?["windowUUID"] as? String,
              notiWindowUUID == self.windowUUID.uuidString else {return}
        self.downloadToast?.dismiss(true)
        self.stopDownload(buttonPressed: true)
    }

    @objc
    private func onReduceTransparencyStatusDidChange(_ notification: Notification) {
        updateBlurViews()

        store.dispatchLegacy(
            ToolbarAction(
                isTranslucent: toolbarHelper.shouldBlur(),
                windowUUID: windowUUID,
                actionType: ToolbarActionType.translucencyDidChange
            )
        )
    }

    // TODO: FXIOS-12632 Refactor how we determine when to hide / show toolbar
    /// If we are showing the homepage search bar, then we should hide the address toolbar
    private func shouldHideToolbar() -> Bool {
        let shouldShowSearchBar = store.state.screenState(
            HomepageState.self,
            for: .homepage,
            window: windowUUID
        )?.searchState.shouldShowSearchBar ?? false
        guard shouldShowSearchBar else { return false }
        return true
    }



    // MARK: - Private browsing

    private func updatePrivateBrowsingLogos() {
        guard let tab = tabManager.selectedTab else { return }

        if tab.isPrivate {
            // If we're in private mode, update the logo to use the private browsing one
            urlBarView.locationView.updateSearchEngineImage(isPrivate: true)
        } else {
            urlBarView.locationView.updateSearchEngineImage(isPrivate: false)
        }
    }

    func updateBlurViews() {
        let isTranslucent = toolbarHelper.shouldBlur()
        urlBarView.updateBlurredBackground(isTranslucent: isTranslucent)
        bottomContainer.updateBlurredBackground(isTranslucent: isTranslucent)
    }

    // MARK: - Keyboard shortcuts

    override var keyCommands: [UIKeyCommand]? {
        let searchLocationCommands = [
            UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(focusLocationTextField), discoverabilityTitle: .KeyboardShortcuts.SelectLocationBar),
            UIKeyCommand(input: "k", modifierFlags: .command, action: #selector(focusLocationTextField), discoverabilityTitle: .KeyboardShortcuts.SelectLocationBar),
        ]

        let navigationCommands = [
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(reload), discoverabilityTitle: .KeyboardShortcuts.ReloadPage),
            UIKeyCommand(input: "[", modifierFlags: .command, action: #selector(goBack), discoverabilityTitle: .KeyboardShortcuts.Back),
            UIKeyCommand(input: "]", modifierFlags: .command, action: #selector(goForward), discoverabilityTitle: .KeyboardShortcuts.Forward),

            UIKeyCommand(input: "f", modifierFlags: .command, action: #selector(findInPage), discoverabilityTitle: .KeyboardShortcuts.Find),
            UIKeyCommand(input: "g", modifierFlags: [.command, .shift], action: #selector(findPrevious), discoverabilityTitle: .KeyboardShortcuts.FindPrevious),
            UIKeyCommand(input: "g", modifierFlags: .command, action: #selector(findNext), discoverabilityTitle: .KeyboardShortcuts.FindNext),
        ]

        let tabCommands = [
            UIKeyCommand(input: "t", modifierFlags: .command, action: #selector(newTab), discoverabilityTitle: .KeyboardShortcuts.NewTab),
            UIKeyCommand(input: "t", modifierFlags: [.command, .shift], action: #selector(newPrivateTab), discoverabilityTitle: .KeyboardShortcuts.NewPrivateTab),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(closeTab), discoverabilityTitle: .KeyboardShortcuts.CloseTab),
            UIKeyCommand(input: "w", modifierFlags: [.command, .shift], action: #selector(undoCloseTab), discoverabilityTitle: .KeyboardShortcuts.ReopenClosedTab),
            UIKeyCommand(input: "\t", modifierFlags: .control, action: #selector(nextTab), discoverabilityTitle: .KeyboardShortcuts.ShowNextTab),
            UIKeyCommand(input: "\t", modifierFlags: [.control, .shift], action: #selector(previousTab), discoverabilityTitle: .KeyboardShortcuts.ShowPreviousTab),
        ]

        let tabNumberCommands = (1...9).map { num in
            UIKeyCommand(input: String(num), modifierFlags: .command, action: #selector(selectTabAtIndex(_:)), discoverabilityTitle: String(format: .KeyboardShortcuts.SelectTab, num))
        }

        let miscCommands = [
            UIKeyCommand(input: "d", modifierFlags: .command, action: #selector(addBookmark), discoverabilityTitle: .KeyboardShortcuts.AddBookmark),
            UIKeyCommand(input: "i", modifierFlags: [.command, .shift], action: #selector(openPrivateBrowsing), discoverabilityTitle: .KeyboardShortcuts.PrivateBrowsingMode),
            UIKeyCommand(input: "\\", modifierFlags: [.command, .shift], action: #selector(showTabTray), discoverabilityTitle: .KeyboardShortcuts.ShowTabTray),
        ]

        return searchLocationCommands + navigationCommands + tabCommands + tabNumberCommands + miscCommands
    }

    @objc
    private func focusLocationTextField() {
        scrollController.showToolbars(animated: true)
        urlBarView.tabLocationViewDidTapLocation(urlBarView.locationView)
    }

    @objc
    private func newTab() {
        openBlankNewTab(focusLocationField: true)
    }

    @objc
    private func newPrivateTab() {
        openBlankNewTab(focusLocationField: true, isPrivate: true)
    }

    @objc
    private func closeTab() {
        guard let currentTab = tabManager.selectedTab else { return }
        tabManager.removeTab(currentTab)
    }

    @objc
    private func undoCloseTab() {
        let restoredTab = tabManager.undoCloseTab()
        if restoredTab != nil {
            LegacyTabTrayTelemetry.recordEvent(.reopenClosedTab)
        }
    }

    @objc
    private func nextTab() {
        guard let currentTab = tabManager.selectedTab else { return }
        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index + 1 < tabs.count {
            tabManager.selectTab(tabs[index + 1])
        } else if let firstTab = tabs.first {
            tabManager.selectTab(firstTab)
        }
    }

    @objc
    private func previousTab() {
        guard let currentTab = tabManager.selectedTab else { return }
        let tabs = currentTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        if let index = tabs.firstIndex(of: currentTab), index - 1 >= 0 {
            tabManager.selectTab(tabs[index - 1])
        } else if let lastTab = tabs.last {
            tabManager.selectTab(lastTab)
        }
    }

    @objc
    private func selectTabAtIndex(_ sender: UIKeyCommand) {
        guard let input = sender.input, let index = Int(input) else { return }
        let tabs = tabManager.selectedTab?.isPrivate == true ? tabManager.privateTabs : tabManager.normalTabs

        if index <= tabs.count {
            tabManager.selectTab(tabs[index - 1])
        }
    }

    @objc
    private func reload() {
        tabManager.selectedTab?.reload()
    }

    @objc
    private func goBack() {
        tabManager.selectedTab?.goBack()
    }

    @objc
    private func goForward() {
        tabManager.selectedTab?.goForward()
    }

    @objc
    private func findInPage() {
        updateFindInPageVisibility(visible: true)
    }

    @objc
    private func findNext() {
        findInPageBar?.findNext()
    }

    @objc
    private func findPrevious() {
        findInPageBar?.findPrevious()
    }

    @objc
    private func addBookmark() {
        guard let tab = tabManager.selectedTab,
              let url = tab.canonicalURL?.displayURL,
              !url.isLocal else { return }

        let bookmarkUrl = url.absoluteString
        let bookmarkTitle = tab.title ?? ""
        profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID,
                                      url: bookmarkUrl,
                                      title: bookmarkTitle)

        var userData = [QuickActionInfos.tabURLKey: bookmarkUrl]
        if !bookmarkTitle.isEmpty {
            userData[QuickActionInfos.tabTitleKey] = bookmarkTitle
        }
        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)
        showBookmarkToast(urlString: bookmarkUrl, action: .add)
    }

    @objc
    private func openPrivateBrowsing() {
        // For now, open a new private tab. In the future, this might switch to the private browsing tab tray.
        openBlankNewTab(focusLocationField: true, isPrivate: true)
    }

    @objc
    private func showTabTray() {
        showTabTray()
    }

    // MARK: - TopTabsDelegate

    func topTabsDidPressTabs() {
        showTabTray()
    }

    func topTabsDidPressNewTab(_ isPrivate: Bool) {
        let isPrivate = PrivateBrowsingManager.shared.isPrivateBrowsingEnabled
        if let homePageURL = NewTabAccessors.getHomePage(profile.prefs), homePageURL.isWebPage(), !isPrivate,
           NewTabAccessors.getNewTabPage(profile.prefs) == .blankPage || NewTabAccessors.getNewTabPage(profile.prefs) == .customURL,
           let url = homePageURL {
            openBlankNewTab(focusLocationField: false, isPrivate: isPrivate)
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: url) as URLRequest)
        } else {
            openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
            overlayManager.openNewTab(url: nil, newTabSettings: newTabSettings)
        }
    }

    func topTabsDidLongPressNewTab(button: UIButton) {
        presentNewTabLongPressActionSheet(from: button)
    }

    func topTabsDidChangeTab() {
        // Only for iPad leave overlay mode on tab change
        overlayManager.switchTab(shouldCancelLoading: true)
        updateZoomPageBarVisibility(visible: false)
    }

    func topTabsDidPressPrivateMode() {
        updateZoomPageBarVisibility(visible: false)
    }

    func topTabsShowCloseTabsToast() {
        showToast(message: .TabsTray.CloseTabsToast.SingleTabTitle, toastAction: .closeTab)
    }
}

extension BrowserViewController: DevicePickerViewControllerDelegate, InstructionsViewDelegate {
    func dismissInstructionsView() {
        self.navigationController?.presentedViewController?.dismiss(animated: true)
        self.popToBVC()
    }

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        self.popToBVC()
    }

    func devicePickerViewController(
        _ devicePickerViewController: DevicePickerViewController,
        didPickDevices devices: [RemoteDevice]
    ) {
        guard let shareItem = devicePickerViewController.shareItem else { return }

        guard shareItem.isShareable else {
            let alert = UIAlertController(
                title: .SendToErrorTitle,
                message: .SendToErrorMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: .SendToErrorOKButton,
                style: .default
            ) { _ in self.popToBVC() })
            present(alert, animated: true, completion: nil)
            return
        }
        profile.sendItem(shareItem, toDevices: devices).uponQueue(.main) { _ in
            self.popToBVC()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SimpleToast().showAlertWithText(.LegacyAppMenu.AppMenuTabSentConfirmMessage,
                                                bottomContainer: self.contentContainer,
                                                theme: self.currentTheme())
            }
        }
    }
}

extension BrowserViewController {
    func trackStartupTelemetry() {
        let toolbarLocation: SearchBarPosition = self.isBottomSearchBar ? .bottom : .top
        SearchBarSettingsViewModel.recordLocationTelemetry(for: toolbarLocation)
        trackAccessibility()
        trackNotificationPermission()
        appStartupTelemetry.sendStartupTelemetry()
        creditCardInitialSetupTelemetry()
    }

    func trackAccessibility() {
        typealias Key = TelemetryWrapper.EventExtraKey
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .voiceOver,
            object: .app,
            extras: [Key.isVoiceOverRunning.rawValue: UIAccessibility.isVoiceOverRunning.description]
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .switchControl,
            object: .app,
            extras: [Key.isSwitchControlRunning.rawValue: UIAccessibility.isSwitchControlRunning.description]
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceTransparency,
            object: .app,
            extras: [Key.isReduceTransparencyEnabled.rawValue: UIAccessibility.isReduceTransparencyEnabled.description]
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceMotion,
            object: .app,
            extras: [Key.isReduceMotionEnabled.rawValue: UIAccessibility.isReduceMotionEnabled.description]
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .invertColors,
            object: .app,
            extras: [Key.isInvertColorsEnabled.rawValue: UIAccessibility.isInvertColorsEnabled.description]
        )

        ensureMainThread {
            let a11yEnabled = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory.description
            let a11yCategory = UIApplication.shared.preferredContentSizeCategory.rawValue.description
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .dynamicTextSize,
                object: .app,
                extras: [Key.isAccessibilitySizeEnabled.rawValue: a11yEnabled,
                         Key.preferredContentSizeCategory.rawValue: a11yCategory]
            )
        }
    }

    func trackNotificationPermission() {
        NotificationManager().getNotificationSettings(sendTelemetry: true) { _ in }
    }
}