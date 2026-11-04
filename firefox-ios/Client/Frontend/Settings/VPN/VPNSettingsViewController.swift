// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

@available(iOS 17.0, *)
final class VPNSettingsViewController: UIViewController {
    // TODO: replace this with the actual URL eventually
    static let learnMoreURL = SupportUtils.URLForTopic("vpn")

    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let viewModel: VPNSettingsViewModel
    private lazy var hostingController = UIHostingController(
        rootView: VPNSettingsViewContainer(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel,
            viewController: self
        )
    )

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        // TODO: FXIOS-16876 The view model will be held by VPNManager so it can be shared with VPNSetting
        self.viewModel = VPNSettingsViewModel()
        super.init(nibName: nil, bundle: nil)
        self.title = .VPN.Settings.Title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingController()
    }

    private func setupHostingController() {
        guard let hostingView = hostingController.view else { return }
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    func learnMoreTapped() {
        let controller = SettingsContentViewController(windowUUID: windowUUID)
        controller.url = Self.learnMoreURL
        navigationController?.pushViewController(controller, animated: true)
    }
}
