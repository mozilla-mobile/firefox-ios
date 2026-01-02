// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

protocol TabTrayThemeable {
    @MainActor
    func retrieveTheme() -> Theme
    @MainActor
    func applyTheme(_ theme: Theme)
}

final class TabDisplayPanelViewController: UIViewController,
                                     Themeable,
                                     EmptyPrivateTabsViewDelegate,
                                     StoreSubscriber,
                                     FeatureFlaggable,
                                     TabTrayThemeable {
    typealias SubscriberStateType = TabsPanelState

    let panelType: TabTrayPanelType
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var tabsState: TabsPanelState
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private var viewHasAppeared = false

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    private lazy var layout: TabTrayLayoutType = {
        return shouldUseiPadSetup() ? .regular : .compact
    }()

    var isCompactLayout: Bool {
        return layout == .compact
    }

    // MARK: UI elements
    lazy var tabDisplayView: TabDisplayView = {
        let view = TabDisplayView(panelType: self.panelType,
                                  state: self.tabsState,
                                  windowUUID: windowUUID)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var backgroundPrivacyOverlay: UIView = .build()
    private lazy var emptyPrivateTabsView: EmptyPrivateTabView = {
        if isTabTrayUIExperimentsEnabled {
            let view = ExperimentEmptyPrivateTabsView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        } else {
            let view = EmptyPrivateTabsView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
    }()

    private lazy var fadeView: UIView = .build { view in
        view.isUserInteractionEnabled = false
    }

    private lazy var gradientLayer = CAGradientLayer()
    private lazy var statusBarView: UIView = .build { _ in }

    init(isPrivateMode: Bool,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         dragAndDropDelegate: TabDisplayViewDragAndDropInteraction) {
        self.panelType = isPrivateMode ? .privateTabs : .tabs
        self.tabsState = TabsPanelState(windowUUID: windowUUID, isPrivateMode: isPrivateMode)
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        tabDisplayView.dragAndDropDelegate = dragAndDropDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure("TabDisplayPanelViewController was not deallocated on the main thread. Redux was not removed")
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityLabel = .TabsTray.TabTrayViewAccessibilityLabel
        setupView()
        subscribeToRedux()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !viewHasAppeared {
            store.dispatch(TabPanelViewAction(panelType: panelType,
                                              windowUUID: windowUUID,
                                              actionType: TabPanelViewActionType.tabPanelWillAppear))
            viewHasAppeared = true
        }
        updateInsets()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        shouldShowFadeView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = fadeView.bounds
        adjustStatusBarFrameIfNeeded()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.view.safeAreaInsetsDidChange()
        updateInsets()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addSubview(tabDisplayView)
        view.addSubview(backgroundPrivacyOverlay)

        NSLayoutConstraint.activate([
            tabDisplayView.topAnchor.constraint(equalTo: view.topAnchor),
            tabDisplayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabDisplayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabDisplayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backgroundPrivacyOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundPrivacyOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundPrivacyOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundPrivacyOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        backgroundPrivacyOverlay.isHidden = true
        setupEmptyView()
        setupFadeView()
    }

    private func setupEmptyView() {
        guard tabsState.isPrivateMode, tabsState.isPrivateTabsEmpty else {
            shouldShowEmptyView(false)
            return
        }

        emptyPrivateTabsView.delegate = self
        view.insertSubview(emptyPrivateTabsView, aboveSubview: tabDisplayView)
        NSLayoutConstraint.activate([
            emptyPrivateTabsView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyPrivateTabsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyPrivateTabsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyPrivateTabsView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        shouldShowEmptyView(true)
    }

    private func shouldShowEmptyView(_ shouldShowEmptyView: Bool) {
        emptyPrivateTabsView.isHidden = !shouldShowEmptyView
        tabDisplayView.isHidden = shouldShowEmptyView
    }

    func removeTabPanel() {
        guard isViewLoaded else { return }
        view.removeConstraints(view.constraints)
        view.subviews.forEach { $0.removeFromSuperview() }
        view.removeFromSuperview()
    }

    // MARK: - Themeable

    func applyTheme() {
        let theme = retrieveTheme()
        backgroundPrivacyOverlay.backgroundColor = theme.colors.layerScrim
        tabDisplayView.applyTheme(theme: theme)
        emptyPrivateTabsView.applyTheme(theme: theme)
        adjustFadeView(theme: theme)
    }

    var shouldUsePrivateOverride: Bool {
        return featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly)
    }

    var shouldBeInPrivateTheme: Bool {
        let tabTrayState = store.state.screenState(TabTrayState.self, for: .tabsTray, window: windowUUID)
        return tabTrayState?.isPrivateMode ?? false
    }

    // MARK: - Fade view & status bar view

    private func setupFadeView() {
        guard isTabTrayUIExperimentsEnabled, isCompactLayout else { return }
        fadeView.layer.addSublayer(gradientLayer)
        view.addSubview(fadeView)

        NSLayoutConstraint.activate([
            fadeView.topAnchor.constraint(equalTo: view.topAnchor),
            fadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            fadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        shouldShowFadeView()
    }

    private func shouldShowFadeView() {
        guard isTabTrayUIExperimentsEnabled, isCompactLayout else { return }
        let isPrivateModeFadeViewNeeded = !tabsState.tabs.isEmpty && tabsState.isPrivateMode
        let shouldShow = !tabsState.isPrivateMode || isPrivateModeFadeViewNeeded
        fadeView.isHidden = !shouldShow
    }

    // MARK: Themeable

    private func adjustFadeView(theme: Theme) {
        guard isTabTrayUIExperimentsEnabled else { return }

        if UIAccessibility.isReduceTransparencyEnabled {
            gradientLayer.isHidden = true
            if statusBarView.superview == nil {
                view.addSubview(statusBarView)
            }
            statusBarView.backgroundColor = theme.colors.layer3
            adjustStatusBarFrameIfNeeded()
        } else {
            gradientLayer.isHidden = false
            statusBarView.removeFromSuperview()
            gradientLayer.locations = [0.0, 0.12]
            gradientLayer.colors = [
                theme.colors.layer3.cgColor,
                theme.colors.layer3.withAlphaComponent(0.0).cgColor
            ]
        }
    }

    private func adjustStatusBarFrameIfNeeded() {
        guard isTabTrayUIExperimentsEnabled, UIAccessibility.isReduceTransparencyEnabled else { return }

        let isLandscape = UIDevice.current.orientation.isLandscape
        statusBarView.isHidden = isLandscape
        guard !isLandscape else { return }

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height {
            statusBarView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: statusBarHeight)
        }
    }

    private func updateInsets() {
        if isCompactLayout {
            let bottomInset = if emptyPrivateTabsView.needsSafeArea {
                DefaultTabTrayUtils().segmentedControlHeight + view.safeAreaInsets.bottom
            } else {
                DefaultTabTrayUtils().segmentedControlHeight
            }

            emptyPrivateTabsView.updateInsets(top: 0, bottom: bottomInset)
            tabDisplayView.updateInsets(top: 0, bottom: DefaultTabTrayUtils().segmentedControlHeight)
        } else {
            emptyPrivateTabsView.updateInsets(top: view.safeAreaInsets.top, bottom: 0)
            tabDisplayView.updateInsets(top: 0, bottom: 0)
        }
    }

    // MARK: - TabTrayThemeable

    func retrieveTheme() -> Theme {
        if shouldUsePrivateOverride {
            return themeManager.resolvedTheme(with: panelType == .privateTabs)
        } else {
            return themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    func applyTheme(_ theme: Theme) {
        backgroundPrivacyOverlay.backgroundColor = theme.colors.layerScrim
        tabDisplayView.applyTheme(theme: theme)
        emptyPrivateTabsView.applyTheme(theme: theme)

        // Hide the fadeview when animating the transition of panels
        fadeView.isHidden = true
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let screenAction = ScreenAction(windowUUID: windowUUID,
                                        actionType: ScreenActionType.showScreen,
                                        screen: .tabsPanel)
        store.dispatch(screenAction)

        let didLoadAction = TabPanelViewAction(panelType: panelType,
                                               windowUUID: windowUUID,
                                               actionType: TabPanelViewActionType.tabPanelDidLoad)
        store.dispatch(didLoadAction)

        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return TabsPanelState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .tabsPanel)
        store.dispatch(action)
    }

    func newState(state: TabsPanelState) {
        guard state != tabsState else { return }

        tabsState = state
        tabDisplayView.newState(state: tabsState)
        if panelType == .privateTabs, tabsState.isPrivateMode {
            // Only adjust the empty view if we are in private mode
            shouldShowEmptyView(tabsState.isPrivateTabsEmpty)
        }
        shouldShowFadeView()

        if shouldUsePrivateOverride {
            applyTheme()
        }
    }

    // MARK: - EmptyPrivateTabsViewDelegate

    func didTapLearnMore(urlRequest: URLRequest) {
        let action = TabPanelViewAction(panelType: panelType,
                                        urlRequest: urlRequest,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.learnMorePrivateMode)
        store.dispatch(action)
    }
}
