// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class LaunchScreenViewController: UIViewController, LaunchFinishedLoadingDelegate, FeatureFlaggable {
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private lazy var launchScreen: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "splash"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private weak var coordinator: LaunchFinishedLoadingDelegate?
    private var viewModel: LaunchScreenViewModel

    private lazy var splashScreenAnimation = SplashScreenAnimation()
    private let nimbusSplashScreenFeatureLayer = NimbusSplashScreenFeatureLayer()

    private var shouldTriggerSplashScreenExperiment: Bool {
        return featureFlags.isFeatureEnabled(.splashScreen, checking: .buildOnly)
        && !viewModel.getSplashScreenExperimentHasShown()
    }

    private var isViewSetupComplete = false

    init(windowUUID: WindowUUID,
         coordinator: LaunchFinishedLoadingDelegate,
         viewModel: LaunchScreenViewModel? = nil) {
        self.coordinator = coordinator
        self.viewModel = viewModel ?? LaunchScreenViewModel(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    override var prefersStatusBarHidden: Bool {
        return false
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
            startLoading()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !isViewSetupComplete {
            setupLaunchScreen()
            isViewSetupComplete = true
        }

        viewModel.loadNextLaunchType()
    }

    // MARK: - Loading
    func startLoading() {
        viewModel.startLoading()
    }

    // MARK: - Setup

    private func setupLayout() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)

        launchScreen.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(launchScreen)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            launchScreen.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            launchScreen.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            launchScreen.widthAnchor.constraint(equalToConstant: 130),
            launchScreen.heightAnchor.constraint(equalToConstant: 130)
        ])
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchWith(launchType: LaunchType) {
        self.coordinator?.launchWith(launchType: launchType)
    }

    func launchBrowser() {
        guard let window = view.window else {
            coordinator?.launchBrowser()
            return
        }

        // First, set the browser as root without animation
        coordinator?.launchBrowser()

        // Create a snapshot of our launch screen to animate on top
        guard let snapshotView = view.snapshotView(afterScreenUpdates: false) else { return }
        window.addSubview(snapshotView)

        // Animate the snapshot scaling and fading, revealing the browser underneath
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: .curveEaseIn,
            animations: {
                snapshotView.transform = .identity.scaledBy(x: 20.0, y: 20.0)
                snapshotView.alpha = 0.0
            }, completion: { _ in
            snapshotView.removeFromSuperview()
            })
    }

    deinit {
        print("FF: deinti LaunchScreenViewController")
    }

    func finishedLoadingLaunchOrder() {
        viewModel.loadNextLaunchType()
    }

    // MARK: - Splash Screen

    private func delayStart() async throws {
        guard shouldTriggerSplashScreenExperiment else { return }
        viewModel.setSplashScreenExperimentHasShown()
        let position: Int = nimbusSplashScreenFeatureLayer.maximumDurationMs
        try await Task.sleep(nanoseconds: UInt64(position * 1_000_000))
    }

    private func setupLaunchScreen() {
        setupLayout()
        guard shouldTriggerSplashScreenExperiment else { return }
        if !UIAccessibility.isReduceMotionEnabled {
            splashScreenAnimation.configureAnimation(with: launchScreen)
        }
    }
}
