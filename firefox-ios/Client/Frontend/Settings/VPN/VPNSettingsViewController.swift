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
        prefs: Prefs,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        // TODO: FXIOS-16876 The view model will be held by VPNManager so it can be shared with VPNSetting
        self.viewModel = VPNSettingsViewModel(prefs: prefs, localeProvider: localeProvider)
        super.init(nibName: nil, bundle: nil)
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
        hostingView.frame = view.bounds
        hostingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addChild(hostingController)
        view.addSubview(hostingView)
        hostingController.didMove(toParent: self)
    }

    func learnMoreTapped() {
        let controller = SettingsContentViewController(windowUUID: windowUUID)
        controller.url = Self.learnMoreURL
        navigationController?.pushViewController(controller, animated: true)
    }
}
