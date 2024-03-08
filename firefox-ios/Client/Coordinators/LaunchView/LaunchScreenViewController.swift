// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class LaunchScreenViewController: UIViewController, LaunchFinishedLoadingDelegate, FeatureFlaggable {
    private lazy var launchScreen = LaunchScreenView.fromNib()
    private weak var coordinator: LaunchFinishedLoadingDelegate?
    private var viewModel: LaunchScreenViewModel
    private var mainQueue: DispatchQueueInterface

    private lazy var splashScreenAnimation = SplashScreenAnimation()
    private let nimbusSplashScreenFeatureLayer = NimbusSplashScreenFeatureLayer()

    init(coordinator: LaunchFinishedLoadingDelegate,
         viewModel: LaunchScreenViewModel = LaunchScreenViewModel(),
         mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.mainQueue = mainQueue
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
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
        view.backgroundColor = .systemBackground

        Task {
            try await delayStart()
            await startLoading()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLaunchScreen()
    }

    // MARK: - Loading
    func startLoading() async {
        await viewModel.startLoading()
    }

    // MARK: - Setup

    private func setupLayout() {
        launchScreen.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(launchScreen)

        NSLayoutConstraint.activate([
            launchScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            launchScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            launchScreen.topAnchor.constraint(equalTo: view.topAnchor),
            launchScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        mainQueue.async {
            self.coordinator?.launchWith(launchType: launchType)
        }
    }

    func launchBrowser() {
        mainQueue.async {
            self.coordinator?.launchBrowser()
        }
    }

    // MARK: - Splash Screen

    private func delayStart() async throws {
        guard featureFlags.isFeatureEnabled(.splashScreen, checking: .buildOnly) else { return }
        let position: Int = nimbusSplashScreenFeatureLayer.maximumDurationMs
        try await Task.sleep(nanoseconds: UInt64(position * 1_000_000))
    }

    private func setupLaunchScreen() {
        setupLayout()
        guard featureFlags.isFeatureEnabled(.splashScreen, checking: .buildOnly) else { return }
        if !UIAccessibility.isReduceMotionEnabled {
            splashScreenAnimation.configureAnimation(with: launchScreen)
        }
    }
}
