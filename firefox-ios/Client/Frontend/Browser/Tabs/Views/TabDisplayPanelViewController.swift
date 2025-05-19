// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

class TabDisplayPanelViewController: UIViewController,
                                     Themeable,
                                     EmptyPrivateTabsViewDelegate,
                                     StoreSubscriber,
                                     FeatureFlaggable {
    typealias SubscriberStateType = TabsPanelState

    let panelType: TabTrayPanelType
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var tabsState: TabsPanelState
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private var viewHasAppeared = false

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    private var isToolbarRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = fadeView.bounds
    }

    init(isPrivateMode: Bool,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.panelType = isPrivateMode ? .privateTabs : .tabs
        self.tabsState = TabsPanelState(windowUUID: windowUUID, isPrivateMode: isPrivateMode)
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func removeTabPanel() {
        guard isViewLoaded else { return }
        view.removeConstraints(view.constraints)
        view.subviews.forEach { $0.removeFromSuperview() }
        view.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityLabel = .TabsTray.TabTrayViewAccessibilityLabel
        setupView()
        listenForThemeChange(view)
        applyTheme()
        subscribeToRedux()

        if !tabDisplayView.shouldHideInactiveTabs {
            InactiveTabsTelemetry().sectionShown()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !viewHasAppeared {
            store.dispatch(TabPanelViewAction(panelType: panelType,
                                              windowUUID: windowUUID,
                                              actionType: TabPanelViewActionType.tabPanelWillAppear))
            viewHasAppeared = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isToolbarRefactorEnabled, isTabTrayUIExperimentsEnabled else { return }
        store.dispatch(
            ToolbarAction(
                shouldAnimate: true,
                windowUUID: windowUUID,
                actionType: ToolbarActionType.animationStateChanged
            )
        )
    }

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

    private func setupFadeView() {
        guard isTabTrayUIExperimentsEnabled, isCompactLayout else { return }
        gradientLayer.locations = [0.0, 0.02, 0.08, 0.12]
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

    private func retrieveTheme() -> Theme {
        if featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
            return themeManager.resolvedTheme(with: tabsState.isPrivateMode)
        } else {
            return themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    // MARK: Themeable
    var shouldUsePrivateOverride: Bool {
        return featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) ? true : false
    }

    var shouldBeInPrivateTheme: Bool {
        let tabTrayState = store.state.screenState(TabTrayState.self, for: .tabsTray, window: windowUUID)
        return tabTrayState?.isPrivateMode ?? false
    }

    func applyTheme() {
        let theme = retrieveTheme()
        backgroundPrivacyOverlay.backgroundColor = theme.colors.layerScrim
        tabDisplayView.applyTheme(theme: theme)
        emptyPrivateTabsView.applyTheme(theme: theme)

        if isTabTrayUIExperimentsEnabled {
            gradientLayer.colors = [
                theme.colors.layer3.cgColor,
                theme.colors.layer3.cgColor,
                theme.colors.layer3.withAlphaComponent(0.95).cgColor,
                theme.colors.layer3.withAlphaComponent(0.0).cgColor
            ]
        }
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
        shouldShowEmptyView(tabsState.isPrivateTabsEmpty)
        shouldShowFadeView()

        if featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
            applyTheme()
        }
    }

    // MARK: EmptyPrivateTabsViewDelegate

    func didTapLearnMore(urlRequest: URLRequest) {
        let action = TabPanelViewAction(panelType: panelType,
                                        urlRequest: urlRequest,
                                        windowUUID: windowUUID,
                                        actionType: TabPanelViewActionType.learnMorePrivateMode)
        store.dispatch(action)
    }
}
