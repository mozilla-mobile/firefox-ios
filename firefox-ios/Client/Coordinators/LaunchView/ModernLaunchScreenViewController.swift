// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import SwiftUI
import OnboardingKit

class ModernLaunchScreenViewController: UIViewController, LaunchFinishedLoadingDelegate, FeatureFlaggable, Themeable {
    // MARK: - UX Constants
    private enum UX {
        static let fadeOutDuration: TimeInterval = 0.24
        static let fadeOutDelay: TimeInterval = 0
        static let fadeOutAlpha: CGFloat = 0.0
        static let minimumDisplayTimeSeconds: TimeInterval = 0.1
    }

    private weak var coordinator: LaunchFinishedLoadingDelegate?
    private var viewModel: LaunchScreenViewModel
    private let windowUUID: WindowUUID

    // MARK: - Themeable Properties
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var currentWindowUUID: WindowUUID? { return windowUUID }

    // MARK: - Dependencies
    private let notificationCenter: NotificationProtocol

    // MARK: - Synchronization
    private var isLoading = false
    private var shouldLoadNextLaunchType = false

    // MARK: - UI Components
    private lazy var modernLaunchView: ModernLaunchScreenView = {
        return ModernLaunchScreenView(windowUUID: windowUUID, themeManager: themeManager)
    }()

    private lazy var hostingController: UIHostingController<ModernLaunchScreenView> = {
        let controller = UIHostingController(rootView: modernLaunchView)
        controller.view.backgroundColor = .clear
        return controller
    }()

    init(
        windowUUID: WindowUUID,
        coordinator: LaunchFinishedLoadingDelegate,
        viewModel: LaunchScreenViewModel? = nil,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.coordinator = coordinator
        self.viewModel = viewModel ?? LaunchScreenViewModel(windowUUID: windowUUID)
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - View cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        startLoading()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: FXIOS-13434 Refactor the `LaunchScreenViewModel` to enhance the logic
        // making it easier to comprehend and facilitating unit testing.
        // Only load next launch type if loading is complete, otherwise defer it
        if isLoading {
            shouldLoadNextLaunchType = true
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + UX.minimumDisplayTimeSeconds) { [weak self] in
                self?.viewModel.loadNextLaunchType()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLoaderAnimation()
    }

    // MARK: - Loading
    func startLoading() {
        isLoading = true
        viewModel.startLoading()
    }

    // MARK: - Setup
    private func setupLayout() {
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Animation Control
    func startLoaderAnimation() {
        modernLaunchView.startAnimation()
    }

    func stopLoaderAnimation() {
        modernLaunchView.stopAnimation()
    }

    func fadeOutLoader(completion: (() -> Void)? = nil) {
        stopLoaderAnimation()

        UIView.animate(
            withDuration: UX.fadeOutDuration,
            delay: UX.fadeOutDelay,
            options: [.curveEaseOut]
        ) {
            self.hostingController.view.alpha = UX.fadeOutAlpha
        } completion: { _ in
            completion?()
        }
    }

    // MARK: - LaunchFinishedLoadingDelegate
    func launchWith(launchType: LaunchType) {
        stopLoaderAnimation()
        coordinator?.launchWith(launchType: launchType)
    }

    func launchBrowser() {
        stopLoaderAnimation()
        coordinator?.launchBrowser()
    }

    func finishedLoadingLaunchOrder() {
        isLoading = false

        // If viewWillAppear was called while we were loading, now process the deferred call
        if shouldLoadNextLaunchType {
            shouldLoadNextLaunchType = false
            viewModel.loadNextLaunchType()
        }
    }

    // MARK: - Themeable Protocol

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }
}
