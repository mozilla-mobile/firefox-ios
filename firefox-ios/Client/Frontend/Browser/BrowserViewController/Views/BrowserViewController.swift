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
import ComponentLibrary
import Redux
import ToolbarKit

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import struct MozillaAppServices.EncryptedLogin
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
                             NavigationToolbarContainerDelegate,
                             AddressToolbarContainerDelegate,
                             FeatureFlaggable {
    private enum UX {
        static let ShowHeaderTapAreaHeight: CGFloat = 32
        static let ActionSheetTitleMaxLength = 120
    }

    /// Describes the state of the current search session. This state is used
    /// to record search engagement and abandonment telemetry.
    enum SearchSessionState {
        /// The user is currently searching. The URL bar's text field
        /// is focused, but the search controller may be hidden if the
        /// text field is empty.
        case active

        /// The user completed their search by navigating to a destination,
        /// either by tapping on a suggestion, or by entering a search term
        /// or a URL.
        case engaged

        /// The user abandoned their search by dismissing the URL bar.
        case abandoned
    }

    typealias SubscriberStateType = BrowserViewControllerState

    private let KVOs: [KVOConstants] = [
        .estimatedProgress,
        .loading,
        .canGoBack,
        .canGoForward,
        .URL,
        .title,
        .hasOnlySecureContent
    ]

    weak var browserDelegate: BrowserDelegate?
    weak var navigationHandler: BrowserNavigationHandler?

    private(set) lazy var addressToolbarContainer: AddressToolbarContainer = .build()
    var urlBar: URLBarView!

    var urlBarHeightConstraint: Constraint!
    var clipboardBarDisplayHandler: ClipboardBarDisplayHandler?
    var readerModeBar: ReaderModeBarView?
    var readerModeCache: ReaderModeCache
    var statusBarOverlay: StatusBarOverlay = .build { _ in }
    var searchController: SearchViewController?
    var searchSessionState: SearchSessionState?
    var screenshotHelper: ScreenshotHelper!
    var searchTelemetry: SearchTelemetry?
    var searchLoader: SearchLoader?
    var findInPageBar: FindInPageBar?
    var zoomPageBar: ZoomPageBar?
    var microsurvey: MicrosurveyPromptView?
    lazy var mailtoLinkHandler = MailtoLinkHandler()
    var urlFromAnotherApp: UrlToOpenModel?
    var isCrashAlertShowing = false
    var currentMiddleButtonState: MiddleButtonState?
    var passBookHelper: OpenPassBookHelper?
    var overlayManager: OverlayModeManager
    var appAuthenticator: AppAuthenticationProtocol
    var toolbarContextHintVC: ContextualHintViewController
    var dataClearanceContextHintVC: ContextualHintViewController
    var navigationContextHintVC: ContextualHintViewController
    let shoppingContextHintVC: ContextualHintViewController
    var windowUUID: WindowUUID { return tabManager.windowUUID }
    var currentWindowUUID: UUID? { return windowUUID }
    private var observedWebViews = WeakList<WKWebView>()

    // MARK: Telemetry Variables
    var webviewTelemetry = WebViewLoadMeasurementTelemetry()
    var privateBrowsingTelemetry = PrivateBrowsingTelemetry()
    var appStartupTelemetry = AppStartupTelemetry()

    // popover rotation handling
    var displayedPopoverController: UIViewController?
    var updateDisplayedPopoverProperties: (() -> Void)?

    // location label actions
    var pasteGoAction: AccessibleAction!
    var pasteAction: AccessibleAction!
    var copyAddressAction: AccessibleAction!

    var navigationHintDoubleTapTimer: Timer?

    var tabTrayViewController: TabTrayController?

    let profile: Profile
    let tabManager: TabManager
    let ratingPromptManager: RatingPromptManager
    var isToolbarRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
    }
    var isUnifiedSearchEnabled: Bool {
        return featureFlags.isFeatureEnabled(.unifiedSearch, checking: .buildOnly)
    }
    var isOneTapNewTabEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarOneTapNewTab, checking: .buildOnly)
    }
    var isToolbarNavigationHintEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarNavigationHint, checking: .buildOnly)
    }

    var isNativeErrorPageEnabled: Bool {
        return featureFlags.isFeatureEnabled(.nativeErrorPage, checking: .buildOnly)
    }

    /// Temporary flag for showing no internet connection native error page only.
    var isNICErrorPageEnabled: Bool {
        return featureFlags.isFeatureEnabled(.noInternetConnectionErrorPage, checking: .buildOnly)
    }

    private var browserViewControllerState: BrowserViewControllerState?

    // Header stack view can contain the top url bar, top reader mode, top ZoomPageBar
    var header: BaseAlphaStackView = .build { _ in }

    // OverKeyboardContainer stack view contains
    // the bottom reader mode, the bottom url bar and the ZoomPageBar
    var overKeyboardContainer: BaseAlphaStackView = .build { _ in }

    // Overlay dimming view for private mode
    lazy var privateModeDimmingView: UIView = .build { view in
        view.backgroundColor = self.currentTheme().colors.layerScrim
        view.accessibilityIdentifier = AccessibilityIdentifiers.PrivateMode.dimmingView
    }

    // BottomContainer stack view contains toolbar
    var bottomContainer: BaseAlphaStackView = .build { _ in }

    // Alert content that appears on top of the content
    // ex: Find In Page, SnackBars
    var bottomContentStackView: BaseAlphaStackView = .build { stackview in
        stackview.isClearBackground = true
    }

    // The content stack view contains the contentContainer with homepage or browser and the shopping sidebar
    var contentStackView: SidebarEnabledView = .build()

    // The content container contains the homepage, error page or webview. Embedded by the coordinator.
    var contentContainer: ContentContainer = .build { _ in }

    lazy var isBottomSearchBar: Bool = {
        guard isSearchBarLocationFeatureEnabled else { return false }
        return searchBarPosition == .bottom
    }()

    private lazy var topTouchArea: UIButton = .build { topTouchArea in
        topTouchArea.isAccessibilityElement = false
        topTouchArea.addTarget(self, action: #selector(self.tappedTopArea), for: .touchUpInside)
    }

    var topTabsVisible: Bool {
        return topTabsViewController != nil
    }
    // Window helper used for displaying an opaque background for private tabs.
    private lazy var privacyWindowHelper = PrivacyWindowHelper()
    var keyboardBackdrop: UIView?

    lazy var scrollController = TabScrollingController(
        windowUUID: windowUUID,
        isPullToRefreshRefactorEnabled: featureFlags.isFeatureEnabled(
            .pullToRefreshRefactor,
            checking: .buildOnly
        )
    )
    private var keyboardState: KeyboardState?
    var pendingToast: Toast? // A toast that might be waiting for BVC to appear before displaying
    var downloadToast: DownloadToast? // A toast that is showing the combined download progress

    // Tracking navigation items to record history types.
    // TODO: weak references?
    var ignoredNavigation = Set<WKNavigation>()
    var typedNavigation = [WKNavigation: VisitType]()

    private lazy var navigationToolbarContainer: NavigationToolbarContainer = .build { view in
        view.windowUUID = self.windowUUID
    }
    lazy var toolbar = TabToolbar()
    var navigationToolbar: TabToolbarProtocol {
        return toolbar.isHidden ? urlBar : toolbar
    }

    var topTabsViewController: TopTabsViewController?

    // Keep track of allowed `URLRequest`s from `webView(_:decidePolicyFor:decisionHandler:)` so
    // that we can obtain the originating `URLRequest` when a `URLResponse` is received. This will
    // allow us to re-trigger the `URLRequest` if the user requests a file to be downloaded.
    var pendingRequests = [String: URLRequest]()

    // This is set when the user taps "Download Link" from the context menu. We then force a
    // download of the next request through the `WKNavigationDelegate` that matches this web view.
    weak var pendingDownloadWebView: WKWebView?

    let downloadQueue: DownloadQueue

    private var keyboardPressesHandlerValue: Any?

    var themeManager: ThemeManager
    var notificationCenter: NotificationProtocol
    var themeObserver: NSObjectProtocol?

    var logger: Logger

    var newTabSettings: NewTabPage {
        return NewTabAccessors.getNewTabPage(profile.prefs)
    }

    @available(iOS 13.4, *)
    func keyboardPressesHandler() -> KeyboardPressesHandler {
        if let existingHandler = keyboardPressesHandlerValue as? KeyboardPressesHandler {
            return existingHandler
        } else {
            let newHandler = KeyboardPressesHandler()
            keyboardPressesHandlerValue = newHandler
            return newHandler
        }
    }

    init(
        profile: Profile,
        tabManager: TabManager,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        ratingPromptManager: RatingPromptManager = AppContainer.shared.resolve(),
        downloadQueue: DownloadQueue = AppContainer.shared.resolve(),
        logger: Logger = DefaultLogger.shared,
        appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()
    ) {
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.ratingPromptManager = ratingPromptManager
        self.readerModeCache = DiskReaderModeCache.sharedInstance
        self.downloadQueue = downloadQueue
        self.logger = logger
        self.appAuthenticator = appAuthenticator
        self.overlayManager = DefaultOverlayModeManager()
        let windowUUID = tabManager.windowUUID
        let contextualViewProvider = ContextualHintViewProvider(forHintType: .toolbarLocation,
                                                                with: profile)
        self.toolbarContextHintVC = ContextualHintViewController(with: contextualViewProvider,
                                                                 windowUUID: windowUUID)
        let shoppingViewProvider = ContextualHintViewProvider(forHintType: .shoppingExperience,
                                                              with: profile)
        shoppingContextHintVC = ContextualHintViewController(with: shoppingViewProvider,
                                                             windowUUID: windowUUID)
        let dataClearanceViewProvider = ContextualHintViewProvider(
            forHintType: .dataClearance,
            with: profile
        )
        self.dataClearanceContextHintVC = ContextualHintViewController(with: dataClearanceViewProvider,
                                                                       windowUUID: windowUUID)

        let navigationViewProvider = ContextualHintViewProvider(forHintType: .navigation, with: profile)

        self.navigationContextHintVC = ContextualHintViewController(with: navigationViewProvider, windowUUID: windowUUID)

        super.init(nibName: nil, bundle: nil)
        didInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        logger.log("BVC deallocating", level: .info, category: .lifecycle)
        unsubscribeFromRedux()
        observedWebViews.forEach({ stopObserving(webView: $0) })
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

    fileprivate func didInit() {
        screenshotHelper = ScreenshotHelper(controller: self)
        tabManager.addDelegate(self)
        tabManager.addNavigationDelegate(self)
        downloadQueue.addDelegate(self)
        let tabWindowUUID = tabManager.windowUUID
        AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(tabWindowUUID)]) { [weak self] in
            // Ensure we call into didBecomeActive at least once during startup flow (if needed)
            guard !AppEventQueue.activityIsCompleted(.browserUpdatedForAppActivation(tabWindowUUID)) else { return }
            self?.browserDidBecomeActive()
        }
    }

    @objc
    private func didAddPendingBlobDownloadToQueue() {
        pendingDownloadWebView = nil
    }

    /// If user manually opens the keyboard and presses undo, the app switches to the last
    /// open tab, and because of that we need to leave overlay state
    @objc
    func didTapUndoCloseAllTabToast(notification: Notification) {
        guard windowUUID == notification.windowUUID else { return }
        overlayManager.switchTab(shouldCancelLoading: true)
    }

    @objc
    func didFinishAnnouncement(notification: Notification) {
        if let userInfo = notification.userInfo,
            let announcementText =  userInfo[UIAccessibility.announcementStringValueUserInfoKey] as? String {
            let saveSuccessMessage: String = .CreditCard.RememberCreditCard.CreditCardSaveSuccessToastMessage
            let updateSuccessMessage: String = .CreditCard.UpdateCreditCard.CreditCardUpdateSuccessToastMessage
            if announcementText == saveSuccessMessage || announcementText == updateSuccessMessage {
                UIAccessibility.post(
                    notification: .layoutChanged,
                    argument: self.tabManager.selectedTab?.currentWebView()
                )
            }
        }
    }

    @objc
    func searchBarPositionDidChange(notification: Notification) {
        guard let dict = notification.object as? NSDictionary,
              let newSearchBarPosition = dict[PrefsKeys.FeatureFlags.SearchBarPosition] as? SearchBarPosition,
              (!isToolbarRefactorEnabled && urlBar != nil) || isToolbarRefactorEnabled
        else { return }

        let searchBarView: TopBottomInterchangeable = isToolbarRefactorEnabled ? addressToolbarContainer : urlBar
        let newPositionIsBottom = newSearchBarPosition == .bottom
        let newParent = newPositionIsBottom ? overKeyboardContainer : header
        searchBarView.removeFromParent()
        searchBarView.addToParent(parent: newParent)

        if let readerModeBar = readerModeBar {
            readerModeBar.removeFromParent()
            readerModeBar.addToParent(parent: newParent, addToTop: newSearchBarPosition == .bottom)
        }

        isBottomSearchBar = newPositionIsBottom
        updateViewConstraints()
        updateHeaderConstraints()
        toolbar.setNeedsDisplay()
        searchBarView.updateConstraints()
        updateMicrosurveyConstraints()

        let action = GeneralBrowserMiddlewareAction(
            scrollOffset: scrollController.contentOffset,
            toolbarPosition: newSearchBarPosition,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.toolbarPositionChanged)
        store.dispatch(action)
    }

    @objc
    fileprivate func appMenuBadgeUpdate() {
        let isActionNeeded = RustFirefoxAccounts.shared.isActionNeeded
        let showWarningBadge = isActionNeeded

        if isToolbarRefactorEnabled {
            let action = ToolbarAction(
                showMenuWarningBadge: showWarningBadge,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.showMenuWarningBadge
            )
            store.dispatch(action)
        } else {
            urlBar.warningMenuBadge(setVisible: showWarningBadge)
            toolbar.warningMenuBadge(setVisible: showWarningBadge)
        }
    }

    func updateToolbarStateForTraitCollection(_ newCollection: UITraitCollection) {
        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: newCollection)
        let showTopTabs = ToolbarHelper().shouldShowTopTabs(for: newCollection)

        switchToolbarIfNeeded()

        if isToolbarRefactorEnabled {
            if showNavToolbar {
                navigationToolbarContainer.isHidden = false
                navigationToolbarContainer.applyTheme(theme: currentTheme())
                updateTabCountUsingTabManager(self.tabManager)
            } else {
                navigationToolbarContainer.isHidden = true
            }

            updateToolbarStateTraitCollectionIfNecessary(newCollection)
        } else {
            urlBar.topTabsIsShowing = showTopTabs
            urlBar.setShowToolbar(!showNavToolbar)

            if showNavToolbar {
                toolbar.isHidden = false
                toolbar.tabToolbarDelegate = self
                toolbar.applyUIMode(
                    isPrivate: tabManager.selectedTab?.isPrivate ?? false,
                    theme: currentTheme()
                )
                toolbar.applyTheme(theme: currentTheme())
                handleMiddleButtonState(currentMiddleButtonState ?? .search)
                updateTabCountUsingTabManager(self.tabManager)
            } else {
                toolbar.tabToolbarDelegate = nil
                toolbar.isHidden = true
            }
        }

        appMenuBadgeUpdate()

        if showTopTabs, topTabsViewController == nil {
            let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
            topTabsViewController.delegate = self
            addChild(topTabsViewController)
            header.addArrangedViewToTop(topTabsViewController.view)
            self.topTabsViewController = topTabsViewController
            topTabsViewController.applyTheme()
        } else if showTopTabs, topTabsViewController != nil {
            topTabsViewController?.applyTheme()
        } else {
            if let topTabsView = topTabsViewController?.view {
                header.removeArrangedView(topTabsView)
            }
            topTabsViewController?.removeFromParent()
            topTabsViewController = nil
        }

        header.setNeedsLayout()
        view.layoutSubviews()

        if let tab = tabManager.selectedTab,
           let webView = tab.webView,
           !isToolbarRefactorEnabled {
            updateURLBarDisplayURL(tab)
            navigationToolbar.updateBackStatus(webView.canGoBack)
            navigationToolbar.updateForwardStatus(webView.canGoForward)
        }
    }

    func dismissVisibleMenus() {
        displayedPopoverController?.dismiss(animated: true)
        if self.presentedViewController as? PhotonActionSheet != nil {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    @objc
    func appDidEnterBackgroundNotification() {
        displayedPopoverController?.dismiss(animated: false) {
            self.updateDisplayedPopoverProperties = nil
            self.displayedPopoverController = nil
        }
        if self.presentedViewController as? PhotonActionSheet != nil {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        // Formerly these calls were run during AppDelegate.didEnterBackground(), but we have
        // individual TabManager instances for each BVC, so we perform these here instead.
        tabManager.preserveTabs()
        logTelemetryForAppDidEnterBackground()
    }

    @objc
    func tappedTopArea() {
        scrollController.showToolbars(animated: true)
    }

    @objc
    func sceneDidEnterBackgroundNotification(notification: Notification) {
        // Ensure the notification is for the current window scene
        guard let currentWindowScene = view.window?.windowScene,
              let notificationWindowScene = notification.object as? UIWindowScene,
              currentWindowScene === notificationWindowScene else { return }
        guard canShowPrivacyWindow else { return }

        privacyWindowHelper.showWindow(windowScene: currentWindowScene, withThemedColor: currentTheme().colors.layer3)
    }

    @objc
    func sceneDidActivateNotification() {
        privacyWindowHelper.removeWindow()
    }

    @objc
    func appWillResignActiveNotification() {
        // Dismiss any popovers that might be visible
        displayedPopoverController?.dismiss(animated: false) {
            self.updateDisplayedPopoverProperties = nil
            self.displayedPopoverController = nil
        }

        guard canShowPrivacyWindow else { return }
        privacyWindowHelper.showWindow(windowScene: view.window?.windowScene, withThemedColor: currentTheme().colors.layer3)
    }

    private var canShowPrivacyWindow: Bool {
        // Ensure the selected tab is private and determine if the privacy window can be shown.
        guard let privateTab = tabManager.selectedTab, privateTab.isPrivate else { return false }
        // Show privacy window if no view controller is presented
        // or if the presented view is a PhotonActionSheet.
        return self.presentedViewController == nil || presentedViewController is PhotonActionSheet
    }

    @objc
    func appDidBecomeActiveNotification() {
        privacyWindowHelper.removeWindow()

        if let tab = tabManager.selectedTab, !tab.isFindInPageMode {
            // Re-show toolbar which might have been hidden during scrolling (prior to app moving into the background)
            scrollController.showToolbars(animated: false)
        }

        browserDidBecomeActive()
    }

    func browserDidBecomeActive() {
        let uuid = tabManager.windowUUID
        AppEventQueue.started(.browserUpdatedForAppActivation(uuid))
        defer { AppEventQueue.completed(.browserUpdatedForAppActivation(uuid)) }

        nightModeUpdates()

        // Update lock icon without redrawing the whole locationView
        if let tab = tabManager.selectedTab, !isToolbarRefactorEnabled {
            // It appears this was added to fix an issue with the lock icon, so we're
            // calling into this for some kind of beneficial side effect. We should
            // probably explore a different solution; tab content blocking does not
            // change every time the app is brought forward. [FXIOS-10091]
            urlBar.locationView.tabDidChangeContentBlocking(tab)
        }

        dismissModalsIfStartAtHome()
    }

    private func nightModeUpdates() {
        if NightModeHelper.isActivated(),
           !featureFlags.isFeatureEnabled(.nightMode, checking: .buildOnly) {
            NightModeHelper.turnOff()
            themeManager.applyThemeUpdatesToWindows()
        }

        NightModeHelper.cleanNightModeDefaults()
    }

    private func dismissModalsIfStartAtHome() {
        guard tabManager.startAtHomeCheck() else { return }
        let action = FakespotAction(isOpen: false,
                                    windowUUID: windowUUID,
                                    actionType: FakespotActionType.setAppearanceTo)
        store.dispatch(action)

        guard presentedViewController != nil else { return }
        dismissVC()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .browserViewController)
        store.dispatch(action)

        let browserAction = GeneralBrowserMiddlewareAction(
            toolbarPosition: searchBarPosition,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.browserDidLoad)
        store.dispatch(browserAction)

        let uuid = self.windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return BrowserViewControllerState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .browserViewController)
        store.dispatch(action)
        // Note: actual `store.unsubscribe()` is not strictly needed; Redux uses weak subscribers
    }

    func newState(state: BrowserViewControllerState) {
        browserViewControllerState = state

        // opens or close sidebar/bottom sheet to match the saved state
        if state.fakespotState.isOpen {
            let productURL = isToolbarRefactorEnabled ?
                store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)?.addressToolbar.url :
                urlBar.currentURL
            guard let productURL else { return }
            handleFakespotFlow(productURL: productURL)
        } else if !state.fakespotState.isOpen {
            dismissFakespotIfNeeded()
        }

        if state.reloadWebView {
            updateContentInHomePanel(state.browserViewType)
        }

        setupMiddleButtonStatus(isLoading: false)

        if let toast = state.toast {
            self.showToastType(toast: toast)
        }

        if state.showOverlay == true {
            overlayManager.openNewTab(url: nil, newTabSettings: newTabSettings)
        } else if state.showOverlay == false {
            overlayManager.cancelEditing(shouldCancelLoading: false)
        }

        executeNavigationAndDisplayActions()

        handleMicrosurvey(state: state)
    }

    private func showToastType(toast: ToastType) {
        switch toast {
        case .addShortcut,
                .addToReadingList,
                .removeShortcut,
                .removeFromReadingList,
                .addBookmark:
            SimpleToast().showAlertWithText(
                toast.title,
                bottomContainer: contentContainer,
                theme: currentTheme()
            )
        default:
            let viewModel = ButtonToastViewModel(
                labelText: toast.title,
                buttonText: toast.buttonText)
            let uuid = windowUUID
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: currentTheme(),
                                    completion: { buttonPressed in
                if let action = toast.reduxAction(for: uuid), buttonPressed {
                    store.dispatch(action)
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
        KeyboardHelper.defaultHelper.addDelegate(self)
        trackTelemetry()
        setupNotifications()
        addSubviews()
        listenForThemeChange(view)
        setupAccessibleActions()

        clipboardBarDisplayHandler = ClipboardBarDisplayHandler(prefs: profile.prefs, tabManager: tabManager)
        clipboardBarDisplayHandler?.delegate = self

        navigationToolbarContainer.toolbarDelegate = self

        scrollController.header = header
        scrollController.overKeyboardContainer = overKeyboardContainer
        scrollController.bottomContainer = bottomContainer

        updateToolbarStateForTraitCollection(traitCollection)

        setupConstraints()

        // Setup UIDropInteraction to handle dragging and dropping
        // links into the view from other apps.
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        searchTelemetry = SearchTelemetry(tabManager: tabManager)

        // Awesomebar Location Telemetry
        SearchBarSettingsViewModel.recordLocationTelemetry(for: isBottomSearchBar ? .bottom : .top)

        overlayManager.setURLBar(urlBarView: isToolbarRefactorEnabled ? addressToolbarContainer : urlBar)

        // Update theme of already existing views
        let theme = currentTheme()
        header.applyTheme(theme: theme)
        overKeyboardContainer.applyTheme(theme: theme)
        bottomContainer.applyTheme(theme: theme)
        bottomContentStackView.applyTheme(theme: theme)
        statusBarOverlay.hasTopTabs = ToolbarHelper().shouldShowTopTabs(for: traitCollection)
        statusBarOverlay.applyTheme(theme: theme)

        // Feature flag for credit card until we fully enable this feature
        let autofillCreditCardStatus = featureFlags.isFeatureEnabled(
            .creditCardAutofillStatus, checking: .buildOnly)
        // We need to update autofill status on sync manager as there could be delay from nimbus
        // in getting the value. When the delay happens the credit cards might not sync
        // as the default value is false
        profile.syncManager.updateCreditCardAutofillStatus(value: autofillCreditCardStatus)
        // Credit card initial setup telemetry
        creditCardInitialSetupTelemetry()

        // Send settings telemetry for Fakespot
        FakespotUtils().addSettingTelemetry()

        subscribeToRedux()
    }

    private func setupAccessibleActions() {
        // UIAccessibilityCustomAction subclass holding an AccessibleAction instance does not work,
        // thus unable to generate AccessibleActions and UIAccessibilityCustomActions "on-demand" and need
        // to make them "persistent" e.g. by being stored in BVC
        pasteGoAction = AccessibleAction(name: .PasteAndGoTitle, handler: { [weak self] () -> Bool in
            guard let self, let pasteboardContents = UIPasteboard.general.string else { return false }
            if isToolbarRefactorEnabled {
                openBrowser(searchTerm: pasteboardContents)
            } else {
                urlBar(urlBar, didSubmitText: pasteboardContents)
            }
            searchController?.searchTelemetry?.interactionType = .pasted
            return true
        })
        pasteAction = AccessibleAction(name: .PasteTitle, handler: {  [weak self] () -> Bool in
            guard let self, let pasteboardContents = UIPasteboard.general.string else { return false }
            // Enter overlay mode and make the search controller appear.
            overlayManager.openSearch(with: pasteboardContents)
            searchController?.searchTelemetry?.interactionType = .pasted
            return true
        })
        copyAddressAction = AccessibleAction(name: .CopyAddressTitle, handler: { [weak self] () -> Bool in
            guard let self else { return false }
            let fallbackURL = isToolbarRefactorEnabled ? tabManager.selectedTab?.currentURL() : urlBar.currentURL
            if let url = tabManager.selectedTab?.canonicalURL?.displayURL ?? fallbackURL {
                UIPasteboard.general.url = url
            }
            return true
        })
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
            selector: #selector(sceneDidEnterBackgroundNotification),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(sceneDidActivateNotification),
            name: UIScene.didActivateNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(appMenuBadgeUpdate),
            name: .FirefoxAccountStateChange,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(searchBarPositionDidChange),
            name: .SearchBarPositionDidChange,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(didTapUndoCloseAllTabToast),
            name: .DidTapUndoCloseAllTabToast,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(didFinishAnnouncement),
            name: UIAccessibility.announcementDidFinishNotification,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(didAddPendingBlobDownloadToQueue),
            name: .PendingBlobDownloadAddedToQueue,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(updateForDefaultSearchEngineDidChange),
            name: .SearchSettingsDidUpdateDefaultSearchEngine,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(handlePageZoomLevelUpdated),
            name: .PageZoomLevelUpdated,
            object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(openRecentlyClosedTabs),
            name: .RemoteTabNotificationTapped,
            object: nil
        )
    }

    private func switchToolbarIfNeeded() {
        var updateNeeded = false

        // FXIOS-10210 Temporary to support updating the Unified Search feature flag during runtime
        if isToolbarRefactorEnabled {
            addressToolbarContainer.isUnifiedSearchEnabled = isUnifiedSearchEnabled
        }

        if isToolbarRefactorEnabled, addressToolbarContainer.superview == nil {
            // Show toolbar refactor
            updateNeeded = true
            overKeyboardContainer.removeArrangedView(urlBar, animated: false)
            header.removeArrangedView(urlBar, animated: false)
            bottomContainer.removeArrangedView(toolbar, animated: false)

            addAddressToolbar()
        } else if !isToolbarRefactorEnabled && (urlBar == nil || urlBar.superview == nil) {
            // Show legacy toolbars
            updateNeeded = true

            overKeyboardContainer.removeArrangedView(addressToolbarContainer, animated: false)
            header.removeArrangedView(addressToolbarContainer, animated: false)
            bottomContainer.removeArrangedView(navigationToolbarContainer, animated: false)

            createLegacyUrlBar()

            urlBar.snp.makeConstraints { make in
                urlBarHeightConstraint = make.height.equalTo(UIConstants.TopToolbarHeightMax).constraint
            }
        }

        if updateNeeded {
            let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar
            bottomContainer.addArrangedViewToBottom(toolbarToShow, animated: false)
            overlayManager.setURLBar(urlBarView: isToolbarRefactorEnabled ? addressToolbarContainer : urlBar)
            updateToolbarStateForTraitCollection(traitCollection)
            updateViewConstraints()
        }
    }

    private func createLegacyUrlBar() {
        guard !isToolbarRefactorEnabled else { return }

        urlBar = URLBarView(profile: profile, windowUUID: windowUUID)
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        urlBar.tabToolbarDelegate = self
        urlBar.applyTheme(theme: currentTheme())
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: currentTheme())
        urlBar.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)
    }

    private func addAddressToolbar() {
        guard isToolbarRefactorEnabled else { return }

        addressToolbarContainer.configure(
            windowUUID: windowUUID,
            profile: profile,
            delegate: self,
            isUnifiedSearchEnabled: isUnifiedSearchEnabled
        )
        addressToolbarContainer.applyTheme(theme: currentTheme())
        addressToolbarContainer.addToParent(parent: isBottomSearchBar ? overKeyboardContainer : header)
    }

    func addSubviews() {
        view.addSubviews(contentStackView)

        contentStackView.addArrangedSubview(contentContainer)

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
        view.addSubview(overKeyboardContainer)

        let toolbarToShow = isToolbarRefactorEnabled ? navigationToolbarContainer : toolbar

        bottomContainer.addArrangedSubview(toolbarToShow)
        view.addSubview(bottomContainer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Note: `restoreTabs()` returns early if `tabs` is not-empty; repeated calls should have no effect.
        tabManager.restoreTabs()

        switchToolbarIfNeeded()
        updateTabCountUsingTabManager(tabManager, animated: false)

        if !isToolbarRefactorEnabled {
            urlBar.searchEnginesDidUpdate()
        }

        updateToolbarStateForTraitCollection(traitCollection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let toast = self.pendingToast {
            self.pendingToast = nil
            show(toast: toast, afterWaiting: ButtonToast.UX.delay)
        }
        showQueuedAlertIfAvailable()

        prepareURLOnboardingContextualHint()

        browserDelegate?.browserHasLoaded()
        AppEventQueue.signal(event: .browserIsReady)
    }

    private func prepareURLOnboardingContextualHint() {
        guard toolbarContextHintVC.shouldPresentHint(),
              featureFlags.isFeatureEnabled(.isToolbarCFREnabled, checking: .buildOnly)
        else { return }

        toolbarContextHintVC.configure(
            anchor: isToolbarRefactorEnabled ? addressToolbarContainer : urlBar,
            withArrowDirection: isBottomSearchBar ? .down : .up,
            andDelegate: self,
            presentedUsing: { [weak self] in self?.presentContextualHint() },
            andActionForButton: { [weak self] in self?.homePanelDidRequestToOpenSettings(at: .toolbar) },
            overlayState: overlayManager)
    }

    private func presentContextualHint() {
        if IntroScreenManager(prefs: profile.prefs).shouldShowIntroScreen { return }
        present(toolbarContextHintVC, animated: true)

        UIAccessibility.post(notification: .layoutChanged, argument: toolbarContextHintVC)
    }

    func willNavigateAway() {
        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Remove existing constraints
        statusBarOverlay.removeConstraints(statusBarOverlay.constraints)

        // Set new constraints for the statusBarOverlay
        NSLayoutConstraint.activate([
            statusBarOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarOverlay.heightAnchor.constraint(equalToConstant: view.safeAreaInsets.top)
        ])

        // Ensure the layout is updated immediately
        view.layoutIfNeeded()

        // TODO: [FXIOS-10334] Needs investigation. Dequeuing JS alerts as part of subview layout is problematic.
        showQueuedAlertIfAvailable()
        switchToolbarIfNeeded()
        adjustURLBarHeightBasedOnLocationViewHeight()
    }

    private func adjustURLBarHeightBasedOnLocationViewHeight() {
        guard isToolbarRefactorEnabled else {
            adjustLegacyURLBarHeightBasedOnLocationViewHeight()
            return
        }

        // Adjustment for landscape on the urlbar
        // need to account for inset and remove it when keyboard is showing
        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection)
        let isKeyboardShowing = keyboardState != nil

        if !showNavToolbar && isBottomSearchBar && !isKeyboardShowing {
            overKeyboardContainer.addBottomInsetSpacer(spacerHeight: UIConstants.BottomInset)
        } else {
            overKeyboardContainer.removeBottomInsetSpacer()
        }
    }

    private func adjustLegacyURLBarHeightBasedOnLocationViewHeight() {
        // Make sure that we have a height to actually base our calculations on
        guard !isToolbarRefactorEnabled, urlBar.locationContainer.bounds.height != 0 else { return }
        let locationViewHeight = urlBar.locationView.bounds.height
        let heightWithPadding = locationViewHeight + UIConstants.ToolbarPadding

        // Adjustment for landscape on the urlbar
        // need to account for inset and remove it when keyboard is showing
        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection)
        let isKeyboardShowing = keyboardState != nil

        if !showNavToolbar && isBottomSearchBar &&
        !isKeyboardShowing && UIDevice.current.orientation.isLandscape {
            overKeyboardContainer.addBottomInsetSpacer(spacerHeight: UIConstants.BottomInset)
        } else {
            overKeyboardContainer.removeBottomInsetSpacer()
        }

        urlBarHeightConstraint.update(offset: heightWithPadding)
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.willTransition(to: newCollection, with: coordinator)

        // During split screen launching on iPad, this callback gets fired before viewDidLoad gets a chance to
        // set things up. Make sure to only update the toolbar state if the view is ready for it.
        if isViewLoaded {
            updateToolbarStateForTraitCollection(newCollection)
        }

        displayedPopoverController?.dismiss(animated: true, completion: nil)
        coordinator.animate(alongsideTransition: { context in
            self.scrollController.showToolbars(animated: false)
        }, completion: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        dismissVisibleMenus()

        var fakespotNeedsUpdate = false
        if !isToolbarRefactorEnabled, urlBar.currentURL != nil {
            fakespotNeedsUpdate = contentStackView.isSidebarVisible != FakespotUtils().shouldDisplayInSidebar(
                viewSize: size
            )
            if let fakespotState = browserViewControllerState?.fakespotState {
                fakespotNeedsUpdate = fakespotNeedsUpdate && fakespotState.isOpen
            }

            if fakespotNeedsUpdate {
                dismissFakespotIfNeeded(animated: false)
            }
        }

        coordinator.animate(alongsideTransition: { [self] context in
            scrollController.updateMinimumZoom()
            topTabsViewController?.scrollToCurrentTab(false, centerCell: false)
            if let popover = displayedPopoverController {
                updateDisplayedPopoverProperties?()
                present(popover, animated: true, completion: nil)
            }

            let productURL = isToolbarRefactorEnabled ?
            store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID)?.addressToolbar.url :
            urlBar.currentURL

            if let productURL, fakespotNeedsUpdate {
                handleFakespotFlow(productURL: productURL)
            }
        }, completion: { _ in
            self.scrollController.traitCollectionDidChange()
            self.scrollController.setMinimumZoom()
        })
        microsurvey?.setNeedsUpdateConstraints()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateToolbarStateForTraitCollection(traitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            themeManager.applyThemeUpdatesToWindows()
        }
        setupMiddleButtonStatus(isLoading: false)

        // Everything works fine on iPad orientation switch (because CFR remains anchored to the same button),
        // so only necessary to dismiss when vertical size class changes
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            if dataClearanceContextHintVC.isPresenting {
                dataClearanceContextHintVC.dismiss(animated: true)
            }
            if navigationContextHintVC.isPresenting {
                navigationContextHintVC.dismiss(animated: true)
            }
        }
    }

    // MARK: - Constraints

    private func setupConstraints() {
        if !isToolbarRefactorEnabled {
            urlBar.snp.makeConstraints { make in
                urlBarHeightConstraint = make.height.equalTo(UIConstants.TopToolbarHeightMax).constraint
            }
        }

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: header.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: overKeyboardContainer.topAnchor),
        ])

        updateHeaderConstraints()
    }

    private func updateHeaderConstraints() {
        header.snp.remakeConstraints { make in
            if isBottomSearchBar {
                make.left.right.equalTo(view)
                make.top.equalTo(view.safeArea.top)
                // The status bar is covered by the statusBarOverlay,
                // if we don't have the URL bar at the top then header height is 0
                make.height.equalTo(0)
            } else {
                scrollController.headerTopConstraint = make.top.equalTo(view.safeArea.top).constraint
                make.left.right.equalTo(view)
            }
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        NSLayoutConstraint.activate([
            topTouchArea.topAnchor.constraint(equalTo: view.topAnchor),
            topTouchArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topTouchArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topTouchArea.heightAnchor.constraint(equalToConstant: isBottomSearchBar ? 0 : UX.ShowHeaderTapAreaHeight)
        ])

        readerModeBar?.snp.remakeConstraints { make in
            make.height.equalTo(UIConstants.ToolbarHeight)
        }

        // Setup the bottom toolbar
        if !isToolbarRefactorEnabled {
            toolbar.snp.remakeConstraints { make in
                make.height.equalTo(UIConstants.BottomToolbarHeight)
            }
        }

        overKeyboardContainer.snp.remakeConstraints { make in
            scrollController.overKeyboardContainerConstraint = make.bottom.equalTo(bottomContainer.snp.top).constraint
            if !isBottomSearchBar, zoomPageBar != nil {
                make.height.greaterThanOrEqualTo(0)
            } else if !isBottomSearchBar {
                make.height.equalTo(0)
            }
            make.leading.trailing.equalTo(view)
        }

        bottomContainer.snp.remakeConstraints { make in
            scrollController.bottomContainerConstraint = make.bottom.equalTo(view.snp.bottom).constraint
            make.leading.trailing.equalTo(view)
        }

        bottomContentStackView.snp.remakeConstraints { remake in
            adjustBottomContentStackView(remake)
        }

        if let tab = tabManager.selectedTab, tab.isFindInPageMode {
            scrollController.hideToolbars(animated: true, isFindInPageMode: true)
        } else {
            adjustBottomSearchBarForKeyboard()
        }
    }

    private func adjustBottomContentStackView(_ remake: ConstraintMaker) {
        remake.left.equalTo(view.safeArea.left)
        remake.right.equalTo(view.safeArea.right)
        remake.centerX.equalTo(view)
        remake.width.equalTo(view.safeArea.width)

        // Height is set by content - this removes run time error
        remake.height.greaterThanOrEqualTo(0)
        bottomContentStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        if isBottomSearchBar {
            adjustBottomContentBottomSearchBar(remake)
        } else {
            adjustBottomContentTopSearchBar(remake)
        }
    }

    private func adjustBottomContentTopSearchBar(_ remake: ConstraintMaker) {
        if let keyboardHeight = keyboardState?.intersectionHeightForView(view), keyboardHeight > 0 {
            remake.bottom.equalTo(view).offset(-keyboardHeight)
        } else if !toolbar.isHidden {
            remake.bottom.lessThanOrEqualTo(overKeyboardContainer.snp.top)
            remake.bottom.lessThanOrEqualTo(view.safeArea.bottom)
        } else {
            remake.bottom.equalTo(view.safeArea.bottom)
        }
    }

    private func adjustBottomContentBottomSearchBar(_ remake: ConstraintMaker) {
        remake.bottom.lessThanOrEqualTo(overKeyboardContainer.snp.top)
        remake.bottom.lessThanOrEqualTo(view.safeArea.bottom)
    }

    private func adjustBottomSearchBarForKeyboard() {
        guard isBottomSearchBar,
              let keyboardHeight = keyboardState?.intersectionHeightForView(view), keyboardHeight > 0
        else {
            overKeyboardContainer.removeKeyboardSpacer()
            return
        }

        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection)
        let toolBarHeight = showNavToolbar ? UIConstants.BottomToolbarHeight : 0
        let spacerHeight = keyboardHeight - toolBarHeight
        overKeyboardContainer.addKeyboardSpacer(spacerHeight: spacerHeight)
    }

    fileprivate func showQueuedAlertIfAvailable() {
        if let queuedAlertInfo = tabManager.selectedTab?.dequeueJavascriptAlertPrompt() {
            let alertController = queuedAlertInfo.alertController()
            alertController.delegate = self
            present(alertController, animated: true, completion: nil)
        }
    }

    func resetBrowserChrome() {
        // animate and reset transform for tab chrome
        if !isToolbarRefactorEnabled {
            urlBar.updateAlphaForSubviews(1)
            toolbar.isHidden = false
        }

        [header, overKeyboardContainer].forEach { view in
            view?.transform = .identity
        }
    }

    // MARK: - Manage embedded content

    func frontEmbeddedContent(_ viewController: ContentContainable) {
        contentContainer.update(content: viewController)
        statusBarOverlay.resetState(isHomepage: contentContainer.hasLegacyHomepage)
    }

    /// Embed a ContentContainable inside the content container
    /// - Parameter viewController: the view controller to embed inside the content container
    /// - Returns: True when the content was successfully embedded
    func embedContent(_ viewController: ContentContainable) -> Bool {
        guard contentContainer.canAdd(content: viewController) else { return false }

        addChild(viewController)
        viewController.willMove(toParent: self)
        contentContainer.add(content: viewController)
        viewController.didMove(toParent: self)
        statusBarOverlay.resetState(isHomepage: contentContainer.hasLegacyHomepage)

        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
        return true
    }

    /// Show the home page embedded in the contentContainer
    /// - Parameter inline: Inline is true when the homepage is created from the tab tray, a long press
    /// on the tab bar to open a new tab or by pressing the home page button on the tab bar. Inline is false when
    /// it's the zero search page, aka when the home page is shown by clicking the url bar from a loaded web page.
    func showEmbeddedHomepage(inline: Bool, isPrivate: Bool) {
        resetDataClearanceCFRTimer()

        if isPrivate && featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
            browserDelegate?.showPrivateHomepage(overlayManager: overlayManager)
            return
        }

        hideReaderModeBar(animated: false)

        // Make sure reload button is hidden on homepage
        if !isToolbarRefactorEnabled {
            urlBar.locationView.reloadButton.reloadButtonState = .disabled
        }

        if featureFlags.isFeatureEnabled(.homepageRebuild, checking: .buildOnly) {
            browserDelegate?.showHomepage()
        } else {
            browserDelegate?.showLegacyHomepage(
                inline: inline,
                toastContainer: contentContainer,
                homepanelDelegate: self,
                libraryPanelDelegate: self,
                statusBarScrollDelegate: statusBarOverlay,
                overlayManager: overlayManager
            )
        }
    }

    func showEmbeddedWebview() {
        // Make sure reload button is working when showing webview
        if !isToolbarRefactorEnabled {
            urlBar.locationView.reloadButton.reloadButtonState = .reload
        }

        guard let selectedTab = tabManager.selectedTab,
              let webView = selectedTab.webView else {
            logger.log("Webview of selected tab was not available", level: .debug, category: .lifecycle)
            return
        }

        if webView.url == nil {
            // The web view can go gray if it was zombified due to memory pressure.
            // When this happens, the URL is nil, so try restoring the page upon selection.
            logger.log("Webview was zombified, reloading before showing", level: .debug, category: .lifecycle)
            selectedTab.reload()
        }

        browserDelegate?.show(webView: webView)
    }

    // MARK: - Microsurvey
    private func setupMicrosurvey() {
        guard featureFlags.isFeatureEnabled(.microsurvey, checking: .buildOnly), microsurvey == nil else { return }

        store.dispatch(
            MicrosurveyPromptAction(windowUUID: windowUUID, actionType: MicrosurveyPromptActionType.showPrompt)
        )
    }

    private func updateMicrosurveyConstraints() {
        guard let microsurvey else { return }

        microsurvey.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(microsurvey)

        if isBottomSearchBar {
            overKeyboardContainer.addArrangedViewToTop(microsurvey, animated: false, completion: {
                self.view.layoutIfNeeded()
            })
        } else {
            bottomContainer.addArrangedViewToTop(microsurvey, animated: false, completion: {
                self.view.layoutIfNeeded()
            })
        }

        microsurvey.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))

        updateBarBordersForMicrosurvey()
        updateViewConstraints()
    }

    // Update border to hide when microsurvey is shown so that
    // it appears to belong the app and harder to spoof
    private func updateBarBordersForMicrosurvey() {
        // TODO: FXIOS-9503 Update for Toolbar Redesign
        guard !shouldUseiPadSetup(), !isToolbarRefactorEnabled else { return }
        let hasMicrosurvery = microsurvey != nil

        if let urlBar, isBottomSearchBar {
            urlBar.isMicrosurveyShown = hasMicrosurvery
            urlBar.updateTopBorderDisplay()
        }
        toolbar.isMicrosurveyShown = hasMicrosurvery
        toolbar.setNeedsDisplay()
    }

    private func createMicrosurveyPrompt(with state: MicrosurveyPromptState) {
        self.microsurvey = MicrosurveyPromptView(
            state: state,
            windowUUID: windowUUID,
            inOverlayMode: overlayManager.inOverlayMode
        )
        updateMicrosurveyConstraints()
    }

    private func removeMicrosurveyPrompt() {
        guard let microsurvey else { return }

        if isBottomSearchBar {
            overKeyboardContainer.removeArrangedView(microsurvey)
        } else {
            bottomContainer.removeArrangedView(microsurvey)
        }

        self.microsurvey = nil
        updateBarBordersForMicrosurvey()
        updateViewConstraints()
    }

    // MARK: - Native Error Page

    func showEmbeddedNativeErrorPage() {
    // TODO: FXIOS-9641 #21239 Implement Redux for Native Error Pages
        browserDelegate?.showNativeErrorPage(overlayManager: overlayManager)
    }

    // MARK: - Update content

    func updateContentInHomePanel(_ browserViewType: BrowserViewType) {
        logger.log("Update content on browser view controller with type \(browserViewType)",
                   level: .info,
                   category: .coordinator)

        switch browserViewType {
        case .normalHomepage:
            showEmbeddedHomepage(inline: true, isPrivate: false)
        case .privateHomepage:
            showEmbeddedHomepage(inline: true, isPrivate: true)
        case .webview:
            showEmbeddedWebview()
            if !isToolbarRefactorEnabled {
                urlBar.locationView.reloadButton.isHidden = false
            }
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            topTabsViewController?.refreshTabs()
        }
        setupMicrosurvey()
    }

    func updateInContentHomePanel(_ url: URL?, focusUrlBar: Bool = false) {
        let isAboutHomeURL = url.flatMap { InternalURL($0)?.isAboutHomeURL } ?? false

        let isErrorURL = url.flatMap { InternalURL($0)?.isErrorPage } ?? false

        guard url != nil else {
            showEmbeddedWebview()
            if !isToolbarRefactorEnabled {
                urlBar.locationView.reloadButton.reloadButtonState = .disabled
            }
            return
        }

        /// Used for checking if current error code is for no internet connection
        let isNICErrorCode = url?.absoluteString.contains(String(Int(
            CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue))) ?? false

        if isAboutHomeURL {
            showEmbeddedHomepage(inline: true, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
        } else if isErrorURL && isNativeErrorPageEnabled {
            showEmbeddedNativeErrorPage()
        } else if isNICErrorCode && isNICErrorPageEnabled {
            showEmbeddedNativeErrorPage()
        } else {
            showEmbeddedWebview()
            if !isToolbarRefactorEnabled {
                urlBar.locationView.reloadButton.isHidden = false
            }
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            topTabsViewController?.refreshTabs()
        }
        setupMicrosurvey()
    }

    func showLibrary(panel: LibraryPanelType) {
        DispatchQueue.main.async {
            self.navigationHandler?.show(homepanelSection: panel.homepanelSection)
        }
    }

    fileprivate func createSearchControllerIfNeeded() {
        guard self.searchController == nil else { return }

        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        let searchViewModel = SearchViewModel(isPrivate: isPrivate,
                                              isBottomSearchBar: isBottomSearchBar,
                                              profile: profile,
                                              model: profile.searchEnginesManager,
                                              tabManager: tabManager)
        let searchController = SearchViewController(profile: profile,
                                                    viewModel: searchViewModel,
                                                    tabManager: tabManager)
        searchViewModel.searchEnginesManager = profile.searchEnginesManager
        searchController.searchDelegate = self

        let searchLoader = SearchLoader(
            profile: profile,
            autocompleteView: isToolbarRefactorEnabled ? addressToolbarContainer : urlBar)
        searchLoader.addListener(searchViewModel)
        self.searchLoader = searchLoader

        self.searchController = searchController
        self.searchSessionState = .active
    }

    func showSearchController() {
        createSearchControllerIfNeeded()

        guard let searchController = self.searchController else { return }

        // This needs to be added to ensure during animation of the keyboard,
        // No content is showing in between the bottom search bar and the searchViewController
        if isBottomSearchBar, keyboardBackdrop == nil {
            keyboardBackdrop = UIView()
            keyboardBackdrop?.backgroundColor = currentTheme().colors.layer1
            view.insertSubview(keyboardBackdrop!, belowSubview: overKeyboardContainer)
            keyboardBackdrop?.snp.makeConstraints { make in
                make.edges.equalTo(view)
            }
            view.bringSubviewToFront(bottomContainer)
        }

        addChild(searchController)
        view.addSubview(searchController.view)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false

        let constraintTarget = isBottomSearchBar ? overKeyboardContainer.topAnchor : view.bottomAnchor
        NSLayoutConstraint.activate([
            searchController.view.topAnchor.constraint(equalTo: header.bottomAnchor),
            searchController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchController.view.bottomAnchor.constraint(equalTo: constraintTarget)
        ])

        searchController.didMove(toParent: self)
    }

    func hideSearchController() {
        privateModeDimmingView.removeFromSuperview()
        guard let searchController = self.searchController else { return }
        searchController.willMove(toParent: nil)
        searchController.view.removeFromSuperview()
        searchController.removeFromParent()

        keyboardBackdrop?.removeFromSuperview()
        keyboardBackdrop = nil
    }

    func destroySearchController() {
        hideSearchController()

        searchController = nil
        searchSessionState = nil
        searchLoader = nil
    }

    func finishEditingAndSubmit(_ url: URL, visitType: VisitType, forTab tab: Tab) {
        if !isToolbarRefactorEnabled {
            urlBar.currentURL = url
        }
        overlayManager.finishEditing(shouldCancelLoading: false)

        if let nav = tab.loadRequest(URLRequest(url: url)) {
            self.recordNavigationInTab(tab, navigation: nav, visitType: visitType)
        }
    }

    func addBookmark(url: String, title: String? = nil) {
        var title = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            title = url
        }

        let shareItem = ShareItem(url: url, title: title)
        // Add new mobile bookmark at the top of the list
        profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID,
                                      url: shareItem.url,
                                      title: shareItem.title,
                                      position: 0)

        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }
        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)

        showBookmarkToast(action: .add)
    }

    func removeBookmark(url: URL, title: String?) {
        profile.places.deleteBookmarksWithURL(url: url.absoluteString).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            self.showBookmarkToast(bookmarkURL: url, title: title, action: .remove)
        }
    }

    private func showBookmarkToast(bookmarkURL: URL? = nil, title: String? = nil, action: BookmarkAction) {
        switch action {
        case .add:
            self.showToast(message: .LegacyAppMenu.AddBookmarkConfirmMessage, toastAction: .bookmarkPage)
        case .remove:
            self.showToast(
                bookmarkURL,
                title,
                message: .LegacyAppMenu.RemoveBookmarkConfirmMessage,
                toastAction: .removeBookmark
            )
        }
    }

    /// This function will open a view separate from the bookmark edit panel found in the
    /// Library Panel - Bookmarks section. In order to get the correct information, it needs
    /// to fetch the last added bookmark in the mobile folder, which is the default
    /// location for all bookmarks added on mobile.
    internal func openBookmarkEditPanel() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .change,
            object: .bookmark,
            value: .addBookmarkToast
        )
        if profile.isShutdown { return }
        profile.places.getBookmarksTree(
            rootGUID: BookmarkRoots.MobileFolderGUID,
            recursive: false
        ).uponQueue(.main) { result in
            guard let bookmarkFolder = result.successValue as? BookmarkFolderData,
                  let bookmarkNode = bookmarkFolder.children?.first as? FxBookmarkNode
            else { return }

            let detailController = LegacyBookmarkDetailPanel(profile: self.profile,
                                                             windowUUID: self.windowUUID,
                                                             bookmarkNode: bookmarkNode,
                                                             parentBookmarkFolder: bookmarkFolder,
                                                             presentedFromToast: true) { [weak self] in
                self?.showBookmarkToast(action: .remove)
            }
            let controller: DismissableNavigationViewController
            controller = DismissableNavigationViewController(rootViewController: detailController)
            self.present(controller, animated: true, completion: nil)
        }
    }

    override func accessibilityPerformMagicTap() -> Bool {
        if isToolbarRefactorEnabled {
            let action = GeneralBrowserAction(
                windowUUID: windowUUID,
                actionType: GeneralBrowserActionType.showReaderMode
            )
            store.dispatch(action)
            return true
        } else if !urlBar.locationView.readerModeButton.isHidden {
            self.urlBar.tabLocationViewDidTapReaderMode(self.urlBar.locationView)
            return true
        }
        return false
    }

    override func accessibilityPerformEscape() -> Bool {
        if overlayManager.inOverlayMode {
            overlayManager.cancelEditing(shouldCancelLoading: true)
            return true
        } else if let selectedTab = tabManager.selectedTab, selectedTab.canGoBack {
            selectedTab.goBack()
            return true
        }
        return false
    }

    func setupLoadingSpinnerFor(_ webView: WKWebView, isLoading: Bool) {
        if isLoading {
            webView.scrollView.refreshControl?.beginRefreshing()
        } else {
            webView.scrollView.refreshControl?.endRefreshing()
        }
    }

    func setupMiddleButtonStatus(isLoading: Bool) {
        // Setting the default state to search to account for no tab or starting page tab
        // `state` will be modified later if needed
        let state: MiddleButtonState = .search

        // No tab
        guard let tab = tabManager.selectedTab else {
            if !isToolbarRefactorEnabled {
                urlBar.locationView.reloadButton.reloadButtonState = .disabled
            }
            handleMiddleButtonState(state)
            currentMiddleButtonState = state
            return
        }

        // Tab with starting page
        if tab.isURLStartingPage {
            if !isToolbarRefactorEnabled {
                urlBar.locationView.reloadButton.reloadButtonState = .disabled
            }
            handleMiddleButtonState(state)
            currentMiddleButtonState = state
            return
        }

        handleMiddleButtonState(.home)
        if !isToolbarRefactorEnabled {
            urlBar.locationView.reloadButton.reloadButtonState = isLoading ? .stop : .reload
        }
        currentMiddleButtonState = state
    }

    private func handleMiddleButtonState(_ state: MiddleButtonState) {
        let showDataClearanceFlow = browserViewControllerState?.showDataClearanceFlow ?? false
        let showFireButton = featureFlags.isFeatureEnabled(
            .feltPrivacyFeltDeletion,
            checking: .buildOnly
        ) && showDataClearanceFlow
        guard !showFireButton else {
            if !isToolbarRefactorEnabled {
                navigationToolbar.updateMiddleButtonState(.fire)
                configureDataClearanceContextualHint(navigationToolbar.multiStateButton)
            }
            return
        }
        resetDataClearanceCFRTimer()

        if !isToolbarRefactorEnabled {
            navigationToolbar.updateMiddleButtonState(state)
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let webView = object as? WKWebView,
              let tab = tabManager[webView]
        else { return }

        guard let kp = keyPath,
              let path = KVOConstants(rawValue: kp)
        else {
            logger.log("BVC observeValue webpage unhandled KVO",
                       level: .info,
                       category: .webview,
                       description: "Unhandled KVO key: \(keyPath ?? "nil")")
            return
        }

        switch path {
        case .estimatedProgress:
            guard tab === tabManager.selectedTab else { break }
            if let url = webView.url, !InternalURL.isValid(url: url) {
                if isToolbarRefactorEnabled {
                    addressToolbarContainer.updateProgressBar(progress: webView.estimatedProgress)
                } else {
                    urlBar.updateProgressBar(Float(webView.estimatedProgress))
                }
                setupMiddleButtonStatus(isLoading: true)
            } else {
                if isToolbarRefactorEnabled {
                    addressToolbarContainer.hideProgressBar()
                } else {
                    urlBar.hideProgressBar()
                }
                setupMiddleButtonStatus(isLoading: false)
            }
        case .loading:
            guard let loading = change?[.newKey] as? Bool else { break }
            setupMiddleButtonStatus(isLoading: loading)
            setupLoadingSpinnerFor(webView, isLoading: loading)

            if isToolbarRefactorEnabled {
                let action = ToolbarAction(
                    isLoading: loading,
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.websiteLoadingStateDidChange
                )
                store.dispatch(action)
            }

        case .URL:
            // Special case for "about:blank" popups, if the webView.url is nil, keep the tab url as "about:blank"
            if tab.url?.absoluteString == "about:blank" && webView.url == nil {
                break
            }

            // Ensure we do have a URL from that observer
            guard let url = webView.url else { return }

            // To prevent spoofing, only change the URL immediately if the new URL is on
            // the same origin as the current URL. Otherwise, do nothing and wait for
            // didCommitNavigation to confirm the page load.
            if tab.url?.origin == url.origin {
                tab.url = url

                if tab === tabManager.selectedTab {
                    updateUIForReaderHomeStateForTab(tab)
                }
                // Catch history pushState navigation, but ONLY for same origin navigation,
                // for reasons above about URL spoofing risk.
                navigateInTab(tab: tab, webViewStatus: .url)
            }
        case .title:
            // Ensure that the tab title *actually* changed to prevent repeated calls
            // to navigateInTab(tab:) except when ReaderModeState is active
            // so that evaluateJavascriptInDefaultContentWorld() is called.
            guard let title = tab.title else { break }
            if !title.isEmpty {
                if title != tab.lastTitle {
                    tab.lastTitle = title
                    navigateInTab(tab: tab, webViewStatus: .title)
                } else {
                    navigateIfReaderModeActive(currentTab: tab)
                }
            }
            TelemetryWrapper.recordEvent(category: .action, method: .navigate, object: .tab)
        case .canGoBack:
            guard tab === tabManager.selectedTab,
                  let canGoBack = change?[.newKey] as? Bool
            else { break }
            if isToolbarRefactorEnabled {
                dispatchBackForwardToolbarAction(canGoBack: canGoBack, windowUUID: windowUUID)
            } else {
                navigationToolbar.updateBackStatus(canGoBack)
            }
        case .canGoForward:
            guard tab === tabManager.selectedTab,
                  let canGoForward = change?[.newKey] as? Bool
            else { break }
            if isToolbarRefactorEnabled {
                dispatchBackForwardToolbarAction(canGoForward: canGoForward, windowUUID: windowUUID)
            } else {
                navigationToolbar.updateForwardStatus(canGoForward)
            }
        case .hasOnlySecureContent:
            guard let selectedTabURL = tabManager.selectedTab?.url,
                  let webViewURL = webView.url,
                  selectedTabURL == webViewURL else { return }

            if !isToolbarRefactorEnabled {
                urlBar.locationView.hasSecureContent = webView.hasOnlySecureContent
                urlBar.locationView.showTrackingProtectionButton(for: webView.url)
            }
        default:
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
        }
    }

    func updateUIForReaderHomeStateForTab(_ tab: Tab, focusUrlBar: Bool = false) {
        updateURLBarDisplayURL(tab)
        scrollController.showToolbars(animated: false)

        if let url = tab.url {
            if url.isReaderModeURL {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }

            updateInContentHomePanel(url as URL, focusUrlBar: focusUrlBar)
        }
    }

    func updateReaderModeState(for tab: Tab?, readerModeState: ReaderModeState) {
        if isToolbarRefactorEnabled {
            let action = ToolbarAction(
                readerModeState: readerModeState,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.readerModeStateChanged
            )
            store.dispatch(action)
        } else {
            urlBar.updateReaderModeState(readerModeState)
        }
    }

    /// Updates the URL bar text and button states.
    /// Call this whenever the page URL changes.
    fileprivate func updateURLBarDisplayURL(_ tab: Tab) {
        guard !isToolbarRefactorEnabled else {
            var safeListedURLImageName: String? {
                return (tab.contentBlocker?.status == .safelisted) ?
                StandardImageIdentifiers.Small.notificationDotFill : nil
            }

            var lockIconImageName: String?
            var lockIconNeedsTheming = true

            if let hasSecureContent = tab.webView?.hasOnlySecureContent {
                lockIconImageName = hasSecureContent ?
                StandardImageIdentifiers.Large.lockFill :
                StandardImageIdentifiers.Large.lockSlashFill

                let isWebsiteMode = tab.url?.isReaderModeURL == false
                lockIconImageName = isWebsiteMode ? lockIconImageName : nil
                lockIconNeedsTheming = isWebsiteMode ? hasSecureContent : true
            }

            let action = ToolbarAction(
                url: tab.url?.displayURL,
                isPrivate: tab.isPrivate,
                isShowingNavigationToolbar: ToolbarHelper().shouldShowNavigationToolbar(for: traitCollection),
                canGoBack: tab.canGoBack,
                canGoForward: tab.canGoForward,
                lockIconImageName: lockIconImageName,
                lockIconNeedsTheming: lockIconNeedsTheming,
                safeListedURLImageName: safeListedURLImageName,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.urlDidChange)
            store.dispatch(action)

            // update toolbar borders
            let middlewareAction = ToolbarMiddlewareAction(
                scrollOffset: scrollController.contentOffset,
                windowUUID: windowUUID,
                actionType: ToolbarMiddlewareActionType.urlDidChange)
            store.dispatch(middlewareAction)

            return
        }

        if tab == tabManager.selectedTab, let displayUrl = tab.url?.displayURL, urlBar.currentURL != displayUrl {
            let searchData = tab.metadataManager?.tabGroupData ?? LegacyTabGroupData()
            searchData.tabAssociatedNextUrl = displayUrl.absoluteString
            tab.metadataManager?.updateTimerAndObserving(
                state: .tabNavigatedToDifferentUrl,
                searchData: searchData,
                isPrivate: tab.isPrivate)
        }

        urlBar.currentURL = tab.url?.displayURL
        urlBar.locationView.updateShoppingButtonVisibility(for: tab)
        let isPage = tab.url?.displayURL?.isWebPage() ?? false
        navigationToolbar.updatePageStatus(isPage)
    }

    func didSubmitSearchText(_ text: String) {
        guard let currentTab = tabManager.selectedTab else { return }

        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed, forTab: currentTab)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.firstIndex(of: " ") else {
            submitSearchText(text, forTab: currentTab)
            return
        }

        let possibleKeyword = String(trimmedText[..<possibleKeywordQuerySeparatorSpace])
        let possibleQuery = String(trimmedText[trimmedText.index(after: possibleKeywordQuerySeparatorSpace)...])

        profile.places.getBookmarkURLForKeyword(keyword: possibleKeyword).uponQueue(.main) { result in
            if var urlString = result.successValue ?? "",
               let escapedQuery = possibleQuery.addingPercentEncoding(
                withAllowedCharacters: NSCharacterSet.urlQueryAllowed
               ),
               let range = urlString.range(of: "%s") {
                urlString.replaceSubrange(range, with: escapedQuery)

                if let url = URL(string: urlString, invalidCharacters: false) {
                    self.finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: currentTab)
                    return
                }
            }

            self.submitSearchText(text, forTab: currentTab)
        }
    }

    private func executeNavigationAndDisplayActions() {
        guard let state = browserViewControllerState else { return }

        switch state {
        case _ where state.navigateTo != nil:
            handleNavigationActions(for: state)
        case _ where state.displayView != nil:
            handleDisplayActions(for: state)
        case _ where state.navigationDestination != nil:
            guard let destination = state.navigationDestination else { return }
            handleNavigation(to: destination)
        default: break
        }
    }

    private func dispatchBackForwardToolbarAction(canGoBack: Bool? = nil,
                                                  canGoForward: Bool? = nil,
                                                  windowUUID: UUID) {
        guard canGoBack != nil || canGoForward != nil else { return }
        let action = ToolbarAction(canGoBack: canGoBack,
                                   canGoForward: canGoForward,
                                   windowUUID: windowUUID,
                                   actionType: ToolbarActionType.backForwardButtonStateChanged)
        store.dispatch(action)
    }

    private func handleNavigation(to type: NavigationDestination) {
        switch type.destination {
        case .contextMenu:
            navigationHandler?.showContextMenu()
        case .customizeHomepage:
            navigationHandler?.show(settings: .homePage)
        case .link:
            guard let url = type.url else {
                logger.log("url should not be nil when navigating for a link type", level: .warning, category: .coordinator)
                return
            }
            navigationHandler?.navigateFromHomePanel(
                to: url,
                visitType: .link,
                isGoogleTopSite: type.isGoogleTopSite ?? false
            )
        }
    }

    private func handleDisplayActions(for state: BrowserViewControllerState) {
        guard let displayState = state.displayView else { return }

        switch displayState {
        case .qrCodeReader:
            navigationHandler?.showQRCode(delegate: self)
        case .backForwardList:
            navigationHandler?.showBackForwardList()
        case .tabsLongPressActions:
            presentTabsLongPressAction(from: view)
        case .locationViewLongPressAction:
            presentLocationViewActionSheet(from: addressToolbarContainer)
        case .trackingProtectionDetails:
            navigationHandler?.showEnhancedTrackingProtection(sourceView: state.buttonTapped ?? addressToolbarContainer)
        case .menu:
            didTapOnMenu(button: state.buttonTapped)
        case .reloadLongPressAction:
            guard let button = state.buttonTapped else { return }
            presentRefreshLongPressAction(from: button)
        case .tabTray:
            focusOnTabSegment()
        case .share:
            guard let button = state.buttonTapped else { return }
            didTapOnShare(from: button)
        case .readerMode:
            toggleReaderMode()
        case .readerModeLongPressAction:
            _ = toggleReaderModeLongPressAction()
        case .newTabLongPressActions:
            presentNewTabLongPressActionSheet(from: view)
        case .dataClearance:
            didTapOnDataClearance()
        case .passwordGenerator:
            if let tab = tabManager.selectedTab, let frame = state.frame {
                navigationHandler?.showPasswordGenerator(tab: tab, frame: frame)
            }
        }
    }

    private func handleNavigationActions(for state: BrowserViewControllerState) {
        guard let navigationState = state.navigateTo else { return }
        updateZoomPageBarVisibility(visible: false)

        switch navigationState {
        case .home:
            didTapOnHome()
        case .back:
            didTapOnBack()
            startNavigationButtonDoubleTapTimer()
        case .forward:
            didTapOnForward()
            startNavigationButtonDoubleTapTimer()
        case .reloadNoCache:
            tabManager.selectedTab?.reload(bypassCache: true)
        case .reload:
            tabManager.selectedTab?.reload()
        case .stopLoading:
            tabManager.selectedTab?.stop()
        case .newTab:
            topTabsDidPressNewTab(tabManager.selectedTab?.isPrivate ?? false)
        }
    }

    private func navigateIfReaderModeActive(currentTab: Tab) {
        if let readerMode = currentTab.getContentScript(name: ReaderMode.name()) as? ReaderMode {
            if readerMode.state == .active {
                navigateInTab(tab: currentTab, webViewStatus: .title)
            }
        }
    }

    func presentLocationViewActionSheet(from view: UIView) {
        let actions = getLongPressLocationBarActions(with: view, alertContainer: contentContainer)
        guard !actions.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = UIDevice.current.userInterfaceIdiom != .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(
            actions: [actions],
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: style
        )
        presentSheetWith(viewModel: viewModel, on: self, from: view)
    }

    func presentRefreshLongPressAction(from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        let style: UIModalPresentationStyle = !shouldSuppress ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(
            actions: [urlActions],
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: style
        )

        presentSheetWith(viewModel: viewModel, on: self, from: button)
    }

    func presentNewTabLongPressActionSheet(from view: UIView) {
        let actions = getNewTabLongPressActions()

        let shouldPresentAsPopover = ToolbarHelper().shouldShowTopTabs(for: traitCollection)
        let style: UIModalPresentationStyle = shouldPresentAsPopover ? .popover : .overCurrentContext
        let viewModel = PhotonActionSheetViewModel(
            actions: actions,
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: style
        )
        presentSheetWith(viewModel: viewModel, on: self, from: view)
    }

    func didTapOnHome() {
        let shouldUpdateWithRedux = isToolbarRefactorEnabled && browserViewControllerState?.navigateTo == .home
        guard shouldUpdateWithRedux || !isToolbarRefactorEnabled else { return }

        let page = NewTabAccessors.getHomePage(self.profile.prefs)
        if page == .homePage, let homePageURL = HomeButtonHomePageAccessors.getHomePage(self.profile.prefs) {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePageURL) as URLRequest)
        } else if let homePanelURL = page.url {
            tabManager.selectedTab?.loadRequest(PrivilegedRequest(url: homePanelURL) as URLRequest)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .home)
    }

    func didTapOnBack() {
        // This code snippet addresses an issue related to navigation between pages in the same tab FXIOS-7309.
        // Specifically, it checks if the URL bar is not currently focused (`!focusUrlBar`) and if it is
        // operating in an overlay mode (`urlBar.inOverlayMode`).
        dismissUrlBar()
        tabManager.selectedTab?.goBack()
    }

    func didTapOnForward() {
        // This code snippet addresses an issue related to navigation between pages in the same tab FXIOS-7309.
        // Specifically, it checks if the URL bar is not currently focused (`!focusUrlBar`) and if it is
        // operating in an overlay mode (`urlBar.inOverlayMode`).
        dismissUrlBar()
        tabManager.selectedTab?.goForward()
    }

    func didTapOnMenu(button: UIButton?) {
        // Ensure that any keyboards or spinners are dismissed before presenting the menu
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )

        logger.log("Show MainMenu button tapped", level: .info, category: .mainMenu)
        if featureFlags.isFeatureEnabled(.menuRefactor, checking: .buildOnly) {
            navigationHandler?.showMainMenu()
        } else {
            showPhotonMainMenu(from: button)
        }
    }

    func toggleReaderMode() {
        guard let tab = tabManager.selectedTab,
              let readerMode = tab.getContentScript(name: ReaderMode.name()) as? ReaderMode
        else { return }

        switch readerMode.state {
        case .available:
            enableReaderMode()

            if !isToolbarRefactorEnabled {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeOpenButton)
            }
        case .active:
            disableReaderMode()

            if !isToolbarRefactorEnabled {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeCloseButton)
            }
        case .unavailable:
            break
        }
    }

    func toggleReaderModeLongPressAction() -> Bool {
        guard let tab = tabManager.selectedTab,
              let url = tab.url?.displayURL
        else {
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageGeneralErrorAccessibilityLabel
            )

            return false
        }

        let result = profile.readingList.createRecordWithURL(
            url.absoluteString,
            title: tab.title ?? "",
            addedBy: UIDevice.current.name
        )

        switch result.value {
        case .success:
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageSuccessAcessibilityLabel
            )
            SimpleToast().showAlertWithText(.ShareAddToReadingListDone,
                                            bottomContainer: contentContainer,
                                            theme: currentTheme())
        case .failure:
            UIAccessibility.post(
                notification: UIAccessibility.Notification.announcement,
                argument: String.ReaderModeAddPageMaybeExistsErrorAccessibilityLabel
            )
        }

        return true
    }

    private func showPhotonMainMenu(from button: UIButton?) {
        guard let button else { return }

        // Logs homePageMenu or siteMenu depending if HomePage is open or not
        let isHomePage = tabManager.selectedTab?.isFxHomeTab ?? false
        let eventObject: TelemetryWrapper.EventObject = isHomePage ? .homePageMenu : .siteMenu
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: eventObject)
        let menuHelper = MainMenuActionHelper(profile: profile,
                                              tabManager: tabManager,
                                              buttonView: button,
                                              toastContainer: contentContainer)
        menuHelper.delegate = self
        menuHelper.sendToDeviceDelegate = self
        menuHelper.navigationHandler = navigationHandler

        updateZoomPageBarVisibility(visible: false)
        menuHelper.getToolbarActions(navigationController: navigationController) { [weak self] actions in
            guard let self else { return }
            let shouldInverse = PhotonActionSheetViewModel.hasInvertedMainMenu(
                trait: self.traitCollection,
                isBottomSearchBar: self.isBottomSearchBar
            )
            let viewModel = PhotonActionSheetViewModel(
                actions: actions,
                modalStyle: .popover,
                isMainMenu: true,
                isMainMenuInverted: shouldInverse
            )
            if self.profile.prefs.boolForKey(PrefsKeys.PhotonMainMenuShown) == nil {
                self.profile.prefs.setBool(true, forKey: PrefsKeys.PhotonMainMenuShown)
            }
            self.presentSheetWith(viewModel: viewModel, on: self, from: button)
        }
    }

    func didTapOnShare(from view: UIView) {
        if !isToolbarRefactorEnabled {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .awesomebarLocation,
                                         value: .awesomebarShareTap,
                                         extras: nil)
        }

        if let selectedTab = tabManager.selectedTab, let tabUrl = selectedTab.canonicalURL?.displayURL {
            navigationHandler?.showShareExtension(
                url: tabUrl,
                sourceView: view,
                toastContainer: contentContainer,
                popoverArrowDirection: isBottomSearchBar ? .down : .up)
        }
    }

    func presentTabsLongPressAction(from view: UIView) {
        guard presentedViewController == nil else { return }

        var actions: [[PhotonRowActions]] = []
        let useToolbarRefactorLongPressActions = featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly) &&
                                                 featureFlags.isFeatureEnabled(.toolbarOneTapNewTab, checking: .buildOnly)
        if useToolbarRefactorLongPressActions {
            actions = getTabToolbarRefactorLongPressActions()
        } else {
            actions.append(getTabToolbarLongPressActionsForModeSwitching())
            actions.append(getMoreTabToolbarLongPressActions())
        }

        let viewModel = PhotonActionSheetViewModel(
            actions: actions,
            closeButtonTitle: .CloseButtonTitle,
            modalStyle: .overCurrentContext
        )

        presentSheetWith(viewModel: viewModel, on: self, from: view)
    }

    func focusOnTabSegment() {
        let isPrivateTab = tabManager.selectedTab?.isPrivate ?? false
        let segmentToFocus = isPrivateTab ? TabTrayPanelType.privateTabs : TabTrayPanelType.tabs
        showTabTray(focusedSegment: segmentToFocus)
    }

    /// When the trait collection changes the top taps display might have to change
    /// This requires an update of the toolbars.
    private func updateToolbarStateTraitCollectionIfNecessary(_ newCollection: UITraitCollection) {
        let showTopTabs = ToolbarHelper().shouldShowTopTabs(for: newCollection)
        let showNavToolbar = ToolbarHelper().shouldShowNavigationToolbar(for: newCollection)

        // Only dispatch action when the value of top tabs being shown is different from what is saved in the state
        // to avoid having the toolbar re-displayed
        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID),
              toolbarState.isShowingTopTabs != showTopTabs || toolbarState.isShowingNavigationToolbar != showNavToolbar
        else { return }

        let action = ToolbarAction(
            isShowingNavigationToolbar: showNavToolbar,
            isShowingTopTabs: showTopTabs,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.traitCollectionDidChange
        )
        store.dispatch(action)
    }

    // MARK: Opening New Tabs

    /// ⚠️ !! WARNING !! ⚠️
    /// This function opens up x number of new tabs in the background.
    /// This is meant to test memory overflows with tabs on a device.
    /// DO NOT USE unless you're explicitly testing this feature.
    /// It should only be used from the debug menu.
    func debugOpen(numberOfNewTabs: Int?, at url: URL) {
        guard let numberOfNewTabs = numberOfNewTabs,
              numberOfNewTabs > 0
        else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
            let action = TabPanelViewAction(panelType: .tabs,
                                            windowUUID: self.windowUUID,
                                            actionType: TabPanelViewActionType.addNewTab)
            store.dispatch(action)

            self.debugOpen(numberOfNewTabs: numberOfNewTabs - 1, at: url)
        })
    }

    func presentSignInViewController(_ fxaOptions: FxALaunchParams,
                                     flowType: FxAPageType = .emailLoginFlow,
                                     referringPage: ReferringPage = .none) {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        windowManager.postWindowEvent(event: .syncMenuOpened, windowUUID: windowUUID)
        let vcToPresent = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            fxaOptions,
            flowType: flowType,
            referringPage: referringPage,
            profile: profile,
            windowUUID: windowUUID
        )
        (vcToPresent as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = navigationHandler
        presentThemedViewController(navItemLocation: .Left,
                                    navItemText: .Close,
                                    vcBeingPresented: vcToPresent,
                                    topTabsVisible: UIDevice.current.userInterfaceIdiom == .pad)
    }

    func handle(query: String, isPrivate: Bool) {
        openBlankNewTab(focusLocationField: false, isPrivate: isPrivate)
        if isToolbarRefactorEnabled {
            openBrowser(searchTerm: query)
        } else {
            urlBar(urlBar, didSubmitText: query)
        }
    }

    func handle(url: URL?, isPrivate: Bool, options: Set<Route.SearchOptions>? = nil) {
        if let url = url {
            switchToTabForURLOrOpen(url, isPrivate: isPrivate)
        } else {
            openBlankNewTab(
                focusLocationField: options?.contains(.focusLocationField) == true,
                isPrivate: isPrivate
            )
        }
    }

    func handle(url: URL?, tabId: String, isPrivate: Bool = false) {
        if let url = url {
            switchToTabForURLOrOpen(url, uuid: tabId, isPrivate: isPrivate)
        } else {
            openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
        }
    }

    func handleQRCode() {
        navigationHandler?.showQRCode(delegate: self)
    }

    func closeAllPrivateTabs() {
        tabManager.removeTabs(tabManager.privateTabs)
        guard let tab = mostRecentTab(inTabs: tabManager.normalTabs) else {
            tabManager.selectTab(tabManager.addTab())
            return
        }
        tabManager.selectTab(tab)
    }

    func switchToPrivacyMode(isPrivate: Bool) {
        topTabsViewController?.applyUIMode(isPrivate: isPrivate, theme: currentTheme())
    }

    func switchToTabForURLOrOpen(_ url: URL, uuid: String? = nil, isPrivate: Bool = false) {
        guard !isCrashAlertShowing else {
            urlFromAnotherApp = UrlToOpenModel(url: url, isPrivate: isPrivate)
            logger.log("Saving urlFromAnotherApp since crash alert is showing", level: .debug, category: .tabs)
            return
        }
        popToBVC()
        guard !isShowingJSPromptAlert() else {
            tabManager.addTab(URLRequest(url: url), isPrivate: isPrivate)
            return
        }

        if let uuid = uuid, let tab = tabManager.getTabForUUID(uuid: uuid) {
            tabManager.selectTab(tab)
        } else if let tab = tabManager.getTabForURL(url) {
            tabManager.selectTab(tab)
        } else {
            openURLInNewTab(url, isPrivate: isPrivate)
        }
    }

    @discardableResult
    func openURLInNewTab(_ url: URL?, isPrivate: Bool = false) -> Tab {
        let request: URLRequest?
        if let url = url {
            request = URLRequest(url: url)
        } else {
            request = nil
            logger.log("No request for openURLInNewTab", level: .debug, category: .tabs)
        }

        let tab = tabManager.addTab(request, isPrivate: isPrivate)
        tabManager.selectTab(tab)
        switchToPrivacyMode(isPrivate: isPrivate)
        return tab
    }

    func focusLocationTextField(forTab tab: Tab?, setSearchText searchText: String? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            // Without a delay, the text field fails to become first responder
            // Check that the newly created tab is still selected.
            // This let's the user spam the Cmd+T button without lots of responder changes.
            guard tab == self.tabManager.selectedTab else { return }

            if self.isToolbarRefactorEnabled {
                let action = ToolbarAction(searchTerm: searchText,
                                           windowUUID: self.windowUUID,
                                           actionType: ToolbarActionType.didStartEditingUrl)
                store.dispatch(action)
            } else {
                self.urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)

                if let text = searchText {
                    self.urlBar.setLocation(text, search: true)
                }
            }
        }
    }

    func openNewTabFromMenu(focusLocationField: Bool, isPrivate: Bool) {
        overlayManager.openNewTab(url: nil, newTabSettings: newTabSettings)
        openBlankNewTab(focusLocationField: focusLocationField, isPrivate: isPrivate)
    }

    func openBlankNewTab(
        focusLocationField: Bool,
        isPrivate: Bool = false,
        searchFor searchText: String? = nil
    ) {
        popToBVC()
        guard !isShowingJSPromptAlert() else {
            tabManager.addTab(nil, isPrivate: isPrivate)
            return
        }

        let freshTab = openURLInNewTab(nil, isPrivate: isPrivate)
        freshTab.metadataManager?.updateTimerAndObserving(state: .newTab, isPrivate: freshTab.isPrivate)
        if focusLocationField {
            focusLocationTextField(forTab: freshTab, setSearchText: searchText)
        }
    }

    func openSearchNewTab(isPrivate: Bool = false, _ text: String) {
        popToBVC()

        guard let engine = profile.searchEnginesManager.defaultEngine,
              let searchURL = engine.searchURLForQuery(text)
        else {
            DefaultLogger.shared.log("Error handling URL entry: \"\(text)\".", level: .warning, category: .tabs)
            return
        }

        openURLInNewTab(searchURL, isPrivate: isPrivate)

        if let tab = tabManager.selectedTab {
            let searchData = LegacyTabGroupData(searchTerm: text,
                                                searchUrl: searchURL.absoluteString,
                                                nextReferralUrl: "")
            tab.metadataManager?.updateTimerAndObserving(
                state: .navSearchLoaded,
                searchData: searchData,
                isPrivate: tab.isPrivate
            )
        }
    }

    fileprivate func popToBVC() {
        guard let currentViewController = navigationController?.topViewController else { return }
        // Avoid dismissing JSPromptAlert that causes the crash because completionHandler was not called
        if !isShowingJSPromptAlert() {
            currentViewController.dismiss(animated: true, completion: nil)
        }

        if currentViewController != self {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    private func isShowingJSPromptAlert() -> Bool {
        return navigationController?.topViewController?.presentedViewController as? JSPromptAlertController != nil
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

        guard let webView = tab.webView else { return }

        self.screenshotHelper.takeScreenshot(tab)

        // when navigating in a tab, if the tab's mime type is pdf, we should:
        // - scroll to top
        // - set readermode state to unavailable
        if tab.mimeType == MIMEType.PDF {
            tab.shouldScrollToTop = true
            updateReaderModeState(for: tab, readerModeState: .unavailable)
        }

        if let url = webView.url {
            if (!InternalURL.isValid(url: url) || url.isReaderModeURL) && !url.isFileURL {
                postLocationChangeNotificationForTab(tab, navigation: navigation)
                tab.readabilityResult = nil
                webView.evaluateJavascriptInDefaultContentWorld("\(ReaderModeNamespace).checkReadability()")
            }

            // Update Fakespot sidebar if necessary
            if webViewStatus == .url {
                updateFakespot(tab: tab)
            }

            TabEvent.post(.didChangeURL(url), for: tab)
        }

        if webViewStatus == .finishedNavigation {
            let isSelectedTab = (tab == tabManager.selectedTab)
            if isSelectedTab && !isToolbarRefactorEnabled {
                // Refresh secure content state after completed navigation
                urlBar.locationView.hasSecureContent = webView.hasOnlySecureContent
            }

            if !isSelectedTab, let webView = tab.webView, tab.screenshot == nil {
                // To Screenshot a tab that is hidden we must add the webView,
                // then wait enough time for the webview to render.
                webView.frame = contentContainer.frame
                view.insertSubview(webView, at: 0)
                // This is kind of a hacky fix for Bug 1476637 to prevent webpages from focusing the
                // touch-screen keyboard from the background even though they shouldn't be able to.
                webView.resignFirstResponder()

                // We need a better way of identifying when webviews are finished rendering
                // There are cases in which the page will still show a loading animation or nothing
                // when the screenshot is being taken, depending on internet connection
                // Issue created: https://github.com/mozilla-mobile/firefox-ios/issues/7003
                let delayedTimeInterval = DispatchTimeInterval.milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: .now() + delayedTimeInterval) {
                    self.screenshotHelper.takeScreenshot(tab)
                    if webView.superview == self.view {
                        webView.removeFromSuperview()
                    }
                }
            }
        }
    }

    internal func updateFakespot(tab: Tab, isReload: Bool = false) {
        guard let webView = tab.webView,
              let url = webView.url
        else {
            // We're on homepage or a blank tab
            let action = FakespotAction(isOpen: false,
                                        windowUUID: windowUUID,
                                        actionType: FakespotActionType.setAppearanceTo)
            store.dispatch(action)
            return
        }

        let action = FakespotAction(tabUUID: tab.tabUUID,
                                    windowUUID: windowUUID,
                                    actionType: FakespotActionType.tabDidChange)
        store.dispatch(action)
        let isFeatureEnabled = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI)
        let environment = isFeatureEnabled ? FakespotEnvironment.staging : .prod
        let product = ShoppingProduct(url: url, client: FakespotClient(environment: environment))

        guard product.product != nil, !tab.isPrivate else {
            let action = FakespotAction(isOpen: false,
                                        windowUUID: windowUUID,
                                        actionType: FakespotActionType.setAppearanceTo)
            store.dispatch(action)
            // Quick fix: make sure to sidebar is hidden when opened from deep-link
            // Relates to FXIOS-7844
            contentStackView.hideSidebar(self)
            return
        }

        if isReload, let productId = product.product?.id {
            let action = FakespotAction(tabUUID: tab.tabUUID,
                                        productId: productId,
                                        windowUUID: windowUUID,
                                        actionType: FakespotActionType.tabDidReload)
            store.dispatch(action)
        }

        // Do not update Fakespot when we are not on a selected tab
        guard tabManager.selectedTab == tab else { return }

        if contentStackView.isSidebarVisible {
            // Sidebar is visible, update content
            navigationHandler?.updateFakespotSidebar(productURL: url,
                                                     sidebarContainer: contentStackView,
                                                     parentViewController: self)
        } else if FakespotUtils().shouldDisplayInSidebar(),
                  let fakespotState = browserViewControllerState?.fakespotState,
                  fakespotState.isOpen {
            // Sidebar should be displayed and Fakespot is open, display Fakespot
            handleFakespotFlow(productURL: url)
        } else if let fakespotState = browserViewControllerState?.fakespotState,
                  fakespotState.sidebarOpenForiPadLandscape,
                  UIDevice.current.userInterfaceIdiom == .pad {
            // Sidebar should be displayed, display Fakespot
            let action = FakespotAction(isOpen: true,
                                        windowUUID: windowUUID,
                                        actionType: FakespotActionType.setAppearanceTo)
            store.dispatch(action)
        }
    }

    // MARK: Autofill

    private func creditCardInitialSetupTelemetry() {
        // Credit card autofill status telemetry
        let userDefaults = UserDefaults.standard
        let key = PrefsKeys.KeyAutofillCreditCardStatus
        // Default value is true for autofill credit card input
        let autofillStatus = userDefaults.value(forKey: key) as? Bool ?? true
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .settings,
            object: .creditCardAutofillEnabled,
            extras: [
                TelemetryWrapper.ExtraKey.isCreditCardAutofillEnabled.rawValue: autofillStatus
            ]
        )

        // Credit card sync telemetry
        self.profile.hasSyncAccount { [unowned self] hasSync in
            logger.log("User has sync account setup \(hasSync)",
                       level: .debug,
                       category: .setup)

            guard hasSync else { return }
            let syncStatus = self.profile.syncManager.checkCreditCardEngineEnablement()
            TelemetryWrapper.recordEvent(
                category: .information,
                method: .settings,
                object: .creditCardSyncEnabled,
                extras: [
                    TelemetryWrapper.ExtraKey.isCreditCardSyncEnabled.rawValue: syncStatus
                ]
            )
        }
    }

    private func autofillCreditCardNimbusFeatureFlag() -> Bool {
        return featureFlags.isFeatureEnabled(.creditCardAutofillStatus, checking: .buildOnly)
    }

    private func autofillLoginNimbusFeatureFlag() -> Bool {
        return featureFlags.isFeatureEnabled(.loginAutofill, checking: .buildOnly)
    }

    private func autofillCreditCardSettingsUserDefaultIsEnabled() -> Bool {
        let userDefaults = UserDefaults.standard
        let keyCreditCardAutofill = PrefsKeys.KeyAutofillCreditCardStatus

        return (userDefaults.object(forKey: keyCreditCardAutofill) as? Bool ?? true)
    }

    private func addressAutofillSettingsUserDefaultsIsEnabled() -> Bool {
        let userDefaults = UserDefaults.standard
        let keyAddressAutofill = PrefsKeys.KeyAutofillAddressStatus

        return (userDefaults.object(forKey: keyAddressAutofill) as? Bool ?? true)
    }

    private func autofillSetup(_ tab: Tab, didCreateWebView webView: WKWebView) {
        let formAutofillHelper = FormAutofillHelper(tab: tab)
        tab.addContentScript(formAutofillHelper, name: FormAutofillHelper.name())

        // Closure to handle found field values for credit card and address fields
        formAutofillHelper.foundFieldValues = { [weak self] fieldValues, type, frame in
            guard let self, let tabWebView = tab.webView else { return }

            // Handle different field types
            switch fieldValues.fieldValue {
            case .address:
                handleFoundAddressFieldValue(type: type,
                                             tabWebView: tabWebView,
                                             webView: webView,
                                             frame: frame)
            case .creditCard:
                handleFoundCreditCardFieldValue(fieldValues: fieldValues,
                                                type: type,
                                                tabWebView: tabWebView,
                                                webView: webView,
                                                frame: frame)
            }
        }
    }

    private func handleFoundAddressFieldValue(type: FormAutofillPayloadType?,
                                              tabWebView: TabWebView,
                                              webView: WKWebView,
                                              frame: WKFrameInfo?) {
        guard addressAutofillSettingsUserDefaultsIsEnabled(),
              AddressLocaleFeatureValidator.isValidRegion(),
              // FXMO-376: Phase 2 let addressPayload = fieldValues.fieldData as? UnencryptedAddressFields,
              let type = type else { return }

        // Handle address form filling or capturing
        switch type {
        case .fillAddressForm:
            displayAddressAutofillAccessoryView(tabWebView: tabWebView)
        case .captureAddressForm:
            // FXMO-376: No action needed for capturing address form as this is for Phase 2
            break
        default:
            break
        }

        tabWebView.accessoryView.savedAddressesClosure = {
            DispatchQueue.main.async { [weak self] in
                webView.resignFirstResponder()
                self?.navigationHandler?.showAddressAutofill(frame: frame)
            }
        }
    }

    private func handleFoundCreditCardFieldValue(fieldValues: AutofillFieldValuePayload,
                                                 type: FormAutofillPayloadType?,
                                                 tabWebView: TabWebView,
                                                 webView: WKWebView,
                                                 frame: WKFrameInfo?) {
        guard let creditCardPayload = fieldValues.fieldData as? UnencryptedCreditCardFields,
              let type = type,
              autofillCreditCardSettingsUserDefaultIsEnabled() else { return }

        // Record telemetry for credit card form detection
        if type == .formInput {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .creditCardFormDetected)
        }

        guard autofillCreditCardNimbusFeatureFlag() else { return }

        // Handle different types of credit card interactions
        switch type {
        case .formInput:
            displayAutofillCreditCardAccessoryView(tabWebView: tabWebView)
        case .formSubmit:
            showCreditCardAutofillSheet(fieldValues: creditCardPayload)
        default:
            break
        }

        // Handle action when saved cards button is tapped
        handleSavedCardsButtonTap(tabWebView: tabWebView,
                                  webView: webView,
                                  frame: frame)
    }

    private func displayAutofillCreditCardAccessoryView(tabWebView: TabWebView) {
        profile.autofill.listCreditCards(completion: { cards, error in
            guard let cards = cards, !cards.isEmpty, error == nil else { return }
            DispatchQueue.main.async {
                tabWebView.accessoryView.reloadViewFor(AccessoryType.creditCard)
                tabWebView.reloadInputViews()
            }
        })
    }

    private func displayAddressAutofillAccessoryView(tabWebView: TabWebView) {
        profile.autofill.listAllAddresses(completion: { addresses, error in
            guard let addresses = addresses, !addresses.isEmpty, error == nil else { return }

            TelemetryWrapper.recordEvent(
                category: .action,
                method: .view,
                object: .addressAutofillPromptShown
            )
            DispatchQueue.main.async {
                tabWebView.accessoryView.reloadViewFor(AccessoryType.address)
                tabWebView.reloadInputViews()
            }
        })
    }

    /// Handles the action when the saved cards button is tapped on the tab web view.
    private func handleSavedCardsButtonTap(tabWebView: TabWebView, webView: WKWebView, frame: WKFrameInfo?) {
        tabWebView.accessoryView.savedCardsClosure = {
            DispatchQueue.main.async { [weak self] in
                webView.resignFirstResponder()
                self?.authenticateSelectCreditCardBottomSheet(frame: frame)
            }
        }
    }

    private func authenticateSelectCreditCardBottomSheet(frame: WKFrameInfo? = nil) {
        appAuthenticator.getAuthenticationState { [unowned self] state in
            switch state {
            case .deviceOwnerAuthenticated:
                // Note: Since we are injecting card info, we pass on the frame
                // for special iframe cases
                self.navigationHandler?.showCreditCardAutofill(creditCard: nil,
                                                               decryptedCard: nil,
                                                               viewType: .selectSavedCard,
                                                               frame: frame,
                                                               alertContainer: self.contentContainer)
            case .deviceOwnerFailed:
                break // Keep showing bvc
            case .passCodeRequired:
                self.navigationHandler?.showRequiredPassCode()
            }
        }
    }

    func showCreditCardAutofillSheet(fieldValues: UnencryptedCreditCardFields) {
        self.profile.autofill.checkForCreditCardExistance(
            cardNumber: fieldValues.ccNumberLast4
        ) { existingCard, error in
            guard let existingCard = existingCard else {
                DispatchQueue.main.async {
                    self.navigationHandler?.showCreditCardAutofill(creditCard: nil,
                                                                   decryptedCard: fieldValues,
                                                                   viewType: .save,
                                                                   frame: nil,
                                                                   alertContainer: self.contentContainer)
                }
                return
            }

            // card already saved should update if any of its other values are different
            if !fieldValues.isEqualToCreditCard(creditCard: existingCard) {
                DispatchQueue.main.async {
                    self.navigationHandler?.showCreditCardAutofill(creditCard: existingCard,
                                                                   decryptedCard: fieldValues,
                                                                   viewType: .update,
                                                                   frame: nil,
                                                                   alertContainer: self.contentContainer)
                }
            }
        }
    }

    // MARK: Overlay View
    // Disable search suggests view only if user is in private mode and setting is enabled
    private var shouldDisableSearchSuggestsForPrivateMode: Bool {
        let featureFlagEnabled = featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
        let alwaysShowSearchSuggestionsView = browserViewControllerState?
            .searchScreenState
            .showSearchSugestionsView ?? false

        let isSettingEnabled = profile.searchEnginesManager.shouldShowPrivateModeSearchSuggestions

        return featureFlagEnabled && !alwaysShowSearchSuggestionsView && !isSettingEnabled
    }

    // Configure dimming view to show for private mode
    private func configureDimmingView() {
        if let selectedTab = tabManager.selectedTab, selectedTab.isPrivate {
            view.addSubview(privateModeDimmingView)
            view.bringSubviewToFront(privateModeDimmingView)

            NSLayoutConstraint.activate([
                privateModeDimmingView.topAnchor.constraint(equalTo: contentStackView.topAnchor),
                privateModeDimmingView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                privateModeDimmingView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor),
                privateModeDimmingView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor)
            ])
        }
    }

    // Determines the view user should see when editing the url bar
    // Dimming view appears if private mode search suggest is disabled
    // Otherwise shows search suggests screen
    func configureOverlayView() {
        if shouldDisableSearchSuggestsForPrivateMode {
            configureDimmingView()
        } else {
            showSearchController()
        }
    }

    // MARK: Page Zoom

    @objc
    func handlePageZoomLevelUpdated(_ notification: Notification) {
        guard let uuid = notification.windowUUID,
              let zoomSetting = notification.userInfo?["zoom"] as? DomainZoomLevel,
              uuid != windowUUID else { return }
        updateForZoomChangedInOtherIPadWindow(zoom: zoomSetting)
    }

    // MARK: Themeable

    func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let currentTheme = currentTheme()
        statusBarOverlay.hasTopTabs = ToolbarHelper().shouldShowTopTabs(for: traitCollection)
        statusBarOverlay.applyTheme(theme: currentTheme)
        keyboardBackdrop?.backgroundColor = currentTheme.colors.layer1
        setNeedsStatusBarAppearanceUpdate()

        tabManager.selectedTab?.applyTheme(theme: currentTheme)

        if !isToolbarRefactorEnabled {
            let isPrivate = tabManager.selectedTab?.isPrivate ?? false
            urlBar.applyUIMode(isPrivate: isPrivate, theme: currentTheme)
        }

        toolbar.applyTheme(theme: currentTheme)

        guard let contentScript = tabManager.selectedTab?.getContentScript(name: ReaderMode.name()) else { return }
        applyThemeForPreferences(profile.prefs, contentScript: contentScript)
    }

    var isPreferSwitchToOpenTabOverDuplicateFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.preferSwitchToOpenTabOverDuplicate, checking: .buildOnly)
    }

    // MARK: - Telemetry

    private func logTelemetryForAppDidEnterBackground() {
        SearchBarSettingsViewModel.recordLocationTelemetry(for: isBottomSearchBar ? .bottom : .top)
        TabsTelemetry.trackTabsQuantity(tabManager: tabManager)

        if UIDevice.current.userInterfaceIdiom == .pad {
            let windowManager: WindowManager = AppContainer.shared.resolve()
            let windowCountExtras = [
                TelemetryWrapper.EventExtraKey.windowCount.rawValue: Int64(windowManager.windows.count)
            ]
            TelemetryWrapper.recordEvent(category: .information,
                                         method: .background,
                                         object: .iPadWindowCount,
                                         extras: windowCountExtras)
        }
    }

    // MARK: - LibraryPanelDelegate

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        guard let tab = tabManager.selectedTab else { return }

        if isPreferSwitchToOpenTabOverDuplicateFeatureEnabled,
           let tab = tabManager.tabs.reversed().first(where: {
               // URL for reading mode comes encoded and we need a separate case to check if it's equal with the tab url
               ($0.url == url || $0.url == url.safeEncodedUrl) && $0.isPrivate == tab.isPrivate
           }) {
            tabManager.selectTab(tab)
        } else {
            // Handle keyboard shortcuts from homepage with url selection
            // (ex: Cmd + Tap on Link; which is a cell in this case)
            if navigateLinkShortcutIfNeeded(url: url) {
                return
            }
            finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
        }
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        let tab = self.tabManager.addTab(
            URLRequest(url: url),
            afterTab: self.tabManager.selectedTab,
            isPrivate: isPrivate
        )
        let toolbar: URLBarViewProtocol = isToolbarRefactorEnabled ? addressToolbarContainer : urlBar
        // If we are showing toptabs a user can just use the top tab bar
        // If in overlay mode switching doesnt correctly dismiss the homepanels
        guard !topTabsVisible, !toolbar.inOverlayMode else { return }
        // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
        let viewModel = ButtonToastViewModel(labelText: .ContextMenuButtonToastNewTabOpenedLabelText,
                                             buttonText: .ContextMenuButtonToastNewTabOpenedButtonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: currentTheme(),
                                completion: { buttonPressed in
            if buttonPressed {
                self.tabManager.selectTab(tab)
            }
        })
        self.show(toast: toast)
    }

    var libraryPanelWindowUUID: WindowUUID {
        return windowUUID
    }

    // MARK: - RecentlyClosedPanelDelegate

    func openRecentlyClosedSiteInSameTab(_ url: URL) {
        guard let tab = self.tabManager.selectedTab else { return }
        self.finishEditingAndSubmit(url, visitType: .link, forTab: tab)
    }

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        tabManager.selectTab(tabManager.addTab(URLRequest(url: url)))
    }

    // MARK: - QRCodeViewControllerDelegate

    func didScanQRCodeWithURL(_ url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
        TelemetryWrapper.recordEvent(category: .action, method: .scan, object: .qrCodeURL)
    }

    func didScanQRCodeWithText(_ text: String) {
        TelemetryWrapper.recordEvent(category: .action, method: .scan, object: .qrCodeText)
        let defaultAction: () -> Void = { [weak self] in
            guard let tab = self?.tabManager.selectedTab else { return }
            self?.submitSearchText(text, forTab: tab)
        }
        let content = TextContentDetector.detectTextContent(text)
        switch content {
        case .some(.link(let url)):
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .some(.phoneNumber(let phoneNumber)):
            if let url = URL(string: "tel:\(phoneNumber)", invalidCharacters: false) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                defaultAction()
            }
        default:
            defaultAction()
        }
    }

    var qrCodeScanningPermissionLevel: QRCodeScanPermissions {
        return .default
    }

    // MARK: - BrowserFrameInfoProvider

    func getHeaderSize() -> CGSize {
        return header.frame.size
    }

    func getBottomContainerSize() -> CGSize {
        return bottomContainer.frame.size
    }

    func getOverKeyboardContainerSize() -> CGSize {
        return overKeyboardContainer.frame.size
    }

    // MARK: - AddressToolbarContainerDelegate
    func searchSuggestions(searchTerm: String) {
        openSuggestions(searchTerm: searchTerm)
        searchLoader?.query = searchTerm
    }

    func openBrowser(searchTerm: String) {
        didSubmitSearchText(searchTerm)
    }

    func openSuggestions(searchTerm: String) {
        if searchTerm.isEmpty {
            hideSearchController()
        } else {
            configureOverlayView()
        }
        searchController?.viewModel.searchQuery = searchTerm
        searchController?.searchTelemetry?.searchQuery = searchTerm
        searchController?.searchTelemetry?.clearVisibleResults()
        searchController?.searchTelemetry?.determineInteractionType()
    }

    // Also implements 
    // NavigationToolbarContainerDelegate::configureContextualHint(for button: UIButton, with contextualHintType: String)
    func configureContextualHint(for button: UIButton, with contextualHintType: String) {
        switch contextualHintType {
        case ContextualHintType.dataClearance.rawValue:
            configureDataClearanceContextualHint(button)
        case ContextualHintType.navigation.rawValue:
            configureNavigationContextualHint(button)
        default:
            return
        }
    }

    func addressToolbarDidBeginEditing(searchTerm: String, shouldShowSuggestions: Bool) {
        addressToolbarDidEnterOverlayMode(addressToolbarContainer)
    }

    func addressToolbarContainerAccessibilityActions() -> [UIAccessibilityCustomAction]? {
        locationActionsForURLBar().map { $0.accessibilityCustomAction }
    }

    func addressToolbarDidEnterOverlayMode(_ view: UIView) {
        guard let profile = profile as? BrowserProfile else { return }

        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibility.post(
                notification: UIAccessibility.Notification.screenChanged,
                argument: UIAccessibility.Notification.screenChanged
            )
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }

            showEmbeddedHomepage(inline: false, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
        }

        (view as? ThemeApplicable)?.applyTheme(theme: currentTheme())
    }

    func addressToolbar(_ view: UIView, didLeaveOverlayModeForReason reason: URLBarLeaveOverlayModeReason) {
        if searchSessionState == .active {
            // This delegate method may be called even if the user isn't
            // currently searching, but we only want to update the search
            // session state if they are.
            searchSessionState = switch reason {
            case .finished: .engaged
            case .cancelled: .abandoned
            }
        }
        destroySearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)

        (view as? ThemeApplicable)?.applyTheme(theme: currentTheme())
    }

    func addressToolbarDidBeginDragInteraction() {
        dismissVisibleMenus()
    }

    func addressToolbarDidTapSearchEngine(_ searchEngineView: UIView) {
        navigationHandler?.showSearchEngineSelection(forSourceView: searchEngineView)
    }
}

extension BrowserViewController: ClipboardBarDisplayHandlerDelegate {
    func shouldDisplay(clipBoardURL url: URL) {
        let viewModel = ButtonToastViewModel(
            labelText: .GoToCopiedLink,
            descriptionText: url.absoluteDisplayString,
            buttonText: .GoButtonTittle
        )

        let toast = ButtonToast(
            viewModel: viewModel,
            theme: currentTheme(),
            completion: { [weak self] buttonPressed in
                if buttonPressed {
                    let isPrivate = self?.tabManager.selectedTab?.isPrivate ?? false
                    self?.openURLInNewTab(url, isPrivate: isPrivate)
                }
            }
        )

        clipboardBarDisplayHandler?.clipboardToast = toast
        show(toast: toast, duration: ClipboardBarDisplayHandler.UX.toastDelay)
    }

    @available(iOS 16.0, *)
    func shouldDisplay() {
        let viewModel = ButtonToastViewModel(
            labelText: .GoToCopiedLink,
            descriptionText: "",
            buttonText: .GoButtonTittle
        )

        pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [UTType.url.identifier])

        let toast = PasteControlToast(
            viewModel: viewModel,
            theme: currentTheme(),
            target: self
        )

        clipboardBarDisplayHandler?.clipboardToast = toast
        show(toast: toast, duration: ClipboardBarDisplayHandler.UX.toastDelay)
    }

    override func paste(itemProviders: [NSItemProvider]) {
        for provider in itemProviders where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            _ = provider.loadObject(ofClass: URL.self) { [weak self] url, error in
                let isPrivate = self?.tabManager.selectedTab?.isPrivate ?? false

                DispatchQueue.main.async {
                    self?.openURLInNewTab(url, isPrivate: isPrivate)
                }
            }
        }
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

        if self.ignoredNavigation.remove(navigation) != nil {
            return nil
        }

        return self.typedNavigation.removeValue(forKey: navigation) ?? VisitType.link
    }
}

// MARK: - LegacyTabDelegate
extension BrowserViewController: LegacyTabDelegate {
    func tab(_ tab: Tab, didCreateWebView webView: WKWebView) {
        webView.frame = contentContainer.frame
        // Observers that live as long as the tab. Make sure these are all cleared in willDeleteWebView below!
        beginObserving(webView: webView)
        self.scrollController.beginObserving(scrollView: webView.scrollView)
        webView.uiDelegate = self

        let readerMode = ReaderMode(tab: tab)
        readerMode.delegate = self
        tab.addContentScript(readerMode, name: ReaderMode.name())

        let logins = LoginsHelper(
            tab: tab,
            profile: profile,
            theme: currentTheme()
        )
        tab.addContentScript(logins, name: LoginsHelper.name())
        logins.foundFieldValues = { [weak self, weak tab, weak webView] field, currentRequestId in
            Task {
                guard self?.autofillLoginNimbusFeatureFlag() == true else { return }
                guard let tabURL = tab?.url else { return }
                let logins = (try? await self?.profile.logins.listLogins()) ?? []
                let loginsForCurrentTab = self?.filterLoginsForCurrentTab(logins: logins,
                                                                          tabURL: tabURL,
                                                                          field: field) ?? []
                if loginsForCurrentTab.isEmpty {
                    tab?.webView?.accessoryView.reloadViewFor(.standard)
                } else {
                    tab?.webView?.accessoryView.reloadViewFor(.login)
                    tab?.webView?.reloadInputViews()
                    TelemetryWrapper.recordEvent(
                        category: .action,
                        method: .view,
                        object: .loginsAutofillPromptShown
                    )
                }
                tab?.webView?.accessoryView.savedLoginsClosure = {
                    Task { @MainActor [weak self] in
                        // Dismiss keyboard
                        webView?.resignFirstResponder()
                        self?.authenticateSelectSavedLoginsClosureBottomSheet(
                            tabURL: tabURL,
                            currentRequestId: currentRequestId,
                            field: field
                        )
                    }
                }
            }
        }

        // Credit card autofill setup and callback
        autofillSetup(tab, didCreateWebView: webView)

        let contextMenuHelper = ContextMenuHelper(tab: tab)
        tab.addContentScript(contextMenuHelper, name: ContextMenuHelper.name())

        let errorHelper = ErrorPageHelper(certStore: profile.certStore)
        tab.addContentScript(errorHelper, name: ErrorPageHelper.name())

        let findInPageHelper = FindInPageHelper(tab: tab)
        findInPageHelper.delegate = self
        tab.addContentScript(findInPageHelper, name: FindInPageHelper.name())

        let adsHelper = AdsTelemetryHelper(tab: tab)
        tab.addContentScript(adsHelper, name: AdsTelemetryHelper.name())

        let noImageModeHelper = NoImageModeHelper(tab: tab)
        tab.addContentScript(noImageModeHelper, name: NoImageModeHelper.name())

        let downloadContentScript = DownloadContentScript(tab: tab)
        tab.addContentScript(downloadContentScript, name: DownloadContentScript.name())

        let printHelper = PrintHelper(tab: tab)
        tab.addContentScriptToPage(printHelper, name: PrintHelper.name())

        let nightModeHelper = NightModeHelper()
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

    private func filterLoginsForCurrentTab(logins: [EncryptedLogin],
                                           tabURL: URL,
                                           field: FocusFieldType) -> [EncryptedLogin] {
        return logins.filter { login in
            if field == FocusFieldType.username && login.decryptedUsername.isEmpty { return false }
            guard let recordHostnameURL = URL(string: login.hostname) else { return false }
            return recordHostnameURL.baseDomain == tabURL.baseDomain
        }
    }

    private func authenticateSelectSavedLoginsClosureBottomSheet(
        tabURL: URL,
        currentRequestId: String,
        field: FocusFieldType
    ) {
        appAuthenticator.getAuthenticationState { [unowned self] state in
            switch state {
            case .deviceOwnerAuthenticated:
                self.navigationHandler?.showSavedLoginAutofill(
                    tabURL: tabURL,
                    currentRequestId: currentRequestId,
                    field: field
                )
            case .deviceOwnerFailed:
                // Keep showing bvc
                break
            case .passCodeRequired:
                self.navigationHandler?.showRequiredPassCode()
            }
        }
    }

    func tab(_ tab: Tab, willDeleteWebView webView: WKWebView) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            stopObserving(webView: webView)
            self.scrollController.stopObserving(scrollView: webView.scrollView)
            webView.uiDelegate = nil
            webView.scrollView.delegate = nil
            webView.removeFromSuperview()
        }
    }

    func tab(_ tab: Tab, didSelectFindInPageForSelection selection: String) {
        updateFindInPageVisibility(isVisible: true, withSearchText: selection)
        findInPageBar?.text = selection
    }

    func tab(_ tab: Tab, didSelectSearchWithFirefoxForSelection selection: String) {
        openSearchNewTab(isPrivate: tab.isPrivate, selection)
    }

    private func beginObserving(webView: WKWebView) {
        guard !observedWebViews.contains(webView) else {
            logger.log("Duplicate observance of webView", level: .warning, category: .webview)
            return
        }
        observedWebViews.insert(webView)
        KVOs.forEach { webView.addObserver(self, forKeyPath: $0.rawValue, options: .new, context: nil) }
    }

    private func stopObserving(webView: WKWebView) {
        guard observedWebViews.contains(webView) else {
            logger.log("Duplicate KVO de-registration of webView", level: .warning, category: .webview)
            return
        }
        observedWebViews.remove(webView)
        KVOs.forEach { webView.removeObserver(self, forKeyPath: $0.rawValue) }
    }

    // MARK: Snack bar

    func tab(_ tab: Tab, didAddSnackbar bar: SnackBar) {
        // If the Tab that had a SnackBar added to it is not currently
        // the selected Tab, do nothing right now. If/when the Tab gets
        // selected later, we will show the SnackBar at that time.
        guard tab == tabManager.selectedTab else { return }
        bar.applyTheme(theme: currentTheme())
        bottomContentStackView.addArrangedViewToBottom(bar, completion: {
            self.view.layoutIfNeeded()
        })
    }

    func tab(_ tab: Tab, didRemoveSnackbar bar: SnackBar) {
        bottomContentStackView.removeArrangedView(bar)
    }
}

// MARK: HomePanelDelegate
extension BrowserViewController: HomePanelDelegate {
    func homePanelDidRequestToOpenLibrary(panel: LibraryPanelType) {
        showLibrary(panel: panel)
        view.endEditing(true)
    }

    func homePanel(didSelectURL url: URL, visitType: VisitType, isGoogleTopSite: Bool) {
        guard let tab = tabManager.selectedTab else { return }

        if isPreferSwitchToOpenTabOverDuplicateFeatureEnabled,
           let tab = tabManager.tabs.reversed().first(where: {
               // URL for reading mode comes encoded and we need a separate case to check if it's equal with the tab url
               ($0.url == url || $0.url == url.safeEncodedUrl) && $0.isPrivate == tab.isPrivate
           }) {
            tabManager.selectTab(tab)
        } else {
            if isGoogleTopSite {
                tab.urlType = .googleTopSite
                searchTelemetry?.shouldSetGoogleTopSiteSearch = true
            }

            // Handle keyboard shortcuts from homepage with url selection
            // (ex: Cmd + Tap on Link; which is a cell in this case)
            if navigateLinkShortcutIfNeeded(url: url) {
                return
            }

            finishEditingAndSubmit(url, visitType: visitType, forTab: tab)
        }
    }

    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        let tab = tabManager.addTab(URLRequest(url: url), afterTab: tabManager.selectedTab, isPrivate: isPrivate)
        // Select new tab automatically if needed
        guard !selectNewTab else {
            tabManager.selectTab(tab)
            return
        }

        // If we are showing toptabs a user can just use the top tab bar
        guard !topTabsVisible else { return }

        // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
        let viewModel = ButtonToastViewModel(labelText: .ContextMenuButtonToastNewTabOpenedLabelText,
                                             buttonText: .ContextMenuButtonToastNewTabOpenedButtonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: currentTheme(),
                                completion: { buttonPressed in
            if buttonPressed {
                self.tabManager.selectTab(tab)
            }
        })
        show(toast: toast)
    }

    func homePanelDidRequestToOpenTabTray(withFocusedTab tabToFocus: Tab?, focusedSegment: TabTrayPanelType?) {
        showTabTray(withFocusOnUnselectedTab: tabToFocus, focusedSegment: focusedSegment)
    }

    func homePanelDidRequestToOpenSettings(at settingsPage: Route.SettingsSection) {
        navigationHandler?.show(settings: settingsPage)
    }

    func homePanelDidRequestBookmarkToast(url: URL?, action: BookmarkAction) {
        showBookmarkToast(bookmarkURL: url, action: action)
    }

    @objc
    func openRecentlyClosedTabs() {
        DispatchQueue.main.async {
            self.navigationHandler?.show(homepanelSection: .history)
            self.notificationCenter.post(name: .OpenRecentlyClosedTabs)
        }
     }
}

// MARK: - SearchViewController
extension BrowserViewController: SearchViewControllerDelegate {
    func searchViewController(
        _ searchViewController: SearchViewController,
        didSelectURL url: URL,
        searchTerm: String?
    ) {
        guard let tab = tabManager.selectedTab else { return }

        let searchData = LegacyTabGroupData(searchTerm: searchTerm ?? "",
                                            searchUrl: url.absoluteString,
                                            nextReferralUrl: "")
        tab.metadataManager?.updateTimerAndObserving(
            state: .navSearchLoaded,
            searchData: searchData,
            isPrivate: tab.isPrivate
        )
        searchTelemetry?.shouldSetUrlTypeSearch = true
        finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: tab)
    }

    // In searchViewController when user selects an open tabs and switch to it
    func searchViewController(_ searchViewController: SearchViewController, uuid: String) {
        overlayManager.switchTab(shouldCancelLoading: true)
        if let tab = tabManager.getTabForUUID(uuid: uuid) {
            tabManager.selectTab(tab)
        }
    }

    func presentSearchSettingsController() {
        let searchSettingsTableViewController = SearchSettingsTableViewController(profile: profile, windowUUID: windowUUID)
        let navController = ModalSettingsNavigationController(rootViewController: searchSettingsTableViewController)
        self.present(navController, animated: true, completion: nil)
    }

    @objc
    func updateForDefaultSearchEngineDidChange(_ notification: Notification) {
        // Update search icon when the search engine changes
        if isToolbarRefactorEnabled {
            let action = ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.searchEngineDidChange)
            store.dispatch(action)
        } else {
            urlBar.searchEnginesDidUpdate()
        }
        searchController?.reloadSearchEngines()
        searchController?.reloadData()
    }

    func setLocationView(text: String, search: Bool) {
        if isToolbarRefactorEnabled {
            let toolbarAction = ToolbarAction(
                searchTerm: text,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.didSetTextInLocationView
            )
            store.dispatch(toolbarAction)

            if search {
                openSuggestions(searchTerm: text)
                searchLoader?.setQueryWithoutAutocomplete(text)
            }
        } else {
            urlBar.setLocation(text, search: search)
        }
    }

    func searchViewController(
        _ searchViewController: SearchViewController,
        didHighlightText text: String,
        search: Bool
    ) {
        searchViewController.searchTelemetry?.interactionType = .refined
        setLocationView(text: text, search: search)
    }

    func searchViewController(_ searchViewController: SearchViewController, didAppend text: String) {
        searchViewController.searchTelemetry?.interactionType = .pasted
        setLocationView(text: text, search: false)
    }

    func searchViewControllerWillHide(_ searchViewController: SearchViewController) {
        switch searchSessionState {
        case .engaged:
            let visibleSuggestionsTelemetryInfo = searchViewController.visibleSuggestionsTelemetryInfo
            visibleSuggestionsTelemetryInfo.forEach { trackVisibleSuggestion(telemetryInfo: $0) }
            searchViewController.searchTelemetry?.recordURLBarSearchEngagementTelemetryEvent()
        case .abandoned:
            searchViewController.searchTelemetry?.engagementType = .dismiss
            let visibleSuggestionsTelemetryInfo = searchViewController.visibleSuggestionsTelemetryInfo
            visibleSuggestionsTelemetryInfo.forEach { trackVisibleSuggestion(telemetryInfo: $0) }
            searchViewController.searchTelemetry?.recordURLBarSearchAbandonmentTelemetryEvent()
        default:
            break
        }
    }

    /// Records telemetry for a suggestion that was visible during an engaged or
    /// abandoned search session. The user may have tapped on this suggestion
    /// or on a different suggestion, typed in a search term or a URL, or
    /// dismissed the URL bar without completing their search.
    func trackVisibleSuggestion(telemetryInfo info: SearchViewVisibleSuggestionTelemetryInfo) {
        switch info {
        // A sponsored or non-sponsored suggestion from Firefox Suggest.
        case let .firefoxSuggestion(telemetryInfo, position, didTap):
            let didAbandonSearchSession = searchSessionState == .abandoned
            TelemetryWrapper.gleanRecordEvent(
                category: .action,
                method: .view,
                object: TelemetryWrapper.EventObject.fxSuggest,
                extras: [
                    TelemetryWrapper.EventValue.fxSuggestionTelemetryInfo.rawValue: telemetryInfo,
                    TelemetryWrapper.EventValue.fxSuggestionPosition.rawValue: position,
                    TelemetryWrapper.EventValue.fxSuggestionDidTap.rawValue: didTap,
                    TelemetryWrapper.EventValue.fxSuggestionDidAbandonSearchSession.rawValue: didAbandonSearchSession,
                ]
            )
            if didTap {
                TelemetryWrapper.gleanRecordEvent(
                    category: .action,
                    method: .tap,
                    object: TelemetryWrapper.EventObject.fxSuggest,
                    extras: [
                        TelemetryWrapper.EventValue.fxSuggestionTelemetryInfo.rawValue: telemetryInfo,
                        TelemetryWrapper.EventValue.fxSuggestionPosition.rawValue: position,
                    ]
                )
            }
        }
    }
}

extension BrowserViewController: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selectedTab: Tab, previousTab: Tab?, isRestoring: Bool) {
        // Failing to have a non-nil webView by this point will cause the toolbar scrolling behaviour to regress,
        // back/forward buttons never to become enabled, etc. on tab restore after launch. [FXIOS-9785, FXIOS-9781]
        assert(selectedTab.webView != nil, "Setup will fail if the webView is not initialized for selectedTab")

        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        if let previousWebView = previousTab?.webView {
            previousWebView.endEditing(true)
            previousWebView.accessibilityLabel = nil
            previousWebView.accessibilityElementsHidden = true
            previousWebView.accessibilityIdentifier = nil
            previousWebView.removeFromSuperview()
        }

        if previousTab == nil || selectedTab.isPrivate != previousTab?.isPrivate {
            applyTheme()

            // TODO: [FXIOS-8907] Ideally we shouldn't create tabs as a side-effect of UI theme updates.
            var ui = [PrivateModeUI?]()
            if isToolbarRefactorEnabled {
                ui = [topTabsViewController]
            } else {
                ui = [toolbar, topTabsViewController, urlBar]
            }
            ui.forEach { $0?.applyUIMode(isPrivate: selectedTab.isPrivate, theme: currentTheme()) }
        } else {
            // Theme is applied to the tab and webView in the else case
            // because in the if block is applied already to all the tabs and web views
            selectedTab.applyTheme(theme: currentTheme())
            selectedTab.webView?.applyTheme(theme: currentTheme())
        }

        updateURLBarDisplayURL(selectedTab)
        if isToolbarRefactorEnabled, addressToolbarContainer.inOverlayMode, selectedTab.url?.displayURL != nil {
            addressToolbarContainer.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        } else if !isToolbarRefactorEnabled, urlBar.inOverlayMode, selectedTab.url?.displayURL != nil {
            urlBar.leaveOverlayMode(reason: .finished, shouldCancelLoading: false)
        }

        if let privateModeButton = topTabsViewController?.privateModeButton,
           previousTab != nil && previousTab?.isPrivate != selectedTab.isPrivate {
            privateModeButton.setSelected(selectedTab.isPrivate, animated: true)
        }
        readerModeCache = selectedTab.isPrivate ? MemoryReaderModeCache.sharedInstance : DiskReaderModeCache.sharedInstance
        ReaderModeHandlers.readerModeCache = readerModeCache

        scrollController.tab = selectedTab

        var needsReload = false
        if let webView = selectedTab.webView {
            webView.accessibilityLabel = .WebViewAccessibilityLabel
            webView.accessibilityIdentifier = "contentView"
            webView.accessibilityElementsHidden = false

            browserDelegate?.show(webView: webView)
            if selectedTab.isFxHomeTab {
                // Added as initial fix for WKWebView memory leak. Needs further investigation.
                // See: [FXIOS-10612] + [FXIOS-10335]
                needsReload = true
            }
            if webView.url == nil {
                // The webView can go gray if it was zombified due to memory pressure.
                // When this happens, the URL is nil, so try restoring the page upon selection.
                needsReload = true
            }
        }

        // Update Fakespot sidebar if necessary
        updateFakespot(tab: selectedTab)

        updateTabCountUsingTabManager(tabManager)

        bottomContentStackView.removeAllArrangedViews()

        selectedTab.bars.forEach { bar in
            bottomContentStackView.addArrangedViewToBottom(bar, completion: { self.view.layoutIfNeeded() })
        }

        updateFindInPageVisibility(isVisible: false, tab: previousTab)
        setupMiddleButtonStatus(isLoading: selectedTab.loading)

        if isToolbarRefactorEnabled {
            dispatchBackForwardToolbarAction(canGoBack: selectedTab.canGoBack,
                                             canGoForward: selectedTab.canGoForward,
                                             windowUUID: windowUUID)
        } else {
            navigationToolbar.updateBackStatus(selectedTab.canGoBack)
            navigationToolbar.updateForwardStatus(selectedTab.canGoForward)
        }

        if let url = selectedTab.webView?.url, !InternalURL.isValid(url: url) {
            if isToolbarRefactorEnabled {
                addressToolbarContainer.updateProgressBar(progress: selectedTab.estimatedProgress)
            } else {
                urlBar.updateProgressBar(Float(selectedTab.estimatedProgress))
            }
        }

        // When the newly selected tab is the homepage or another internal tab,
        // we need to explicitely set the reader mode state to be unavailable.
        if let url = selectedTab.webView?.url, InternalURL.scheme != url.scheme,
           let readerMode = selectedTab.getContentScript(name: ReaderMode.name()) as? ReaderMode {
            updateReaderModeState(for: selectedTab, readerModeState: readerMode.state)
            if readerMode.state == .active {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }
        } else {
            updateReaderModeState(for: selectedTab, readerModeState: .unavailable)
        }

        if topTabsVisible {
            topTabsDidChangeTab()
        }

       /// If the selectedTab is showing an error page trigger a reload
        if let url = selectedTab.url, let internalUrl = InternalURL(url), internalUrl.isErrorPage {
            needsReload = true
        }

        if needsReload {
            selectedTab.reloadPage()
        }
    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {
        // If we are restoring tabs then we update the count once at the end
        if !isRestoring {
            updateTabCountUsingTabManager(tabManager)
        }
        tab.tabDelegate = self

        // Show the Toolbar if a link from the current tab, open another tab
        if placeNextToParentTab {
            scrollController.showToolbars(animated: false)
        }
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        if let url = tab.lastKnownUrl, !(InternalURL(url)?.isAboutURL ?? false), !tab.isPrivate {
            profile.recentlyClosedTabs.addTab(url as URL,
                                              title: tab.lastTitle,
                                              lastExecutedTime: tab.lastExecutedTime)
        }
        if !isToolbarRefactorEnabled { urlBar.updateProgressBar(Float(0)) }
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

    func show(toast: Toast,
              afterWaiting delay: DispatchTimeInterval = Toast.UX.toastDelayBefore,
              duration: DispatchTimeInterval? = Toast.UX.toastDismissAfter) {
        if let downloadToast = toast as? DownloadToast {
            self.downloadToast = downloadToast
        }

        // If BVC isn't visible hold on to this toast until viewDidAppear
        if self.view.window == nil {
            self.pendingToast = toast
            return
        }

        toast.showToast(viewController: self, delay: delay, duration: duration) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                toast.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                toast.bottomAnchor.constraint(equalTo: self.bottomContentStackView.bottomAnchor)
            ]
        }
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        guard let toast = toast, !(tabManager.selectedTab?.isPrivate ?? false) else { return }
        // The toast is created from TabManager which doesn't have access to themeManager
        // The whole toast system needs some rework so as compromised solution before the rework I create the toast
        // with light theme and force apply theme with real theme before showing
        toast.applyTheme(theme: currentTheme())
        show(toast: toast, afterWaiting: ButtonToast.UX.delay)
    }

    func updateTabCountUsingTabManager(_ tabManager: TabManager, animated: Bool = true) {
        if let selectedTab = tabManager.selectedTab {
            let count = selectedTab.isPrivate ? tabManager.privateTabs.count : tabManager.normalTabs.count
            if isToolbarRefactorEnabled {
               updateToolbarTabCount(count)
            } else if !isToolbarRefactorEnabled {
                toolbar.updateTabCount(count, animated: animated)
                urlBar.updateTabCount(count, animated: !urlBar.inOverlayMode)
            }
            topTabsViewController?.updateTabCount(count, animated: animated)
        }
    }

    func tabManagerUpdateCount() {
        updateTabCountUsingTabManager(self.tabManager)
    }

    private func updateToolbarTabCount(_ count: Int) {
        // Only dispatch action when the number of tabs is different from what is saved in the state
        // to avoid having the toolbar re-displayed
        guard isToolbarRefactorEnabled,
              let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: windowUUID),
              toolbarState.numberOfTabs != count
        else { return }

        let action = ToolbarAction(numberOfTabs: count,
                                   windowUUID: windowUUID,
                                   actionType: ToolbarActionType.numberOfTabsChanged)
        store.dispatch(action)
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension BrowserViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController
    ) {
        displayedPopoverController = nil
        updateDisplayedPopoverProperties = nil
    }
}

extension BrowserViewController: UIAdaptivePresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}

extension BrowserViewController {
    /// Used to get the context menu save image in the context menu, shown from long press on webview links
    func getImageData(_ url: URL, success: @escaping (Data) -> Void) {
        makeURLSession(
            userAgent: UserAgent.fxaUserAgent,
            configuration: URLSessionConfiguration.defaultMPTCP).dataTask(with: url
            ) { (data, response, error) in
            if validatedHTTPResponse(response, statusCode: 200..<300) != nil,
               let data = data {
                success(data)
            }
        }.resume()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        keyboardPressesHandler().handlePressesBegan(presses, with: event)
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        keyboardPressesHandler().handlePressesEnded(presses, with: event)
        super.pressesEnded(presses, with: event)
    }
}

extension BrowserViewController {
    // no-op - relates to UIImageWriteToSavedPhotosAlbum
    @objc
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) { }
}

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomContentStackView.layoutIfNeeded()
            })
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = nil
        updateViewConstraints()

        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomContentStackView.layoutIfNeeded()
            })

        finishEditionMode()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {
        tabManager.selectedTab?.setFindInPage(isBottomSearchBar: isBottomSearchBar,
                                              doesFindInPageBarExist: findInPageBar != nil)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillChangeWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
        keyboardState = state
        updateViewConstraints()

        UIView.animate(
            withDuration: state.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(state.animationCurve.rawValue << 16))],
            animations: {
                self.bottomContentStackView.layoutIfNeeded()
            })
    }

    private func finishEditionMode() {
        // If keyboard is dismissed leave edit mode, Homepage case is handled in HomepageVC
        let newTabChoice = NewTabAccessors.getNewTabPage(profile.prefs)
        if newTabChoice != .topSites, newTabChoice != .blankPage {
            overlayManager.cancelEditing(shouldCancelLoading: false)
        }
    }
}

extension BrowserViewController: JSPromptAlertControllerDelegate {
    func promptAlertControllerDidDismiss(_ alertController: JSPromptAlertController) {
        showQueuedAlertIfAvailable()
    }
}

extension BrowserViewController: TopTabsDelegate {
    func topTabsDidPressTabs() {
        // Technically is not changing tabs but is loosing focus on urlbar
        overlayManager.switchTab(shouldCancelLoading: true)
        if !isToolbarRefactorEnabled {
            self.urlBarDidPressTabs(urlBar)
        }
    }

    func topTabsDidPressNewTab(_ isPrivate: Bool) {
        let shouldLoadCustomHomePage = isToolbarRefactorEnabled && NewTabAccessors.getHomePage(profile.prefs) == .homePage
        let homePageURL = HomeButtonHomePageAccessors.getHomePage(profile.prefs)

        if shouldLoadCustomHomePage, let url = homePageURL {
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
    func trackTelemetry() {
        trackAccessibility()
        trackNotificationPermission()
        appStartupTelemetry.sendStartupTelemetry()
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

    func trackNotificationPermission() {
        NotificationManager().getNotificationSettings(sendTelemetry: true) { _ in }
    }
}
