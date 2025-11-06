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
        static let logoSize: CGFloat = 125.0
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
    private let loaderView: LaunchScreenLoaderView = .build {
        $0.isAccessibilityElement = false
    }
    private lazy var backgroundViewController: UIHostingController<LaunchScreenBackgroundView> = {
        let controller = UIHostingController(
            rootView: LaunchScreenBackgroundView(windowUUID: windowUUID, themeManager: themeManager)
        )
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
        loaderView.startAnimating()
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

    // MARK: - Loading
    func startLoading() {
        isLoading = true
        viewModel.startLoading()
    }

    // MARK: - Setup
    private func setupLayout() {
        addChild(backgroundViewController)
        view.addSubviews(backgroundViewController.view, loaderView)
        backgroundViewController.didMove(toParent: self)

        backgroundViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loaderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loaderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loaderView.heightAnchor.constraint(lessThanOrEqualToConstant: UX.logoSize),
            loaderView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.logoSize)
        ])
    }

    // MARK: - LaunchFinishedLoadingDelegate
    func launchWith(launchType: LaunchType) {
        coordinator?.launchWith(launchType: launchType)
    }

    func launchBrowser() {
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

    func loadNextLaunchType() {
        loaderView.startAnimating()
        viewModel.loadNextLaunchType()
    }

    // MARK: - Themeable Protocol

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.gradientOnboardingStop3
    }
}
