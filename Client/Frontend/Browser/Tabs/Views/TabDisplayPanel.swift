// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Storage
import UIKit

class TabDisplayPanel: UIViewController,
                                Themeable,
                                EmptyPrivateTabsViewDelegate,
                                StoreSubscriber {
    typealias SubscriberStateType = TabsPanelState
    struct UX {
        static let undoToastDelay = DispatchTimeInterval.seconds(0)
        static let undoToastDuration = DispatchTimeInterval.seconds(3)
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var tabsState: TabsPanelState

    // MARK: UI elements
    private lazy var tabDisplayView: TabDisplayView = {
        let view = TabDisplayView(state: self.tabsState, tabPeekDelegate: self)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var backgroundPrivacyOverlay: UIView = .build()
    private lazy var emptyPrivateTabsView: EmptyPrivateTabsView = .build()
    var shownToast: Toast?

    var toolbarHeight: CGFloat {
        return !shouldUseiPadSetup() ? view.safeAreaInsets.bottom : 0
    }

    init(isPrivateMode: Bool,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.tabsState = TabsPanelState(isPrivateMode: isPrivateMode)
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
        subscribeToRedux()
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

    func applyTheme() {
        backgroundPrivacyOverlay.backgroundColor = themeManager.currentTheme.colors.layerScrim
        tabDisplayView.applyTheme(theme: themeManager.currentTheme)
        emptyPrivateTabsView.applyTheme(themeManager.currentTheme)
    }

    private func presentToast(toastType: ToastType,
                              completion: @escaping (Bool) -> Void) {
        if let currentToast = shownToast {
            currentToast.dismiss(false)
        }

        if toastType.reduxAction != nil {
            let viewModel = ButtonToastViewModel(
                labelText: toastType.title,
                buttonText: toastType.buttonText)
            let toast = ButtonToast(viewModel: viewModel,
                                    theme: themeManager.currentTheme,
                                    completion: { buttonPressed in
                completion(buttonPressed)
            })
            toast.showToast(viewController: self,
                            delay: UX.undoToastDelay,
                            duration: UX.undoToastDuration) { toast in
                [
                    toast.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    toast.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    toast.bottomAnchor.constraint(equalTo: self.view.bottomAnchor,
                                                  constant: -self.toolbarHeight)
                ]
            }
            shownToast = toast
        } else {
            let toast = SimpleToast()
            toast.showAlertWithText(toastType.title,
                                    bottomContainer: view,
                                    theme: themeManager.currentTheme,
                                    bottomConstraintPadding: -toolbarHeight)
        }
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

        // Avoid showing toast multiple times
        if let toastType = tabsState.toastType,
            shownToast == nil {
            store.dispatch(TabPanelAction.hideUndoToast)
            presentToast(toastType: toastType) { undoClose in
                if let action = toastType.reduxAction, undoClose {
                    store.dispatch(action)
                }
                self.shownToast = nil
            }
        }
    }

    // MARK: EmptyPrivateTabsViewDelegate

    func didTapLearnMore(urlRequest: URLRequest) {
        store.dispatch(TabPanelAction.learnMorePrivateMode(urlRequest))
    }
}

extension TabDisplayPanel: LegacyTabPeekDelegate {
    func tabPeekDidAddToReadingList(_ tab: Tab) -> ReadingListItem? { return nil }
    func tabPeekDidAddBookmark(_ tab: Tab) {}
    func tabPeekRequestsPresentationOf(_ viewController: UIViewController) {}
    func tabPeekDidCloseTab(_ tab: Tab) {}
    func tabPeekDidCopyUrl() {}
}
