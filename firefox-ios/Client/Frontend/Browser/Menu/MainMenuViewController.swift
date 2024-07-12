// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

class MainMenuViewController: UIViewController,
                              Themeable,
                              Notifiable,
                              UIAdaptivePresentationControllerDelegate,
                              UISheetPresentationControllerDelegate,
                              UIScrollViewDelegate,
                              StoreSubscriber {
    typealias SubscriberStateType = BrowserViewControllerState

    private struct UX {
        static let titleStackSpacing: CGFloat = 8
        static let closeButtonWidthHeight: CGFloat = 30
        static let scrollContentStackSpacing: CGFloat = 16
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let animationDuration: TimeInterval = 0.2
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    private var viewModel: MainMenuViewModel
    private let windowUUID: WindowUUID

    var currentWindowUUID: UUID? { return windowUUID }

    private lazy var scrollView: UIScrollView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.scrollContentStackSpacing
    }

    private lazy var closeButton: CloseButton = .build { view in
        let viewModel = CloseButtonViewModel(
            a11yLabel: .Shopping.CloseButtonAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.Shopping.sheetCloseButton
        )
        view.configure(viewModel: viewModel)
        view.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

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
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self
        scrollView.delegate = self

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        setupView()
        listenForThemeChange(view)
        subscribeToRedux()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.isSwiping = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidAppear, withObject: windowUUID)
        updateModalA11y()

        let action = FakespotAction(windowUUID: windowUUID,
                                    actionType: FakespotActionType.surfaceDisplayedEventSend)
        store.dispatch(action)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidDismiss, withObject: windowUUID)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        viewModel.isSwiping = true
    }

    // MARK: - View setup
    private func setupView() { }

    private func updateContent() {
        contentStackView.removeAllArrangedViews()
        applyTheme()
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return BrowserViewControllerState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: BrowserViewControllerState) {
    }

    // MARK: - UX related
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    // MARK: - Notifications
    func handleNotifications(_ notification: Notification) { }

    @objc
    private func closeTapped() {
        triggerDismiss()
    }

    private func triggerDismiss() {
        let action = FakespotAction(windowUUID: windowUUID,
                                    actionType: FakespotActionType.dismiss)
        store.dispatch(action)
    }

    deinit {
        unsubscribeFromRedux()
    }

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

        // in iOS 15 modals with a large detent read content underneath the modal in voice over
        // to prevent this we manually turn this off
        view.accessibilityViewIsModal = currentDetent == .large ? true : false
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        triggerDismiss()
    }

    // MARK: - UISheetPresentationControllerDelegate
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        updateModalA11y()
    }
}
