// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import UIKit

class TabDisplayViewController: UIViewController,
                                Themeable,
                                EmptyPrivateTabsViewDelegate,
                                StoreSubscriber {
    typealias SubscriberStateType = TabsState
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var navigationHandler: TabsNavigationHandler?

    // MARK: UI elements
    lazy var tabDisplayView: TabDisplayView = {
        let view = TabDisplayView(state: self.tabsState)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var backgroundPrivacyOverlay: UIView = .build()
    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = .build()

<<<<<<< HEAD:Client/Frontend/Browser/Tabs/TabDisplayViewController.swift
    // MARK: Redux state
    var tabsState: TabsState
=======
    var tabsState: TabsPanelState
>>>>>>> b7db64ae9 (Refactor FXIOS-7853 [v122] Redux pattern protocol improvements (#17542)):Client/Frontend/Browser/Tabs/Views/TabDisplayPanel.swift

    init(isPrivateMode: Bool,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        // TODO: FXIOS-6936 Integrate Redux state
        self.tabsState = TabsState(isPrivateMode: isPrivateMode)
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        unsubscribeFromRedux()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        listenForThemeChange(view)
        applyTheme()
<<<<<<< HEAD:Client/Frontend/Browser/Tabs/TabDisplayViewController.swift
        subscribeRedux()
    }

    private func subscribeRedux() {
        store.dispatch(ActiveScreensStateAction.showScreen(.tabsPanel))
        store.dispatch(TabPanelAction.tabPanelDidLoad(tabsState.isPrivateMode))
        store.subscribe(self, transform: {
            return $0.select(TabsState.init)
        })
    }

    func newState(state: TabsState) {
        tabsState = state
        tabDisplayView.newState(state: tabsState)
        shouldShowEmptyView(tabsState.isPrivateTabsEmpty)
=======
        subscribeToRedux()
>>>>>>> b7db64ae9 (Refactor FXIOS-7853 [v122] Redux pattern protocol improvements (#17542)):Client/Frontend/Browser/Tabs/Views/TabDisplayPanel.swift
    }

    func setupView() {
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
    }

    func setupEmptyView() {
        guard tabsState.isPrivateMode, tabsState.isPrivateTabsEmpty else {
            shouldShowEmptyView(false)
            return
        }

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

    func applyTheme() {
        backgroundPrivacyOverlay.backgroundColor = themeManager.currentTheme.colors.layerScrim
        tabDisplayView.applyTheme(theme: themeManager.currentTheme)
    }

    // MARK: - Redux

    func subscribeToRedux() {
        store.dispatch(ActiveScreensStateAction.showScreen(.tabsPanel))
        store.dispatch(TabPanelAction.tabPanelDidLoad(tabsState.isPrivateMode))
        store.subscribe(self, transform: {
            return $0.select(TabsPanelState.init)
        })
    }

    func unsubscribeFromRedux() {
        store.dispatch(ActiveScreensStateAction.closeScreen(.tabsPanel))
        store.unsubscribe(self)
    }

    func newState(state: TabsPanelState) {
        tabsState = state
        tabDisplayView.newState(state: tabsState)
        shouldShowEmptyView(tabsState.isPrivateTabsEmpty)
    }

    // MARK: EmptyPrivateTabsViewDelegate
<<<<<<< HEAD:Client/Frontend/Browser/Tabs/TabDisplayViewController.swift
    func didTapLearnMore(urlRequest: URLRequest) {}
=======

    func didTapLearnMore(urlRequest: URLRequest) {
        store.dispatch(TabPanelAction.learnMorePrivateMode(urlRequest))
    }
}

extension TabDisplayPanel: TabPeekDelegate {
    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? { return nil }
    func tabPeekDidAddBookmark(_ tab: Tab) {}
    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {}
    func tabPeekDidCloseTab(_ tab: Tab) {}
    func tabPeekDidCopyUrl() {}
>>>>>>> b7db64ae9 (Refactor FXIOS-7853 [v122] Redux pattern protocol improvements (#17542)):Client/Frontend/Browser/Tabs/Views/TabDisplayPanel.swift
}
