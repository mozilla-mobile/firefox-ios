// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class LaunchScreenViewController: UIViewController {
    private var viewModel: LaunchScreenViewModel
    private lazy var launchScreen = LaunchScreenView.fromNib()

    init(viewModel: LaunchScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

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
}
