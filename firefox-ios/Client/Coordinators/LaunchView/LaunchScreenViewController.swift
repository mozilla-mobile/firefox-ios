// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class LaunchScreenViewController: UIViewController, LaunchFinishedLoadingDelegate, FeatureFlaggable {
    private lazy var launchScreen = LaunchScreenView.fromNib()
    private weak var coordinator: LaunchFinishedLoadingDelegate?
    private var viewModel: LaunchScreenViewModel

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
        startLoading()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadNextLaunchType()
    }

    // MARK: - Loading

    func startLoading() {
        viewModel.startLoading()
        setupLayout()
    }

    // MARK: - Setup

    private func setupLayout() {
        guard let launchScreen = launchScreen else {
            fatalError("LaunchScreen view is nil during layout setup")
        }

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
        self.coordinator?.launchWith(launchType: launchType)
    }

    func launchBrowser() {
        self.coordinator?.launchBrowser()
    }

    func finishedLoadingLaunchOrder() {
        viewModel.loadNextLaunchType()
    }
}
