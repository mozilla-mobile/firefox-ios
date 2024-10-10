// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit
import Shared

class ContextualHintViewController: UIViewController,
                                    OnViewDismissable,
                                    Themeable,
                                    UIAdaptivePresentationControllerDelegate {
    private struct UX {
        static let contextualHintWidth: CGFloat = 350
        static let contextualHintLandscapeExtraWidth: CGFloat = 60
    }

    // MARK: - UI Elements
    private lazy var hintView: ContextualHintView = .build { _ in }

    // MARK: - Properties
    private var viewProvider: ContextualHintViewProvider
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    private let windowUUID: WindowUUID

    private var onViewSummoned: (() -> Void)?
    var onViewDismissed: (() -> Void)?
    private var onActionTapped: (() -> Void)?

    var isPresenting = false

    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - Initializers
    init(with viewProvider: ContextualHintViewProvider,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewProvider = viewProvider
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        listenForThemeChange(view)
        applyTheme()
        isPresenting = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewSummoned?()
        onViewSummoned = nil
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewProvider.markContextualHintPresented()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let targetSize = CGSize(width: UX.contextualHintWidth, height: UIView.layoutFittingCompressedSize.height)
        var systemSize = hintView.systemLayoutSizeFitting(targetSize)
        if UIWindow.isLandscape {
            systemSize.width += UX.contextualHintLandscapeExtraWidth
        }
        preferredContentSize = systemSize
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewProvider.sendTelemetryEvent(for: .tapToDismiss)
        isPresenting = false
        onViewDismissed?()
        onViewDismissed = nil
    }

    private func commonInit() {
        setupConstraints()
    }

    private func setupConstraints() {
        view.addSubview(hintView)

        NSLayoutConstraint.activate([
            hintView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hintView.topAnchor.constraint(equalTo: view.topAnchor),
            hintView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hintView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Button Actions
    private func dismissAnimated() {
        viewProvider.sendTelemetryEvent(for: .closeButton)
        self.dismiss(animated: true, completion: nil)
    }

    private func performAction() {
        self.viewProvider.sendTelemetryEvent(for: .performAction)
        self.dismiss(animated: true) {
            self.onActionTapped?()
            self.onActionTapped = nil
        }
    }

    // MARK: - Interface
    func shouldPresentHint() -> Bool {
        return viewProvider.shouldPresentContextualHint()
    }

    func configure(
        anchor: UIView,
        withArrowDirection arrowDirection: UIPopoverArrowDirection,
        andDelegate delegate: UIPopoverPresentationControllerDelegate? = nil,
        presentedUsing presentation: (() -> Void)?,
        sourceRect: CGRect = CGRect.null,
        withActionBeforeAppearing preAction: (() -> Void)? = nil,
        actionOnDismiss postAction: (() -> Void)? = nil,
        andActionForButton buttonAction: (() -> Void)? = nil,
        andShouldStartTimerRightAway shouldStartTimer: Bool = true,
        overlayState: OverlayStateProtocol? = nil,
        ignoreSafeArea: Bool = false,
        rightSafeAreaMargin: CGFloat? = nil
    ) {
        stopTimer()
        modalPresentationStyle = .popover
        popoverPresentationController?.sourceRect = sourceRect
        popoverPresentationController?.sourceView = anchor
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        popoverPresentationController?.delegate = delegate

        if ignoreSafeArea {
            popoverPresentationController?.popoverLayoutMargins = UIEdgeInsets(
                top: -anchor.safeAreaInsets.top,
                left: -anchor.safeAreaInsets.left,
                bottom: -anchor.safeAreaInsets.bottom,
                right: -(rightSafeAreaMargin ?? anchor.safeAreaInsets.right)
            )
        }

        onViewSummoned = preAction
        onViewDismissed = postAction
        onActionTapped = buttonAction
        viewProvider.presentFromTimer = presentation
        viewProvider.arrowDirection = arrowDirection
        viewProvider.overlayState = overlayState

        if delegate == nil { presentationController?.delegate = self }

        var viewModel = ContextualHintViewModel(
            isActionType: viewProvider.isActionType,
            actionButtonTitle: viewProvider.getCopyFor(.action),
            title: viewProvider.getCopyFor(.title),
            description: viewProvider.getCopyFor(.description),
            arrowDirection: arrowDirection,
            closeButtonA11yLabel: .ContextualHints.ContextualHintsCloseAccessibility,
            actionButtonA11yId: AccessibilityIdentifiers.ContextualHints.actionButton
        )
        viewModel.closeButtonAction = { [weak self] _ in
            self?.dismissAnimated()
        }
        viewModel.actionButtonAction = { [weak self] _ in
            self?.performAction()
        }
        hintView.configure(viewModel: viewModel)
        applyTheme()

        if shouldStartTimer {
            viewProvider.startTimer()
        }

        viewProvider.markContextualHintConfiguration(configured: true)
    }

    func unconfigure() {
        viewProvider.markContextualHintConfiguration(configured: false)
    }

    func stopTimer() {
        viewProvider.stopTimer()
    }

    func startTimer() {
        viewProvider.startTimer()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        hintView.applyTheme(theme: theme)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsLayout()
    }
}
