// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux
import MenuKit

class MainMenuViewController: UIViewController,
                              Themeable,
                              Notifiable,
                              UIAdaptivePresentationControllerDelegate,
                              UISheetPresentationControllerDelegate,
                              UIScrollViewDelegate,
                              StoreSubscriber {
    typealias SubscriberStateType = MainMenuState

    // MARK: - UI/UX elements
    private struct UX {
        static let closeButtonWidthHeight: CGFloat = 30
        static let scrollContentStackSpacing: CGFloat = 16
    }

    private lazy var menuContent: MenuView = .build()
    private lazy var scrollView: UIScrollView = .build()

    private lazy var closeButton: CloseButton = .build { view in
        let viewModel = CloseButtonViewModel(
            a11yLabel: .Shopping.CloseButtonAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.Shopping.sheetCloseButton
        )
        view.configure(viewModel: viewModel)
        view.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

    private lazy var testButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.testButtonTapped), for: .touchUpInside)
        button.backgroundColor = .systemPink
    }

    // MARK: - Properties
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    weak var coordinator: MainMenuCoordinator?

    private let windowUUID: WindowUUID
    private var viewModel: MainMenuViewModel
    private var menuState: MainMenuState

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        viewModel: MainMenuViewModel,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        menuState = MainMenuState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        subscribeToRedux()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle & setup
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self
        scrollView.delegate = self

        setupView()
        listenForThemeChange(view)
        store.dispatch(
            MainMenuAction(
                windowUUID: self.windowUUID,
                actionType: MainMenuActionType.viewDidLoad
            )
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.mainMenuDidAppear
            )
        )
        updateModalA11y()
    }

    deinit {
        unsubscribeFromRedux()
    }

    // MARK: - UI setup
    private func setupView() {
        menuContent.updateDataSource(with: menuState.menuElements)
        view.addSubview(menuContent)

        NSLayoutConstraint.activate([
            menuContent.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuContent.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            menuContent.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuContent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func updateContent() {
        applyTheme()
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.showScreen,
                                  screen: .mainMenu)
        store.dispatch(action)
        let uuid = windowUUID
        store.subscribe(self, transform: {
            return $0.select({ appState in
                return MainMenuState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .mainMenu)
        store.dispatch(action)
    }

    func newState(state: MainMenuState) {
        menuState = state

        menuContent.updateDataSource(with: menuState.menuElements)

        if menuState.shouldDismiss {
            coordinator?.dismissModal(animated: true)
        }
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = .systemPurple//theme.colors.layer1
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) { }

    @objc
    private func closeTapped() { }

    @objc
    private func testButtonTapped() {
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.closeMenu
            )
        )
    }

    // In iOS 15 modals with a large detent read content underneath the modal
    // in voice over. To prevent this we manually turn this off.
    private func updateModalA11y() {
        var currentDetent: UISheetPresentationController.Detent.Identifier? = viewModel.getCurrentDetent(
            for: sheetPresentationController
        )

        if currentDetent == nil,
           let sheetPresentationController,
           let firstDetent = sheetPresentationController.detents.first {
            if firstDetent == .medium() {
                currentDetent = .medium
            } else if firstDetent == .large() {
                currentDetent = .large
            }
        }

        view.accessibilityViewIsModal = currentDetent == .large ? true : false
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        coordinator?.dismissModal(animated: true)
    }

    // MARK: - UISheetPresentationControllerDelegate
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        updateModalA11y()
    }
}
