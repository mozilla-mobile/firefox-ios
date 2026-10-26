// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

final class VPNSettingsViewController: UIViewController {
    // TODO: replace this with the actual URL eventually
    static let learnMoreURL = SupportUtils.URLForTopic("vpn")

    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let prefs: Prefs
    private lazy var hostingController = UIHostingController(
        rootView: VPNSettingsViewContainer(
            windowUUID: windowUUID,
            themeManager: themeManager,
            isVPNEnabled: prefs.boolForKey(PrefsKeys.VPNSettings.isEnabled) ?? false,
            onVPNToggled: { [prefs = self.prefs] isEnabled in
                prefs.setBool(isEnabled, forKey: PrefsKeys.VPNSettings.isEnabled)
            },
            onLearnMoreTapped: { [weak self] in
                self?.learnMoreTapped()
            }
        )
    )

    init(
        windowUUID: WindowUUID,
        prefs: Prefs,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.windowUUID = windowUUID
        self.prefs = prefs
        self.themeManager = themeManager
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

    private func learnMoreTapped() {
        let controller = SettingsContentViewController(windowUUID: windowUUID)
        controller.url = Self.learnMoreURL
        navigationController?.pushViewController(controller, animated: true)
    }
}
