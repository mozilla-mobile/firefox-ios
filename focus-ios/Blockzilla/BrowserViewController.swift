/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import StoreKit
import Intents
import Glean
import Combine
import Onboarding
import AppShortcuts
import SwiftUI

class BrowserViewController: UIViewController {
    private let mainContainerView = UIView(frame: .zero)
    let darkView = UIView()
    private lazy var trackingProtectionManager = TrackingProtectionManager(
        isTrackingEnabled: {
            Settings.getToggle(.trackingProtection)
        })
    private lazy var webViewController: LegacyWebViewController = {
        var menuAction = WebMenuAction.live
        menuAction.openLink = { url in
            if let url = URIFixup.getURL(entry: url.absoluteString) {
                self.submit(url: url, source: .action)
            }
        }
        return LegacyWebViewController(trackingProtectionManager: trackingProtectionManager, webMenuAction: menuAction)
    }()
    private let legacyWebViewContainer = UIView()

    var modalDelegate: ModalDelegate?
    private var keyboardState: KeyboardState?
    private var homeViewController: HomeViewController!
    private let overlayView = OverlayView()
    private let searchEngineManager = SearchEngineManager(prefs: UserDefaults.standard)
    private let urlBarContainer = UIView()

    private var urlBar: URLBar!
    private lazy var browserToolbar = BrowserToolbar(viewModel: urlBarViewModel)
    private lazy var urlBarViewModel = URLBarViewModel(
        enableCustomDomainAutocomplete: { Settings.getToggle(.enableCustomDomainAutocomplete) },
        getCustomDomainSetting: { Settings.getCustomDomainSetting() },
        setCustomDomainSetting: { Settings.setCustomDomainSetting(domains: $0) },
        enableDomainAutocomplete: { Settings.getToggle(.enableDomainAutocomplete) }
    )

    private let searchSuggestClient = SearchSuggestClient()
    private var findInPageBar: FindInPageBar?
    private var fillerView: UIView?
    private let alertStackView = UIStackView() // All content that appears above the footer should be added to this view. (Find In Page/SnackBars)
    private let shortcutsContainer = UIStackView()
    private let shortcutsBackground = UIView()

    private var toolbarBottomConstraint: Constraint!
    private var urlBarTopConstraint: Constraint!
    private var homeViewBottomConstraint: Constraint!
    private var browserBottomConstraint: Constraint!
    private var lastScrollOffset = CGPoint.zero
    private var lastScrollTranslation = CGPoint.zero
    private var scrollBarOffsetAlpha: CGFloat = 0
    private var scrollBarState: URLBarScrollState = .expanded
    private var background = UIImageView()
    private var cancellables = Set<AnyCancellable>()
    private var onboardingEventsHandler: OnboardingEventsHandling
    private var themeManager: ThemeManager
    private let shortcutsPresenter = ShortcutsPresenter()
    private let onboardingTelemetry = OnboardingTelemetryHelper()

    private enum URLBarScrollState {
        case collapsed
        case expanded
        case transitioning
        case animating
    }

    private var homeViewContainer = UIView()

    fileprivate var showsToolsetInURLBar = false {
        didSet {
            if showsToolsetInURLBar {
                browserBottomConstraint.deactivate()
            } else {
                browserBottomConstraint.activate()
            }
        }
    }

    private let searchSuggestionsDebouncer = Debouncer(timeInterval: 0.1)
    private var shouldEnsureBrowsingMode = false
    private var isIPadRegularDimensions = false {
        didSet {
            overlayView.isIpadView = isIPadRegularDimensions
        }
    }
    private var initialUrl: URL?
    private var orientationWillChange = false
    private let tipManager: TipManager
    internal let shortcutManager: ShortcutsManager
    private let authenticationManager: AuthenticationManager

    static let userDefaultsTrackersBlockedKey = "lifetimeTrackersBlocked"

    init(
        tipManager: TipManager = TipManager.shared,
        shortcutManager: ShortcutsManager,
        authenticationManager: AuthenticationManager,
        onboardingEventsHandler: OnboardingEventsHandling,
        themeManager: ThemeManager
    ) {
        self.tipManager = tipManager
        self.shortcutManager = shortcutManager
        self.authenticationManager = authenticationManager
        self.onboardingEventsHandler = onboardingEventsHandler
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        self.shortcutManager.onTap = { [unowned self] in self.shortcutTapped(url: $0) }
        self.shortcutManager.onDismiss = { [unowned self] in self.dismissShortcut() }
        self.shortcutManager.onRemove = { [unowned self] in self.removeFromShortcuts() }
        self.shortcutManager.onShowRenameAlert = { [unowned self] in self.showRenameAlert(shortcut: $0) }
        self.shortcutManager.shortcutsDidUpdate = { [unowned self] in self.shortcutsDidUpdate() }
        self.shortcutManager.shortcutDidRemove = { [unowned self] in self.shortcutDidRemove(shortcut: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("BrowserViewController hasn't implemented init?(coder:)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    fileprivate func addShortcutsBackgroundConstraints() {
        shortcutsBackground.backgroundColor = isIPadRegularDimensions ? .systemBackground.withAlphaComponent(0.85) : .foundation
        shortcutsBackground.layer.cornerRadius = isIPadRegularDimensions ? 10 : 0

        if isIPadRegularDimensions {
            shortcutsBackground.snp.makeConstraints { make in
                make.top.equalTo(urlBarContainer.snp.bottom)
                make.width.equalTo(UIConstants.layout.shortcutsBackgroundWidthIPad)
                make.height.equalTo(UIConstants.layout.shortcutsBackgroundHeightIPad)
                make.centerX.equalTo(urlBarContainer)
            }
        } else {
            shortcutsBackground.snp.makeConstraints { make in
                make.top.equalTo(urlBarContainer.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(UIConstants.layout.shortcutsBackgroundHeight)
            }
        }
    }

    fileprivate func addShortcutsContainerConstraints() {
        let config: ShortcutView.LayoutConfiguration = isIPadRegularDimensions ? .iPad : .default
        shortcutsContainer.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom).offset(isIPadRegularDimensions ? UIConstants.layout.shortcutsContainerOffsetIPad : UIConstants.layout.shortcutsContainerOffset)
            make.width.equalTo(isIPadRegularDimensions ?
                               UIConstants.layout.shortcutsContainerWidthIPad :
                                UIConstants.layout.shortcutsContainerWidth).priority(.medium)
            make.height.equalTo(config.height)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(mainContainerView).inset(8)
            make.trailing.lessThanOrEqualTo(mainContainerView).inset(-8)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        view.addSubview(mainContainerView)

        isIPadRegularDimensions = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular

        darkView.isHidden = true
        darkView.backgroundColor = .ink90
        darkView.alpha = 0.4
        view.addSubview(darkView)
        darkView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        mainContainerView.snp.makeConstraints { make in
            make.top.bottom.leading.width.equalToSuperview()
        }

        if WebEngineFlagManager.isWebEngineEnabled {
            // FXIOS-8617 - #19118 ⁃ Integrate EngineSession in Focus iOS
        } else {
            // Legacy UI and related configuration
            // TODO: [FXIOS-8616] Portions of this configuration will eventually be shared also by WebEngine.
            configureLegacyUI()
        }
    }

    private func configureLegacyUI() {
        webViewController.delegate = self

        setupBackgroundImage()
        background.contentMode = .scaleAspectFill
        mainContainerView.addSubview(background)

        mainContainerView.addSubview(homeViewContainer)

        legacyWebViewContainer.isHidden = true
        mainContainerView.addSubview(legacyWebViewContainer)

        urlBarContainer.alpha = 0
        mainContainerView.addSubview(urlBarContainer)

        browserToolbar.isHidden = true
        browserToolbar.alpha = 0
        browserToolbar.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(browserToolbar)

        overlayView.isHidden = true
        overlayView.alpha = 0
        overlayView.delegate = self
        overlayView.backgroundColor = isIPadRegularDimensions ? .clear : .scrim.withAlphaComponent(0.48)
        overlayView.setSearchSuggestionsPromptViewDelegate(delegate: self)
        mainContainerView.addSubview(overlayView)

        shortcutsPresenter.shortcutsState = .createShortcutViews
        background.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView)
        }

        urlBarContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(mainContainerView)
            make.height.equalTo(mainContainerView).multipliedBy(0.6).priority(500)
        }

        browserToolbar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(mainContainerView)
            toolbarBottomConstraint = make.bottom.equalTo(mainContainerView).constraint
        }

        homeViewContainer.snp.makeConstraints { make in
            make.top.equalTo(mainContainerView.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(mainContainerView)
            homeViewBottomConstraint = make.bottom.equalTo(mainContainerView).constraint
            homeViewBottomConstraint.activate()
        }

        addWebViewConstraints()

        legacyWebViewContainer.snp.makeConstraints { make in
            browserBottomConstraint = make.bottom.equalTo(browserToolbar.snp.top).priority(1000).constraint
            if !showsToolsetInURLBar {
                browserBottomConstraint.activate()
            }
        }

        view.addSubview(alertStackView)
        alertStackView.axis = .vertical
        alertStackView.alignment = .center

        // true if device is an iPad or is an iPhone in landscape mode
        showsToolsetInURLBar = (UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == view.frame.size.width || view.frame.size.width > view.frame.size.height)) || (UIDevice.current.userInterfaceIdiom == .phone && view.frame.size.width > view.frame.size.height)

        containWebView()
        createHomeView()
        createURLBar()
        bindUrlBarViewModel()
        updateViewConstraints()

        overlayView.snp.makeConstraints { make in
            make.top.equalTo(urlBarContainer.snp.bottom)
            make.leading.trailing.equalTo(mainContainerView)
            make.bottom.equalToSuperview().inset(UIConstants.layout.tipViewHeight)
        }

        // Listen for request desktop site notifications
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: UIConstants.strings.requestDesktopNotification), object: nil, queue: nil) { [weak self] _ in
            // FXIOS-8638 - #19161 ⁃ Handle webViewController requestUserAgentChange
            self?.webViewController.requestUserAgentChange()
        }

        // Listen for request mobile site notifications
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: UIConstants.strings.requestMobileNotification), object: nil, queue: nil) { [weak self] _ in
            // FXIOS-8638 - #19161 ⁃ Handle webViewController requestUserAgentChange
            self?.webViewController.requestUserAgentChange()
        }

        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)

        // Listen for find in page actvitiy notifications
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: UIConstants.strings.findInPageNotification), object: nil, queue: nil) { [weak self] _ in
            self?.updateFindInPageVisibility(visible: true, text: "")
        }

        setupOnboardingEvents()
        setupShortcutEvents()

        trackingProtectionManager
            .$trackingProtectionStatus
            .sink { [unowned self] status in
                updateLockIcon(trackingProtectionStatus: status)
            }
            .store(in: &cancellables)

        guard shouldEnsureBrowsingMode else { return }
        ensureBrowsingMode()
        guard let url = initialUrl else { return }
        submit(url: url, source: .action)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
        homeViewController.toolbar.layoutIfNeeded()
        browserToolbar.layoutIfNeeded()
    }

    private func tooltipController(
        anchoredBy sourceView: UIView,
        sourceRect: CGRect, title: String = "",
        body: String,
        dismiss: @escaping () -> Void ) -> UIViewController {
            let tooltipViewController = TooltipViewController()
            tooltipViewController.set(title: title, body: body)
            tooltipViewController.configure(anchoredBy: sourceView, sourceRect: sourceRect)
            tooltipViewController.dismiss = dismiss
            return tooltipViewController
        }

    func controller(for route: ToolTipRoute) -> UIViewController? {
        switch route {
        case .trackingProtectionShield(let version):
            switch version {
            case .v2:
                return self.tooltipController(
                    anchoredBy: self.urlBar.shieldIconAnchor,
                    sourceRect: CGRect(x: self.urlBar.shieldIconAnchor.bounds.midX, y: self.urlBar.shieldIconAnchor.bounds.midY + 10, width: 0, height: 0),
                    body: UIConstants.strings.tooltipBodyTextForShieldIconV2,
                    dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil
                        self.onboardingEventsHandler.send(.showTrash)
                    }
                )

            case .v1:
                return self.tooltipController(
                    anchoredBy: self.urlBar.shieldIconAnchor,
                    sourceRect: CGRect(x: self.urlBar.shieldIconAnchor.bounds.midX, y: self.urlBar.shieldIconAnchor.bounds.midY + 10, width: 0, height: 0),
                    body: UIConstants.strings.tooltipBodyTextForShieldIcon,
                    dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil }
                )
            }

        case .trash(let version):
            switch version {
            case .v2:
                let sourceButton = showsToolsetInURLBar ? urlBar.deleteButtonAnchor : browserToolbar.deleteButtonAnchor
                let sourceRect = showsToolsetInURLBar ? CGRect(x: sourceButton.bounds.midX, y: sourceButton.bounds.maxY - 10, width: 0, height: 0) :
                CGRect(x: sourceButton.bounds.midX, y: sourceButton.bounds.minY + 10, width: 0, height: 0)
                return self.tooltipController(
                    anchoredBy: sourceButton,
                    sourceRect: sourceRect,
                    body: UIConstants.strings.tooltipBodyTextForTrashIconV2,
                    dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil }
                )

            case .v1:
                let sourceButton = showsToolsetInURLBar ? urlBar.deleteButtonAnchor : browserToolbar.deleteButtonAnchor
                let sourceRect = showsToolsetInURLBar ? CGRect(x: sourceButton.bounds.midX, y: sourceButton.bounds.maxY - 10, width: 0, height: 0) :
                CGRect(x: sourceButton.bounds.midX, y: sourceButton.bounds.minY + 10, width: 0, height: 0)
                return self.tooltipController(
                    anchoredBy: sourceButton,
                    sourceRect: sourceRect,
                    body: UIConstants.strings.tooltipBodyTextForTrashIcon,
                    dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil }
                )
            }

        case .searchBar:
            return self.tooltipController(
                anchoredBy: self.urlBar.textFieldAnchor,
                sourceRect: CGRect(
                    x: self.urlBar.textFieldAnchor.bounds.minX,
                    y: self.urlBar.textFieldAnchor.bounds.maxY,
                    width: 0,
                    height: 0
                ),
                body: UIConstants.strings.tooltipBodyTextStartPrivateBrowsing,
                dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil }
            )

        case .onboarding(let onboardingType):
            let dismissOnboarding = { [unowned self] in
                UserDefaults.standard.set(true, forKey: OnboardingConstants.onboardingDidAppear)
                urlBar.activateTextField()
                onboardingEventsHandler.route = nil
                onboardingEventsHandler.send(.enterHome)
            }
                return OnboardingFactory.make(onboardingType: onboardingType, dismissAction: dismissOnboarding, telemetry: onboardingTelemetry.handle(event:))

        case .trackingProtection:
            return nil

        case .widget:
            urlBar.dismiss()
            let cardBanner = PortraitHostingController(
                rootView: CardBannerView(
                    config: .init(
                        title: UIConstants.strings.widgetOnboardingCardTitle,
                        subtitle: UIConstants.strings.widgetOnboardingCardSubtitle,
                        actionButtonTitle: UIConstants.strings.widgetOnboardingCardActionButton,
                        widget: .init(
                            title: UIConstants.strings.searchInAppInstruction
                        )),
                    primaryAction: { [weak self] in
                        self?.onboardingEventsHandler.route = nil
                        self?.onboardingEventsHandler.send(.widgetDismissed)
                        self?.onboardingTelemetry.handle(event: .widgetPrimaryButtonTapped)
                    },
                    dismiss: { [weak self] in
                        self?.onboardingEventsHandler.route = nil
                        self?.urlBar.activateTextField()
                        self?.onboardingTelemetry.handle(event: .widgetCloseTapped)
                    }))
            cardBanner.view.backgroundColor = .clear
            cardBanner.modalPresentationStyle = .overFullScreen
            return cardBanner

        case .menu:
            return self.tooltipController(
                anchoredBy: self.urlBar.contextMenuButtonAnchor,
                sourceRect: CGRect(x: self.urlBar.contextMenuButtonAnchor.bounds.maxX, y: self.urlBar.contextMenuButtonAnchor.bounds.midY + 12, width: 0, height: 0),
                body: UIConstants.strings.tootipBodyTextForContextMenuIcon,
                dismiss: { [unowned self] in self.onboardingEventsHandler.route = nil }
            )
        case .widgetTutorial:
            let controller = PortraitHostingController(
                rootView: ShowMeHowOnboardingView(
                    config: .init(
                        title: UIConstants.strings.titleShowMeHowOnboardingV2,
                        subtitleStep1: UIConstants.strings.subtitleStepOneShowMeHowOnboardingV2,
                        subtitleStep2: UIConstants.strings.subtitleStepTwoShowMeHowOnboardingV2,
                        subtitleStep3: UIConstants.strings.subtitleStepThreeShowMeHowOnboardingV2,
                        buttonText: UIConstants.strings.buttonTextShowMeHowOnboardingV2,
                        widgetText: UIConstants.strings.searchInAppInstruction),
                    dismissAction: { [unowned self] in self.onboardingEventsHandler.route = nil }))
            controller.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .phone ? .overFullScreen : .formSheet
            controller.isModalInPresentation = true
            return controller
        }
    }

    private func setupOnboardingEvents() {
        var presentedController: UIViewController?
        onboardingEventsHandler
            .routePublisher
            .sink { [unowned self] route in
                switch route {
                case .none:
                    presentedController?.dismiss(animated: true)
                    presentedController = nil

                case .some(let route):
                    if let controller = controller(for: route) {
                        self.present(controller, animated: true)
                        presentedController = controller
                        switch route {
                        case .onboarding(let onboardingType):
                            if onboardingType == .v2 {
                                onboardingTelemetry.handle(event: .getStartedAppeared)
                            }
                        case .widget:
                            onboardingTelemetry.handle(event: .widgetCardAppeared)
                        default: break
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func setupShortcutEvents() {
        shortcutsPresenter
            .$shortcutsState
            .sink { [unowned self] shortcutsState in
                switch shortcutsState {
                case .createShortcutViews:
                    self.mainContainerView.addSubview(shortcutsBackground)
                    shortcutsBackground.isHidden = true
                    addShortcutsBackgroundConstraints()
                    setupShortcuts()
                    self.mainContainerView.addSubview(shortcutsContainer)
                    addShortcutsContainerConstraints()

                case .onHomeView:
                    shortcutsContainer.isHidden = false
                    shortcutsBackground.isHidden = true

                case .editingURL(let text):
                    let shouldShowShortcuts = text.isEmpty && !shortcutManager.shortcutsViewModels.isEmpty
                    shortcutsContainer.isHidden = !shouldShowShortcuts
                    shortcutsBackground.isHidden = !urlBar.inBrowsingMode ? true : !shouldShowShortcuts

                case .activeURLBar:
                    let shouldShowShortcuts = !shortcutManager.shortcutsViewModels.isEmpty
                    shortcutsContainer.isHidden = !shouldShowShortcuts
                    shortcutsBackground.isHidden = !shouldShowShortcuts || !urlBar.inBrowsingMode

                case .dismissedURLBar:
                    // FXIOS-8636 - #19159 - Integrate onProgress and onNavigationStateChange in Focus iOS
                    shortcutsContainer.isHidden = urlBar.inBrowsingMode || webViewController.isLoading
                    shortcutsBackground.isHidden = true

                case .none:
                    shortcutsContainer.isHidden = true
                    shortcutsBackground.isHidden = true
                }
            }
            .store(in: &cancellables)
    }

    private func addShortcuts() {
        if !shortcutManager.shortcutsViewModels.isEmpty {
            for shortcutViewModel in shortcutManager.shortcutsViewModels {
                let config: ShortcutView.LayoutConfiguration = isIPadRegularDimensions ? .iPad : .default
                let shortcutView = ShortcutView(shortcutViewModel: shortcutViewModel, layoutConfiguration: config)
                let interaction = UIContextMenuInteraction(delegate: shortcutView)
                shortcutView.outerView.addInteraction(interaction)
                shortcutView.setContentCompressionResistancePriority(.required, for: .horizontal)
                shortcutView.setContentHuggingPriority(.required, for: .horizontal)
                shortcutsContainer.addArrangedSubview(shortcutView)
                shortcutView.snp.makeConstraints { make in
                    make.width.equalTo(config.width)
                    make.height.equalTo(config.height)
                }
            }
        }
        if shortcutManager.hasSpace {
            shortcutsContainer.addArrangedSubview(UIView())
        }
    }

    private func setupShortcuts() {
        shortcutsContainer.axis = .horizontal
        shortcutsContainer.alignment = .leading
        shortcutsContainer.spacing = isIPadRegularDimensions ?
            UIConstants.layout.shortcutsContainerSpacingIPad :
            UIConstants.layout.shortcutsContainerSpacing

        addShortcuts()
    }

    @objc
    func orientationChanged() {
        setupBackgroundImage()
    }

    func setupBackgroundImage() {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            background.image = UIApplication.shared.orientation?.isLandscape == true ? #imageLiteral(resourceName: "background_iphone_landscape") : #imageLiteral(resourceName: "background_iphone_portrait")
        case .pad:
            background.image = UIApplication.shared.orientation?.isLandscape == true ? #imageLiteral(resourceName: "background_ipad_landscape") : #imageLiteral(resourceName: "background_ipad_portrait")
        default:
            background.image = #imageLiteral(resourceName: "background_iphone_portrait")
        }
    }

    private func updateLockIcon(trackingProtectionStatus: TrackingProtectionStatus) {
        // FXIOS-8643 - #19166 ⁃ Integrate content blocking in Focus iOS
        let isSecureConnection = urlBar.inBrowsingMode ? self.webViewController.connectionIsSecure : true
        let shieldIconStatus: ShieldIconStatus
        if isSecureConnection {
            switch trackingProtectionStatus {
            case .on: shieldIconStatus = .on
            case .off: shieldIconStatus = .off
            }
        } else {
            shieldIconStatus = .connectionNotSecure
        }
        urlBarViewModel.connectionState = shieldIconStatus
    }

    // These functions are used to handle displaying and hiding the keyboard after the splash view is animated
    public func activateUrlBarOnHomeView() {
        // Do not activate if a modal is presented
        if self.presentedViewController != nil {
            return
        }

        // Do not activate if we are showing a web page, nor the overlayView hidden
        if urlBar.inBrowsingMode {
            return
        }

        urlBar.activateTextField()
    }

    public func deactivateUrlBarOnHomeView() {
        urlBar.dismissTextField()
    }

    public func deactivateUrlBar() {
        if urlBar.inBrowsingMode {
            urlBar.dismiss()
        }
    }

    public func dismissSettings() {
        if self.presentedViewController?.children.first is SettingsViewController {
            self.presentedViewController?.children.first?.dismiss(animated: true, completion: nil)
        }
    }

    public func dismissActionSheet() {
        if self.presentedViewController is PhotonActionSheet {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            photonActionSheetDidDismiss()
        }
    }

    // FXIOS-8632 - #19158 - Integrate EngineSession full screen in Focus iOS
    public func exitFullScreenVideo() {
        let js = "closeFullScreen()"
        webViewController.evaluate(js, completion: nil)
    }

    // FXIOS-8617 - #19118 ⁃ Integrate EngineSession in Focus iOS
    private func containWebView() {
        addChild(webViewController)
        legacyWebViewContainer.addSubview(webViewController.view)
        webViewController.didMove(toParent: self)

        webViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(legacyWebViewContainer.snp.edges)
        }
    }

    private func createHomeView() {
        homeViewController = HomeViewController(tipManager: tipManager)
        homeViewController.delegate = self
        homeViewController.onboardingEventsHandler = onboardingEventsHandler
        install(homeViewController, on: homeViewContainer)
    }

    private func createURLBar() {
        urlBar = URLBar(viewModel: urlBarViewModel)
        urlBar.delegate = self
        urlBar.isIPadRegularDimensions = isIPadRegularDimensions
        urlBar.shouldShowToolset = showsToolsetInURLBar
        mainContainerView.insertSubview(urlBar, aboveSubview: urlBarContainer)

        addURLBarConstraints()
    }

    private func bindUrlBarViewModel() {
        urlBarViewModel.viewActionPublisher
            .sink { [weak self] action in
                guard let self = self else { return }

                switch action {
                case .contextMenuTap(let anchor):
                    self.updateFindInPageVisibility(visible: false)
                    self.presentContextMenu(from: anchor)

                case .backButtonTap:
                    // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
                    self.webViewController.goBack()

                case .forwardButtonTap:
                    // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
                    self.webViewController.goForward()

                case .deleteButtonTap:
                    self.updateFindInPageVisibility(visible: false)
                    self.resetBrowser()
                    self.urlBarViewModel.resetToDefaults()

                case .shieldIconButtonTap:
                    self.urlBarDidTapShield(self.urlBar)

                case .stopButtonTap:
                    // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
                    self.webViewController.stop()

                case .reloadButtonTap:
                    // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
                    self.webViewController.reload()

                case .dragInteractionStarted:
                    GleanMetrics.UrlInteraction.dragStarted.record()

                case .pasteAndGo:
                    GleanMetrics.UrlInteraction.pasteAndGo.record()
                }
            }.store(in: &cancellables)
    }

    private func addURLBarConstraints() {
        urlBar.snp.makeConstraints { make in
            urlBarTopConstraint = make.top.equalTo(mainContainerView.safeAreaLayoutGuide.snp.top).constraint

            if isIPadRegularDimensions {
                make.leading.trailing.equalToSuperview()
                make.centerX.equalToSuperview()
                make.bottom.equalTo(urlBarContainer)
            } else {
                make.bottom.equalTo(urlBarContainer)
                make.leading.trailing.equalToSuperview()
            }
        }
    }

    private func addWebViewConstraints() {
        let topConstraint = legacyWebViewContainer.topAnchor.constraint(equalTo: urlBarContainer.bottomAnchor)
        topConstraint.priority = .defaultLow
        let bottomConstraint = legacyWebViewContainer.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor)
        bottomConstraint.priority = .defaultLow
        let leadingConstraint = legacyWebViewContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor)
        let trailingConstraint = legacyWebViewContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        NSLayoutConstraint.activate([topConstraint, bottomConstraint, leadingConstraint, trailingConstraint])
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        alertStackView.snp.remakeConstraints { make in
            make.centerX.equalTo(self.view)
            make.width.equalTo(self.view.snp.width)

            if let keyboardHeight = keyboardState?.intersectionHeightForView(view: self.view), keyboardHeight > 0 {
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            } else if !browserToolbar.isHidden {
                // is an iPhone
                make.bottom.equalTo(self.browserToolbar.snp.top).priority(.low)
                make.bottom.lessThanOrEqualTo(self.view.safeAreaLayoutGuide.snp.bottom).priority(.required)
            } else {
                // is an iPad
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }

    func updateFindInPageVisibility(visible: Bool, text: String = "") {
        if visible {
            if findInPageBar == nil {
                urlBar.dismiss {
                    // Start our animation after urlBar dismisses
                    let findInPageBar = FindInPageBar()
                    self.findInPageBar = findInPageBar
                    let fillerView = UIView()
                    self.fillerView = fillerView
                    fillerView.backgroundColor = .grey70
                    findInPageBar.text = text
                    findInPageBar.delegate = self

                    self.alertStackView.addArrangedSubview(findInPageBar)
                    self.mainContainerView.insertSubview(fillerView, belowSubview: self.browserToolbar)

                    findInPageBar.snp.makeConstraints { make in
                        make.height.equalTo(UIConstants.layout.toolbarHeight)
                        make.leading.trailing.equalTo(self.alertStackView)
                        make.bottom.equalTo(self.alertStackView.snp.bottom)
                    }
                    fillerView.snp.makeConstraints { make in
                        make.top.equalTo(self.alertStackView.snp.bottom)
                        make.bottom.equalTo(self.view)
                        make.leading.trailing.equalTo(self.alertStackView)
                    }

                    self.view.layoutIfNeeded()
                }
            }

            self.findInPageBar?.becomeFirstResponder()
        } else if let findInPageBar = self.findInPageBar {
            findInPageBar.endEditing(true)
            // FXIOS-8631 - #19154 ⁃ Integrate EngineSession focus in Focus iOS
            webViewController.focus()
            // FXIOS-8628 - #19150 ⁃ Integrate EngineSession find in page in Focus iOS
            // This is done through `func findInPageDone()`
            webViewController.evaluate("__firefox__.findDone()", completion: nil)
            findInPageBar.removeFromSuperview()
            fillerView?.removeFromSuperview()
            self.findInPageBar = nil
            self.fillerView = nil
            updateViewConstraints()
        }
    }

    func resetBrowser(hidePreviousSession: Bool = false) {
        // Used when biometrics fail and the previous session should be obscured
        if hidePreviousSession {
            clearBrowser()
            urlBar.activateTextField()
            return
        }

        // Screenshot the browser, showing the screenshot on top.
        let screenshotView = view.snapshotView(afterScreenUpdates: true) ?? UIView()

        mainContainerView.addSubview(screenshotView)
        screenshotView.snp.makeConstraints { make in
            make.edges.equalTo(mainContainerView)
        }

        clearBrowser()

        UIView.animate(
            withDuration: UIConstants.layout.deleteAnimationDuration,
            animations: {
                screenshotView.snp.remakeConstraints { make in
                    make.centerX.equalTo(self.mainContainerView)
                    make.top.equalTo(self.mainContainerView.snp.bottom)
                    make.size.equalTo(self.mainContainerView).multipliedBy(0.9)
                }
            screenshotView.alpha = 0
            self.mainContainerView.layoutIfNeeded()
            },
            completion: { _ in
                self.urlBar.activateTextField()
                Toast(text: UIConstants.strings.eraseMessage).show()
                screenshotView.removeFromSuperview()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.onboardingEventsHandler.send(.clearTapped)
                }
            }
        )

        userActivity = SiriShortcuts().getActivity(for: .eraseAndOpen)
        let interaction = INInteraction(intent: eraseIntent, response: nil)
        interaction.donate { (error) in
            if let error = error { print(error.localizedDescription) }
        }
    }

    private func clearBrowser() {
        // Helper function for resetBrowser that handles all the logic of actually clearing user data and the browsing session
        overlayView.currentURL = ""
        // FXIOS-8639 - #19162 - Handle reset webview in Focus iOS
        webViewController.reset()
        legacyWebViewContainer.isHidden = true
        browserToolbar.isHidden = true
        urlBarViewModel.canGoBack = false
        urlBarViewModel.canGoForward = false
        urlBarViewModel.canDelete = false
        urlBar.dismiss()
        urlBar.removeFromSuperview()
        urlBarContainer.alpha = 0
        homeViewController.refreshTipsDisplay()
        homeViewController.view.isHidden = false
        createURLBar()
        updateLockIcon(trackingProtectionStatus: trackingProtectionManager.trackingProtectionStatus)
        shortcutsPresenter.shortcutsState = .onHomeView

        // Clear the cache and cookies, starting a new session.
        WebCacheUtils.reset()
        requestReviewIfNecessary()
        mainContainerView.layoutIfNeeded()
    }

    func requestReviewIfNecessary() {
        if AppInfo.isTesting() { return }
        let currentLaunchCount = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        let threshold = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)

        if threshold == 0 {
            UserDefaults.standard.set(14, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
            return
        }

        // Make sure the request isn't within 90 days of last request
        let minimumDaysBetweenReviewRequest = 90
        let daysSinceLastRequest: Int
        if let previousRequest = UserDefaults.standard.object(forKey: UIConstants.strings.userDefaultsLastReviewRequestDate) as? Date {
            daysSinceLastRequest = Calendar.current.dateComponents([.day], from: previousRequest, to: Date()).day ?? 0
        } else {
            // No previous request date found, meaning we've never asked for a review
            daysSinceLastRequest = minimumDaysBetweenReviewRequest
        }

        if currentLaunchCount <= threshold ||  daysSinceLastRequest < minimumDaysBetweenReviewRequest {
            return
        }

        UserDefaults.standard.set(Date(), forKey: UIConstants.strings.userDefaultsLastReviewRequestDate)

        // Increment the threshold by 50 so the user is not constantly pestered with review requests
        switch threshold {
        case 14:
            UserDefaults.standard.set(64, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
        case 64:
            UserDefaults.standard.set(114, forKey: UIConstants.strings.userDefaultsLaunchThresholdKey)
        default:
            break
        }

        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    private func showSiriFavoriteSettings() {
        guard let modalDelegate = modalDelegate else { return }

        urlBar.shouldPresent = false
        let siriFavoriteViewController = SiriFavoriteViewController()
        let siriFavoriteNavController = UINavigationController(rootViewController: siriFavoriteViewController)
        siriFavoriteNavController.modalPresentationStyle = .formSheet

        modalDelegate.presentModal(viewController: siriFavoriteNavController, animated: true)
    }

    func ensureBrowsingMode() {
        guard urlBar != nil else { shouldEnsureBrowsingMode = true; return }
        guard !urlBar.inBrowsingMode else { return }

        urlBarContainer.alpha = 1
        urlBar.ensureBrowsingMode()

        shouldEnsureBrowsingMode = false
    }

    func submit(text: String, source: Source) {
        var url = URIFixup.getURL(entry: text)
        if url == nil {
            recordSearchEvent(source)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        }

        if let url = url {
            submit(url: url, source: source)
        }
    }

    fileprivate func recordSearchEvent(_ source: Source) {
        let identifier = searchEngineManager.activeEngine.getNameOrCustom().lowercased()
        let source = source.rawValue
        GleanMetrics.BrowserSearch.searchCount["\(identifier).\(source)"].add()
    }

    func submit(url: URL, source: Source) {
        // If this is the first navigation, show the browser and the toolbar.
        guard isViewLoaded else { initialUrl = url; return }

        shortcutsPresenter.shortcutsState = .none
        SearchInContentTelemetry.shouldSetUrlTypeSearch = true
        if isIPadRegularDimensions {
            urlBar.snp.makeConstraints { make in
                make.width.equalTo(view)
                make.leading.equalTo(view)
            }
        }

        if legacyWebViewContainer.isHidden {
            legacyWebViewContainer.isHidden = false
            homeViewController.view.isHidden = true
            urlBar.inBrowsingMode = true

            if !showsToolsetInURLBar {
                browserToolbar.animateHidden(false, duration: UIConstants.layout.toolbarFadeAnimationDuration)
            }
        }
        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.load(URLRequest(url: url))

        if urlBar.url != url {
            urlBar.url = url
        }

        onboardingEventsHandler.route = nil
        onboardingEventsHandler.send(.startBrowsing)

        urlBarViewModel.canDelete = true
        guard let savedUrl = UserDefaults.standard.value(forKey: "favoriteUrl") as? String else { return }
        if let currentDomain = url.baseDomain,
            let savedDomain = URL(string: savedUrl, invalidCharacters: false)?.baseDomain,
            currentDomain == savedDomain {
            userActivity = SiriShortcuts().getActivity(for: .openURL)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Fixes the issue of a user fresh-opening Focus via Split View
        guard isViewLoaded else { return }

        orientationWillChange = true
        // UIDevice.current.orientation isn't reliable. See https://bugzilla.mozilla.org/show_bug.cgi?id=1315370#c5
        // As a workaround, consider the phone to be in landscape if the new width is greater than the height.
        showsToolsetInURLBar = (UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == size.width || size.width > size.height)) || (UIDevice.current.userInterfaceIdiom == .phone && size.width > size.height)

        // isIPadRegularDimensions check if the device is a Ipad and the app is not in split mode
        isIPadRegularDimensions = ((UIDevice.current.userInterfaceIdiom == .pad && (UIScreen.main.bounds.width == size.width || size.width > size.height))) || (UIDevice.current.userInterfaceIdiom == .pad &&  UIApplication.shared.orientation?.isPortrait == true && UIScreen.main.bounds.width == size.width)
        urlBar.isIPadRegularDimensions = isIPadRegularDimensions

        if urlBar.state == .default {
            urlBar.snp.removeConstraints()
            addURLBarConstraints()
        } else {
            urlBarContainer.snp.makeConstraints { make in
                make.width.equalTo(view)
                make.leading.equalTo(view)
            }
        }

        urlBar.updateConstraints()
        browserToolbar.updateConstraints()

        shortcutsContainer.spacing = size.width < UIConstants.layout.smallestSplitViewMaxWidthLimit ?
                                        UIConstants.layout.shortcutsContainerSpacingSmallestSplitView :
                                        (isIPadRegularDimensions ? UIConstants.layout.shortcutsContainerSpacingIPad : UIConstants.layout.shortcutsContainerSpacing)

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.urlBar.shouldShowToolset = self.showsToolsetInURLBar

            if self.homeViewController == nil && self.scrollBarState != .expanded {
                self.hideToolbars()
            }

            self.browserToolbar.animateHidden(!self.urlBar.inBrowsingMode || self.showsToolsetInURLBar, duration: coordinator.transitionDuration, completion: {
                self.updateViewConstraints()
                // FXIOS-8627 - #19151 - Integrate EngineSession zoom in Focus iOS
                self.webViewController.resetZoom()
            })
        })

        shortcutsContainer.snp.removeConstraints()
        addShortcutsContainerConstraints()

        shortcutsBackground.snp.removeConstraints()
        addShortcutsBackgroundConstraints()

        DispatchQueue.main.async {
            self.urlBar.updateCollapsedState()
            if case let .trash(version) = self.onboardingEventsHandler.route {
                self.onboardingEventsHandler.route = nil
                self.onboardingEventsHandler.route = .trash(version)
            }
        }
    }

    @objc
    private func selectLocationBar() {
        showToolbars()
        urlBar.activateTextField()
        shortcutsPresenter.shortcutsState = .activeURLBar
    }

    @objc
    private func reload() {
        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.reload()
    }

    @objc
    private func goBack() {
        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.goBack()
    }

    @objc
    private func goForward() {
        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.goForward()
    }

    @objc
    private func showFindInPage() {
        self.updateFindInPageVisibility(visible: true)
    }

    private func toggleURLBarBackground(isBright: Bool) {
        urlBarContainer.backgroundColor = urlBar.inBrowsingMode ? .foundation : .clear
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
                UIKeyCommand(title: UIConstants.strings.selectLocationBarTitle,
                             image: nil,
                             action: #selector(BrowserViewController.selectLocationBar),
                             input: "l",
                             modifierFlags: .command,
                             propertyList: nil),
                UIKeyCommand(title: UIConstants.strings.browserReload,
                             image: nil,
                             action: #selector(BrowserViewController.reload),
                             input: "r",
                             modifierFlags: .command,
                             propertyList: nil),
                UIKeyCommand(title: UIConstants.strings.browserBack,
                             image: nil,
                             action: #selector(BrowserViewController.goBack),
                             input: "[",
                             modifierFlags: .command,
                             propertyList: nil),
                UIKeyCommand(title: UIConstants.strings.browserForward,
                             image: nil,
                             action: #selector(BrowserViewController.goForward),
                             input: "]",
                             modifierFlags: .command,
                             propertyList: nil),
                UIKeyCommand(title: UIConstants.strings.shareMenuFindInPage,
                             image: nil,
                             action: #selector(BrowserViewController.showFindInPage),
                             input: "f",
                             modifierFlags: .command,
                             propertyList: nil)
        ]
    }

    func refreshTipsDisplay() {
        homeViewController.refreshTipsDisplay()
    }

    private func getNumberOfLifetimeTrackersBlocked(userDefaults: UserDefaults = UserDefaults.standard) -> Int {
        return userDefaults.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
    }

    private func setNumberOfLifetimeTrackersBlocked(numberOfTrackers: Int) {
        UserDefaults.standard.set(numberOfTrackers, forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
    }

    // FXIOS-8640 - #19163 - Clean up Focus iOS WebEngine related code
    // This function won't exist as is as part of the WebEngine. URL bar gets updated through onLocationChange(url:)
    func updateURLBar() {
        if webViewController.url?.absoluteString != "about:blank" {
            urlBar.url = webViewController.url
            overlayView.currentURL = urlBar.url?.absoluteString ?? ""
        }
    }

    @available(iOS 14, *)
    func buildActions(for sender: UIView) -> [UIMenuElement] {
        var actions: [UIMenuElement] = []

        if let url = urlBar.url {
            let utils = OpenUtils(url: url, webViewController: webViewController)

            getShortcutsItem(for: url)
                .map(UIAction.init)
                .map { UIMenu(options: .displayInline, children: [$0]) }
                .map {
                    actions.append($0)
                }

            var actionItems: [UIMenuElement] = [UIAction(findInPageItem)]
            actionItems.append(
                webViewController.requestMobileSite
                ? UIAction(requestMobileItem)
                : UIAction(requestDesktopItem)
            )

            let actionMenu = UIMenu(options: .displayInline, children: actionItems)
            actions.append(actionMenu)

            var shareItems: [UIMenuElement?] = [UIAction(copyItem(url: url))]
            shareItems.append(UIAction(sharePageItem(for: utils, sender: sender)))
            shareItems.append(openInFireFoxItem(for: url).map(UIAction.init))
            shareItems.append(openInChromeItem(for: url).map(UIAction.init))
            shareItems.append(UIAction(openInDefaultBrowserItem(for: url)))

            let shareMenu = UIMenu(options: .displayInline, children: shareItems.compactMap { $0 })
            actions.append(shareMenu)
            actions.append(UIMenu(options: .displayInline, children: [UIAction(settingsItem)]))
        } else {
            let actionMenu = UIMenu(options: .displayInline, children: [UIAction(helpItem), UIAction(settingsItem)])
            actions.append(actionMenu)
        }
        return actions
    }

    func buildActions(for sender: UIView) -> [[PhotonActionSheetItem]] {
        var actions: [[PhotonActionSheetItem]] = []

        if let url = urlBar.url {
            let utils = OpenUtils(url: url, webViewController: webViewController)

            actions.append([getShortcutsItem(for: url).map(PhotonActionSheetItem.init)].compactMap { $0 })

            var actionItems = [PhotonActionSheetItem(findInPageItem)]
            actionItems.append(
                webViewController.requestMobileSite
                ? PhotonActionSheetItem(requestMobileItem)
                : PhotonActionSheetItem(requestDesktopItem)
            )

            var shareItems: [PhotonActionSheetItem?] = [PhotonActionSheetItem(copyItem(url: url))]
            shareItems.append(PhotonActionSheetItem(sharePageItem(for: utils, sender: sender)))
            shareItems.append(openInFireFoxItem(for: url).map(PhotonActionSheetItem.init))
            shareItems.append(openInChromeItem(for: url).map(PhotonActionSheetItem.init))
            shareItems.append(PhotonActionSheetItem(openInDefaultBrowserItem(for: url)))

            actions.append(actionItems)
            actions.append(shareItems.compactMap { $0 })
        } else {
            actions.append([PhotonActionSheetItem(helpItem)])
        }

        actions.append([PhotonActionSheetItem(settingsItem)])
        return actions
    }

    func presentContextMenu(from sender: UIButton) {
        if #available(iOS 14, *) {
            sender.showsMenuAsPrimaryAction = true
            sender.menu = UIMenu(children: buildActions(for: sender))
        } else {
            let pageActionsMenu = PhotonActionSheet(actions: buildActions(for: sender))
            presentPhotonActionSheet(pageActionsMenu, from: sender)
        }
    }
}

extension BrowserViewController: MenuItemProvider {}

extension BrowserViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: URL.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        _ = session.loadObjects(ofClass: URL.self) { urls in
            guard let url = urls.first else {
                return
            }

            self.ensureBrowsingMode()
            self.urlBar.fillUrlBar(text: url.absoluteString)
            self.submit(url: url, source: .action)
            GleanMetrics.UrlInteraction.dropEnded.record()
        }
    }
}

// FXIOS-8628 - #19150 ⁃ Integrate EngineSession find in page in Focus iOS
extension BrowserViewController: FindInPageBarDelegate {
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

    private func find(_ text: String, function: String) {
        // FXIOS-8628 - #19150 ⁃ Integrate EngineSession find in page in Focus iOS
        // This is done through `func findInPage(text: String, function: FindInPageFunction)`
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        webViewController.evaluate("__firefox__.\(function)(\"\(escaped)\")", completion: nil)
    }

    private func shortcutContextMenuIsOpenOnIpad() -> Bool {
        var shortcutContextMenuIsDisplayed =  false
        for element in shortcutsContainer.subviews {
            if let shortcut = element as? ShortcutView, shortcut.contextMenuIsDisplayed {
                shortcutContextMenuIsDisplayed = true
            }
        }
        return isIPadRegularDimensions && shortcutContextMenuIsDisplayed
    }
}

extension BrowserViewController: URLBarDelegate {
    func urlBar(_ urlBar: URLBar, didAddCustomURL url: URL) {
        // Add the URL to the autocomplete list:
        let autocompleteSource = CustomCompletionSource(
            enableCustomDomainAutocomplete: { Settings.getToggle(.enableCustomDomainAutocomplete) },
            getCustomDomainSetting: { Settings.getCustomDomainSetting() },
            setCustomDomainSetting: { Settings.setCustomDomainSetting(domains: $0) }
        )

        switch autocompleteSource.add(suggestion: url.absoluteString) {
        case .failure(.duplicateDomain):
            break
        case .failure(let error):
            guard !error.message.isEmpty else { return }
            Toast(text: error.message).show()
        case .success:
            Toast(text: UIConstants.strings.autocompleteCustomURLAdded).show()
        }
    }

    func urlBar(_ urlBar: URLBar, didEnterText text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard urlBar.url?.absoluteString != trimmedText else { return }
        shortcutsPresenter.shortcutsState = .editingURL(text: trimmedText)
        let isOnHomeView = !urlBar.inBrowsingMode

        if Settings.getToggle(.enableSearchSuggestions), !trimmedText.isEmpty {
            searchSuggestionsDebouncer.renewInterval()
            searchSuggestionsDebouncer.completion = { [weak self] in
                guard let self = self else { return }
                self.searchSuggestClient.getSuggestions(trimmedText, callback: { suggestions, error in
                    let userInputText = urlBar.userInputText?.trimmingCharacters(in: .whitespaces) ?? ""

                    // Check if this callback is stale (new user input has been requested)
                    if userInputText.isEmpty || userInputText != trimmedText {
                        return
                    }

                    if userInputText == trimmedText {
                        let suggestions = suggestions ?? [trimmedText]
                        DispatchQueue.main.async {
                            self.overlayView.setColorstToSearchButtons()
                            self.overlayView.setSearchQuery(suggestions: suggestions, hideFindInPage: isOnHomeView || text.isEmpty, hideAddToComplete: true)
                        }
                    }
                })
            }
        } else {
            overlayView.setSearchQuery(suggestions: [trimmedText], hideFindInPage: isOnHomeView || text.isEmpty, hideAddToComplete: true)
        }
    }

    func urlBarDidPressScrollTop(_: URLBar, tap: UITapGestureRecognizer) {
        guard !urlBar.isEditing else { return }

        switch scrollBarState {
        case .expanded:
            let y = tap.location(in: urlBar).y

            // If the tap is greater than this threshold, the user wants to type in the URL bar
            if y >= 10 {
                urlBar.activateTextField()
                return
            }

            // FXIOS-8635 - #19155 Integrate EngineSession scrolling to top in Focus iOS
            // Just scroll the vertical position so the page doesn't appear under
            // the notch on the iPhone X
            var point = webViewController.scrollView.contentOffset
            point.y = 0
            webViewController.scrollView.setContentOffset(point, animated: true)
        case .collapsed: showToolbars()
        default: break
        }
    }

    func urlBar(_ urlBar: URLBar, didSubmitText text: String, source: Source) {
        let text = text.trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else {
            // FXIOS-8637 - #19160 - Integrate onTitleChange, onLocationChange in Focus iOS
            urlBar.url = webViewController.url
            return
        }

        SearchHistoryUtils.pushSearchToStack(with: text)
        SearchHistoryUtils.isFromURLBar = true

        var url = URIFixup.getURL(entry: text)
        if url == nil {
            recordSearchEvent(source)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        }
        if let urlBarURL = url {
            submit(url: urlBarURL, source: source)
            urlBar.url = urlBarURL
        }

        if let urlText = urlBar.url?.absoluteString {
            overlayView.currentURL = urlText
        }

        urlBar.dismiss()
    }

    func urlBarDidDismiss(_ urlBar: URLBar) {
        guard !shortcutContextMenuIsOpenOnIpad() else { return }
        overlayView.dismiss()

        // FXIOS-8636 - #19159 - Integrate onProgress and onNavigationStateChange in Focus iOS
        toggleURLBarBackground(isBright: !webViewController.isLoading)
        shortcutsPresenter.shortcutsState = .dismissedURLBar

        // FXIOS-8631 - #19154 ⁃ Integrate EngineSession focus in Focus iOS
        webViewController.focus()
    }

    func urlBarDidFocus(_ urlBar: URLBar) {
        let isOnHomeView = !urlBar.inBrowsingMode
        overlayView.present(isOnHomeView: isOnHomeView)
        toggleURLBarBackground(isBright: false)
    }

    func urlBarDidActivate(_ urlBar: URLBar) {
        shortcutsPresenter.shortcutsState = .activeURLBar
        homeViewController.updateUI(urlBarIsActive: true, isBrowsing: urlBar.inBrowsingMode)
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration, animations: {
            self.urlBarContainer.alpha = 1
            self.updateFindInPageVisibility(visible: false)
            self.view.layoutIfNeeded()
        })
    }

    func urlBarDidDeactivate(_ urlBar: URLBar) {
        homeViewController.updateUI(urlBarIsActive: false)
        UIView.animate(withDuration: UIConstants.layout.urlBarTransitionAnimationDuration) {
            self.urlBarContainer.alpha = 0
            self.view.setNeedsLayout()
        }
    }

    func urlBarDidTapShield(_ urlBar: URLBar) {
        GleanMetrics.TrackingProtection.toolbarShieldClicked.add()

        guard let modalDelegate = modalDelegate else { return }

        // FXIOS-8634 - #19156 ⁃ Integrate EngineSession favicon in Focus iOS
        let favIconPublisher: AnyPublisher<URL?, Never> =
        webViewController
            .getMetadata()
            .map(\.icon)
            .map { $0.flatMap(URL.init(string:)) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        // FXIOS-8643 - #19166 ⁃ Integrate content blocking in Focus iOS
        let state: TrackingProtectionState = urlBar.inBrowsingMode
        ? .browsing(status: SecureConnectionStatus(
            url: webViewController.url!,
            isSecureConnection: webViewController.connectionIsSecure))
        : .homescreen

        let trackingProtectionViewController = TrackingProtectionViewController(state: state, onboardingEventsHandler: onboardingEventsHandler, favIconPublisher: favIconPublisher)
        trackingProtectionViewController.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            trackingProtectionViewController.modalPresentationStyle = .popover
            trackingProtectionViewController.popoverPresentationController?.sourceView = urlBar.shieldIconAnchor
            modalDelegate.presentModal(viewController: trackingProtectionViewController, animated: true)
        } else {
            modalDelegate.presentSheet(viewController: trackingProtectionViewController)
        }
    }

    func urlBarDidLongPress(_ urlBar: URLBar) { }

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = urlBar.url
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let searchURL = searchURL, let query = searchEngineManager.queryForSearchURL(searchURL as URL) {
            return (query, true)
        } else {
            return (url?.absoluteString, false)
        }
    }
}

extension BrowserViewController: PhotonActionSheetDelegate {
    func presentPhotonActionSheet(_ actionSheet: PhotonActionSheet, from sender: UIView, arrowDirection: UIPopoverArrowDirection = .any) {
        actionSheet.modalPresentationStyle = .popover

        actionSheet.delegate = self

        if let popoverVC = actionSheet.popoverPresentationController {
            popoverVC.delegate = self
            popoverVC.sourceView = sender
            popoverVC.permittedArrowDirections = arrowDirection
        }

        present(actionSheet, animated: true, completion: nil)
    }

    func photonActionSheetDidDismiss() {
        darkView.isHidden = true
    }

    // FXIOS-8643 - #19166 ⁃ Integrate content blocking in Focus iOS
    func photonActionSheetDidToggleProtection(enabled: Bool) {
        if enabled {
            webViewController.enableTrackingProtection()
        } else {
            webViewController.disableTrackingProtection()
        }

        TipManager.sitesNotWorkingTip = false

        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.reload()
    }
}

extension BrowserViewController: UIAdaptivePresentationControllerDelegate {
    // Returning None here makes sure that the Popover is actually presented as a Popover and
    // not as a full-screen modal, which is the default on compact device classes.
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension BrowserViewController: TrackingProtectionDelegate {
    // FXIOS-8643 - #19166 ⁃ Integrate content blocking in Focus iOS
    func trackingProtectionDidToggleProtection(enabled: Bool) {
        if enabled {
            webViewController.enableTrackingProtection()
        } else {
            webViewController.disableTrackingProtection()
        }

        TipManager.sitesNotWorkingTip = false

        // FXIOS-8626 - #19148 - Integrate basics APIs of WebEngine in Focus iOS
        webViewController.reload()
    }
}

extension BrowserViewController: HomeViewControllerDelegate {
    func homeViewControllerDidTouchEmptyArea(_ controller: HomeViewController) {
        urlBar.dismiss()
    }

    func homeViewControllerDidTapShareTrackers(_ controller: HomeViewController, sender: UIButton) {
        let numberOfTrackersBlocked = getNumberOfLifetimeTrackersBlocked()
        let appStoreUrl = URL(string: String(format: "https://mzl.la/2GZBav0"), invalidCharacters: false)
        // Add space after shareTrackerStatsText to add URL in sentence
        let shareTrackerStatsText = "%@, the privacy browser from Mozilla, has already blocked %@ trackers for me. Fewer ads and trackers following me around means faster browsing! Get Focus for yourself here"
        let text = String(format: shareTrackerStatsText + " ", AppInfo.productName, String(numberOfTrackersBlocked))
        let shareController = UIActivityViewController(activityItems: [text, appStoreUrl as Any], applicationActivities: nil)
        // Exact frame dimensions taken from presentPhotonActionSheet
        shareController.popoverPresentationController?.sourceView = sender
        shareController.popoverPresentationController?.sourceRect = CGRect(x: sender.frame.width/2, y: 0, width: 1, height: 1)

        present(shareController, animated: true)
    }

    /// Visit the given URL. We make sure we are in browsing mode, and dismiss all modals. This is currently private
    /// because I don't think it is the best API to expose.
    private func visit(url: URL) {
        ensureBrowsingMode()
        deactivateUrlBarOnHomeView()
        dismissSettings()
        dismissActionSheet()
        submit(url: url, source: .action)
    }

    func homeViewControllerDidTapTip(_ controller: HomeViewController, tip: TipManager.Tip) {
        urlBar.dismiss()
        guard let action = tip.action else { return }
        switch action {
        case .visit(let topic):
            visit(url: URL(forSupportTopic: topic))
        case .showSettings(let destination):
            switch destination {
            case .siri:
                showSettings(shouldScrollToSiri: true)
            case .biometric:
                showSettings()
            case .siriFavorite:
                showSiriFavoriteSettings()
            }
        }
    }
}

extension BrowserViewController: OverlayViewDelegate {
    func overlayViewDidPressSettings(_ overlayView: OverlayView) {
        urlBar.dismiss()
        showSettings()
    }

    func overlayViewDidTouchEmptyArea(_ overlayView: OverlayView) {
        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchForQuery query: String) {
        if searchEngineManager.activeEngine.urlForQuery(query) != nil {
            urlBar(urlBar, didSubmitText: query, source: .suggestion)
        }

        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didSearchOnPage query: String) {
        updateFindInPageVisibility(visible: true, text: query)
        self.find(query, function: "find")
    }

    func overlayView(_ overlayView: OverlayView, didAddToAutocomplete query: String) {
        urlBar.dismiss()

        let autocompleteSource = CustomCompletionSource(
            enableCustomDomainAutocomplete: { Settings.getToggle(.enableCustomDomainAutocomplete) },
            getCustomDomainSetting: { Settings.getCustomDomainSetting() },
            setCustomDomainSetting: { Settings.setCustomDomainSetting(domains: $0) }
        )
        switch autocompleteSource.add(suggestion: query) {
        case .failure(.duplicateDomain):
            Toast(text: UIConstants.strings.autocompleteCustomURLDuplicate).show()
        case .failure(let error):
            guard !error.message.isEmpty else { return }
            Toast(text: error.message).show()
        case .success:
            Toast(text: UIConstants.strings.autocompleteCustomURLAdded).show()
        }
    }

    func overlayView(_ overlayView: OverlayView, didSubmitText text: String) {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            // FXIOS-8637 - #19160 - Integrate onTitleChange, onLocationChange in Focus iOS
            urlBar.url = webViewController.url
            return
        }

        var url = URIFixup.getURL(entry: text)
        if url == nil {
            recordSearchEvent(.suggestion)
            url = searchEngineManager.activeEngine.urlForQuery(text)
        }
        if let overlayURL = url {
            submit(url: overlayURL, source: .suggestion)
            urlBar.url = overlayURL
        }
        urlBar.dismiss()
    }

    func overlayView(_ overlayView: OverlayView, didTapArrowText text: String) {
        urlBar.fillUrlBar(text: text + " ")
        searchSuggestClient.getSuggestions(text) { [weak self] suggestions, error in
            if error == nil, let suggestions = suggestions {
                self?.overlayView.setSearchQuery(suggestions: suggestions, hideFindInPage: true, hideAddToComplete: true)
            }
        }
    }
}

extension BrowserViewController: SearchSuggestionsPromptViewDelegate {
    func searchSuggestionsPromptView(_ searchSuggestionsPromptView: SearchSuggestionsPromptView, didEnable: Bool) {
        UserDefaults.standard.set(true, forKey: SearchSuggestionsPromptView.respondedToSearchSuggestionsPrompt)
        Settings.set(didEnable, forToggle: SettingsToggle.enableSearchSuggestions)
        overlayView.updateSearchSuggestionsPrompt(hidden: true)
        if didEnable, let urlbar = self.urlBar, let value = self.urlBar?.userInputText {
            urlBar(urlbar, didEnterText: value)
        }
    }
}

extension BrowserViewController: LegacyWebControllerDelegate {
    func webControllerDidStartProvisionalNavigation(_ controller: LegacyWebController) {
        urlBar.dismiss()
        updateFindInPageVisibility(visible: false)
    }

    func webController(_ controller: LegacyWebController, didUpdateFindInPageResults currentResult: Int?, totalResults: Int?) {
        if let total = totalResults {
            findInPageBar?.totalResults = total
        }

        if let current = currentResult {
            findInPageBar?.currentResult = current
        }
    }

    func webControllerDidReload(_ controller: LegacyWebController) {
        SearchHistoryUtils.isReload = true
    }

    func webControllerDidStartNavigation(_ controller: LegacyWebController) {
        if !SearchHistoryUtils.isFromURLBar && !SearchHistoryUtils.isNavigating && !SearchHistoryUtils.isReload {
            SearchHistoryUtils.pushSearchToStack(with: (urlBar.url?.absoluteString)!)
        }
        SearchHistoryUtils.isReload = false
        SearchHistoryUtils.isNavigating = false
        SearchHistoryUtils.isFromURLBar = false
        urlBarViewModel.isLoading = true
        toggleURLBarBackground(isBright: false)
        updateURLBar()
    }

    func webControllerDidFinishNavigation(_ controller: LegacyWebController) {
        updateURLBar()
        urlBarViewModel.isLoading = false
        urlBarViewModel.loadingProgres = 1
        toggleURLBarBackground(isBright: !urlBar.isEditing)
        GleanMetrics.Browser.totalUriCount.add()
        // FXIOS-8641 - #19164 ⁃ Handle webViewController evaluateDocumentContentType
        webViewController.evaluateDocumentContentType { documentType in
            if documentType == "application/pdf" {
                GleanMetrics.Browser.pdfViewerUsed.add()
            }
        }
        Task {
            // FXIOS-8634 - #19156 ⁃ Integrate EngineSession favicon in Focus iOS
            let faviconURL = try? await webViewController.getMetadata().icon.flatMap(URL.init(string:))
            guard let faviconURL = faviconURL, let url = urlBar.url else { return }
            shortcutManager.update(faviconURL: faviconURL, for: url)
        }
    }

    func webControllerURLDidChange(_ controller: LegacyWebController, url: URL) {
        showToolbars()
    }

    func webController(_ controller: LegacyWebController, didFailNavigationWithError error: Error) {
        // FXIOS-8637 - #19160 - Integrate onTitleChange, onLocationChange in Focus iOS
        urlBar.url = webViewController.url
        toggleURLBarBackground(isBright: true)
        urlBarViewModel.isLoading = false
        urlBarViewModel.loadingProgres = 1
    }

    func webController(_ controller: LegacyWebController, didUpdateCanGoBack canGoBack: Bool) {
        urlBarViewModel.canGoBack = canGoBack
    }

    func webController(_ controller: LegacyWebController, didUpdateCanGoForward canGoForward: Bool) {
        urlBarViewModel.canGoForward = canGoForward
    }

    // FXIOS-8636 - #19159 - Integrate onProgress and onNavigationStateChange in Focus iOS
    func webController(_ controller: LegacyWebController, didUpdateEstimatedProgress estimatedProgress: Double) {
        // Don't update progress if the home view is visible. This prevents the centered URL bar
        // from catching the global progress events.
        guard urlBar.inBrowsingMode else { return }

        urlBarViewModel.loadingProgres = estimatedProgress
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    func webController(_ controller: LegacyWebController, scrollViewWillBeginDragging scrollView: UIScrollView) {
        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = scrollView.panGestureRecognizer.translation(in: scrollView)
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    func webController(_ controller: LegacyWebController, scrollViewDidEndDragging scrollView: UIScrollView) {
        snapToolbars(scrollView: scrollView)
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    func webController(_ controller: LegacyWebController, scrollViewDidScroll scrollView: UIScrollView) {
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView)
        let isDragging = scrollView.panGestureRecognizer.state != .possible

        // This will be 0 if we're moving but not dragging (i.e., gliding after dragging).
        let dragDelta = translation.y - lastScrollTranslation.y

        // This will match dragDelta unless the URL bar is transitioning.
        let offsetDelta = scrollView.contentOffset.y - lastScrollOffset.y

        lastScrollOffset = scrollView.contentOffset
        lastScrollTranslation = translation

        guard scrollBarState != .animating, !scrollView.isZooming else { return }

        guard scrollView.contentOffset.y + scrollView.frame.height < scrollView.contentSize.height && (scrollView.contentOffset.y > 0 || scrollBarOffsetAlpha > 0) else {
            // We're overscrolling, so don't do anything.
            return
        }

        if !isDragging && offsetDelta < 0 {
            // We're gliding up after dragging, so fully show the toolbars.
            showToolbars()
            return
        }

        let pageExtendsBeyondScrollView = scrollView.frame.height + (UIConstants.layout.browserToolbarHeight + view.safeAreaInsets.bottom) + UIConstants.layout.urlBarHeight < scrollView.contentSize.height
        let toolbarsHiddenAtTopOfPage = scrollView.contentOffset.y <= 0 && scrollBarOffsetAlpha > 0

        guard isDragging, (dragDelta < 0 && pageExtendsBeyondScrollView) || toolbarsHiddenAtTopOfPage || scrollBarState == .transitioning else { return }

        let lastOffsetAlpha = scrollBarOffsetAlpha
        scrollBarOffsetAlpha = (0 ... 1).clamp(scrollBarOffsetAlpha - dragDelta / UIConstants.layout.urlBarHeight)
        switch scrollBarOffsetAlpha {
        case 0:
            scrollBarState = .expanded
        case 1:
            scrollBarState = .collapsed
        default:
            scrollBarState = .transitioning
        }

        let expandAlpha = max(0, (1 - scrollBarOffsetAlpha * 2))
        let collapseAlpha = max(0, -(1 - scrollBarOffsetAlpha * 2))

        if expandAlpha == 1, collapseAlpha == 0 {
            self.urlBar.collapsedState = .extended
        } else {
            self.urlBar.collapsedState = .intermediate(expandAlpha: expandAlpha, collapseAlpha: collapseAlpha)
        }

        self.urlBarTopConstraint.update(offset: -scrollBarOffsetAlpha * (UIConstants.layout.urlBarHeight - UIConstants.layout.collapsedUrlBarHeight))
        self.toolbarBottomConstraint.update(offset: scrollBarOffsetAlpha * (UIConstants.layout.browserToolbarHeight + view.safeAreaInsets.bottom))
        updateViewConstraints()
        scrollView.bounds.origin.y += (lastOffsetAlpha - scrollBarOffsetAlpha) * UIConstants.layout.urlBarHeight

        lastScrollOffset = scrollView.contentOffset
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    func webControllerShouldScrollToTop(_ controller: LegacyWebController) -> Bool {
        guard scrollBarOffsetAlpha == 0 else {
            showToolbars()
            return false
        }

        return true
    }

    func webControllerDidNavigateBack(_ controller: LegacyWebController) {
        handleNavigationBack()
    }

    func webControllerDidNavigateForward(_ controller: LegacyWebController) {
        handleNavigationForward()
    }

    private func handleNavigationBack() {
        // Check if the previous site we were on was AMP
        guard let navigatingFromAmpSite = SearchHistoryUtils.pullSearchFromStack()?.hasPrefix(UIConstants.strings.googleAmpURLPrefix) else {
            return
        }

        // Make sure our navigation is not pushed to the SearchHistoryUtils stack (since it already exists there)
        SearchHistoryUtils.isFromURLBar = true

        // This function is now getting called after our new url is set!!
        if !navigatingFromAmpSite {
            SearchHistoryUtils.goBack()
        }
    }

    private func handleNavigationForward() {
        // Make sure our navigation is not pushed to the SearchHistoryUtils stack (since it already exists there)
        SearchHistoryUtils.isFromURLBar = true

        // Check if we're navigating to an AMP site *after* the URL bar is updated. This is intentionally grabbing the NEW url
        guard let navigatingToAmpSite = urlBar.url?.absoluteString.hasPrefix(UIConstants.strings.googleAmpURLPrefix) else { return }

        if !navigatingToAmpSite {
            SearchHistoryUtils.goForward()
        }
    }

    func webController(_ controller: LegacyWebController, didUpdateTrackingProtectionStatus trackingStatus: TrackingProtectionStatus, oldTrackingProtectionStatus: TrackingProtectionStatus) {
        // Calculate the number of trackers blocked and add that to lifetime total
        if case .on(let info) = trackingStatus,
           case .on(let oldInfo) = oldTrackingProtectionStatus {
            let differenceSinceLastUpdate = max(0, info.total - oldInfo.total)
            let numberOfTrackersBlocked = getNumberOfLifetimeTrackersBlocked()
            let totalNumberOfTrackersBlocked = numberOfTrackersBlocked + differenceSinceLastUpdate
            if totalNumberOfTrackersBlocked > 0 { onboardingEventsHandler.send(.trackerBlocked) }
            setNumberOfLifetimeTrackersBlocked(numberOfTrackers: totalNumberOfTrackersBlocked)
        }
        updateLockIcon(trackingProtectionStatus: trackingStatus)
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    private func showToolbars() {
        let scrollView = webViewController.scrollView

        scrollBarState = .animating

        UIView.animate(
            withDuration: UIConstants.layout.urlBarTransitionAnimationDuration,
            delay: 0,
            options: .allowUserInteraction,
            animations: {
                self.urlBar.collapsedState = .extended
                self.urlBarTopConstraint.update(offset: 0)
                self.toolbarBottomConstraint.update(inset: 0)
                scrollView.bounds.origin.y += self.scrollBarOffsetAlpha * UIConstants.layout.urlBarHeight
                self.scrollBarOffsetAlpha = 0
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.scrollBarState = .expanded
            }
        )
    }

    // FXIOS-8642 - #19165 ⁃ Integrate scroll controller delegate with Focus iOS
    private func hideToolbars() {
        let scrollView = webViewController.scrollView
        scrollBarState = .animating
        UIView.animate(
            withDuration: UIConstants.layout.urlBarTransitionAnimationDuration,
            delay: 0,
            options: .allowUserInteraction,
            animations: {
                self.urlBar.collapsedState = .collapsed
                self.urlBarTopConstraint.update(offset: -UIConstants.layout.urlBarHeight + UIConstants.layout.collapsedUrlBarHeight)
                self.toolbarBottomConstraint.update(offset: UIConstants.layout.browserToolbarHeight + self.view.safeAreaInsets.bottom)
                scrollView.bounds.origin.y += (self.scrollBarOffsetAlpha - 1) * UIConstants.layout.urlBarHeight
                self.scrollBarOffsetAlpha = 1
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.scrollBarState = .collapsed
            }
        )
    }

    private func snapToolbars(scrollView: UIScrollView) {
        guard scrollBarState == .transitioning else { return }

        if scrollBarOffsetAlpha < 0.05 || scrollView.contentOffset.y < UIConstants.layout.urlBarHeight {
            showToolbars()
        } else {
            hideToolbars()
        }
    }
}

extension BrowserViewController: KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        keyboardState = state
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: -state.intersectionHeightForView(view: self.view))
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        keyboardState = state
        self.updateViewConstraints()
        UIView.animate(withDuration: state.animationDuration) {
            self.homeViewBottomConstraint.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {
        if UIDevice.current.userInterfaceIdiom == .pad && !orientationWillChange {
            urlBar.dismiss()
        }
        orientationWillChange = false
    }
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) { }
}

extension BrowserViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        darkView.isHidden = true
    }

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        guard urlBar.inBrowsingMode else { return }
        guard let menuSheet = popoverPresentationController.presentedViewController as? PhotonActionSheet, !(menuSheet.popoverPresentationController?.sourceView is ShortcutView) else {
            return
        }
        view.pointee = self.showsToolsetInURLBar ? urlBar.contextMenuButtonAnchor : browserToolbar.contextMenuButtonAnchor
    }
}

extension BrowserViewController {
    public var eraseIntent: EraseIntent {
        let intent = EraseIntent()
        intent.suggestedInvocationPhrase = "Erase"
        return intent
    }
}

extension BrowserViewController: MenuActionable {
    func openInFirefox(url: URL) {
        guard let escaped = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)&private=true", invalidCharacters: false),
              UIApplication.shared.canOpenURL(firefoxURL) else {
                  return
              }

        UIApplication.shared.open(firefoxURL, options: [:])

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "open_in_firefox"))
    }

    func findInPage() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.findInPageNotification)))

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "find_in_page"))
    }

    func openInDefaultBrowser(url: URL) {
        UIApplication.shared.open(url, options: [:])

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "open_in_default_browser"))
    }

    func openInChrome(url: URL) {
        // Code pulled from https://github.com/GoogleChrome/OpenInChrome
        // Replace the URL Scheme with the Chrome equivalent.
        var chromeScheme: String?
        if url.scheme == "http" {
            chromeScheme = "googlechrome"
        } else if url.scheme == "https" {
            chromeScheme = "googlechromes"
        }

        // Proceed only if a valid Google Chrome URI Scheme is available.
        guard let scheme = chromeScheme,
              let rangeForScheme = url.absoluteString.range(of: ":"),
              let chromeURL = URL(string: scheme + url.absoluteString[rangeForScheme.lowerBound...], invalidCharacters: false) else { return }

        // Open the URL with Chrome.
        UIApplication.shared.open(chromeURL, options: [:])

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "open_in_chrome"))
    }

    var canOpenInFirefox: Bool {
        return UIApplication.shared.canOpenURL(URL(string: "firefox://", invalidCharacters: false)!)
    }

    var canOpenInChrome: Bool {
        return UIApplication.shared.canOpenURL(URL(string: "googlechrome://", invalidCharacters: false)!)
    }

    func requestDesktopBrowsing() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.requestDesktopNotification)))

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "desktop_view_on"))
    }

    func requestMobileBrowsing() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.requestMobileNotification)))

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "desktop_view_off"))
    }

    func showSharePage(for utils: OpenUtils, sender: UIView) {
        let shareVC = utils.buildShareViewController()

        // Exact frame dimensions taken from presentPhotonActionSheet
        shareVC.popoverPresentationController?.sourceView = sender
        shareVC.popoverPresentationController?.sourceRect =
        CGRect(
            x: sender.frame.width/2,
            y: sender.frame.size.height,
            width: 1,
            height: 1
        )

        shareVC.becomeFirstResponder()
        self.present(shareVC, animated: true, completion: nil)

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "share"))
    }

    func showSettings(shouldScrollToSiri: Bool = false) {
        guard let modalDelegate = modalDelegate else { return }

        let settingsViewController = SettingsViewController(
            searchEngineManager: searchEngineManager,
            authenticationManager: authenticationManager,
            onboardingEventsHandler: onboardingEventsHandler,
            themeManager: themeManager,
            dismissScreenCompletion: activateUrlBarOnHomeView,
            shouldScrollToSiri: shouldScrollToSiri
        )
        let settingsNavController = UINavigationController(rootViewController: settingsViewController)
        settingsNavController.modalPresentationStyle = .formSheet

        modalDelegate.presentModal(viewController: settingsNavController, animated: true)

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "settings"))
    }

    func showHelp() {
        submit(text: "https://support.mozilla.org/en-US/products/focus-firefox/Focus-ios", source: .action)
    }

    func showCopy(url: URL) {
        UIPasteboard.general.string = url.absoluteString
        Toast(text: UIConstants.strings.copyURLToast).show()

        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "copy_url"))
    }

    func addToShortcuts(url: URL) {
        Task {
            // FXIOS-8634 - #19156 ⁃ Integrate EngineSession favicon in Focus iOS
            let imageURL = try? await webViewController.getMetadata().icon.flatMap(URL.init(string:))
            let shortcut = Shortcut(url: url, imageURL: imageURL)
            self.shortcutManager.add(shortcutViewModel: .init(shortcut: shortcut))

            GleanMetrics.Shortcuts.shortcutAddedCounter.add()
            TipManager.shortcutsTip = false

            GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "add_to_shortcuts"))
            Toast(text: UIConstants.strings.shareMenuAddToShortcutsConfirmMessage).show()
        }
    }

    func removeShortcut(url: URL) {
        self.shortcutManager.remove(url)
        GleanMetrics.Shortcuts.shortcutRemovedCounter["removed_from_browser_menu"].add()
        GleanMetrics.BrowserMenu.browserMenuAction.record(GleanMetrics.BrowserMenu.BrowserMenuActionExtra(item: "remove_from_shortcuts"))
        Toast(text: UIConstants.strings.shareMenuRemoveShortcutConfirmMessage).show()
    }
}

// MARK: - Shortcuts Actions

extension BrowserViewController {
    func showRenameAlert(shortcut: Shortcut) {
        let alert = UIAlertController.renameAlertController(
            currentName: shortcut.name,
            renameAction: { [weak self] newName in
                guard let self = self else { return }
                self.shortcutManager.rename(shortcut: shortcut, newName: newName)
                self.urlBar.activateTextField()
            }, cancelAction: { [weak self] in
                guard let self = self else { return }
                self.urlBar.activateTextField()
            })
        self.show(alert, sender: nil)
    }

    func removeFromShortcuts() {
        self.shortcutsBackground.isHidden = self.shortcutManager.shortcutsViewModels.isEmpty || !self.urlBar.inBrowsingMode ? true : false
        GleanMetrics.Shortcuts.shortcutRemovedCounter["removed_from_home_screen"].add()
    }

    func dismissShortcut() {
        guard isIPadRegularDimensions else { return }
        urlBarDidDismiss(urlBar)
    }

    func shortcutTapped(url: URL) {
        ensureBrowsingMode()
        urlBar.url = url
        deactivateUrlBarOnHomeView()
        submit(url: url, source: .shortcut)
        GleanMetrics.Shortcuts.shortcutOpenedCounter.add()
    }

    func shortcutDidRemove(shortcut: ShortcutViewModel) {
        for subview in shortcutsContainer.subviews where subview is ShortcutView {
            let subview = subview as? ShortcutView
            if let subviewShortcut = subview?.viewModel, subviewShortcut.shortcut.url == shortcut.shortcut.url {
                subview?.removeFromSuperview()
                shortcutsContainer.addArrangedSubview(UIView())
            }
        }
    }

    func shortcutsDidUpdate() {
        for subview in shortcutsContainer.subviews {
            subview.removeFromSuperview()
        }
        addShortcuts()
    }
}

extension BrowserViewController {
    func openFromWidget() {
        guard !urlBar.isEditing else { return }

        switch scrollBarState {
        case .expanded:
            urlBar.activateTextField()
        case .collapsed: showToolbars()
        default: break
        }
    }
}
