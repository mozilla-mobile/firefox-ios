// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

final class VPNLocationsViewController: UIViewController {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let localeProvider: LocaleProvider
    private let selectedRegionCode: String
    private let onLocationSelected: (String) -> Void
    private lazy var hostingController = UIHostingController(
        rootView: VPNLocationsView(
            windowUUID: windowUUID,
            themeManager: themeManager,
            selectedRegionCode: selectedRegionCode,
            localeProvider: localeProvider,
            onLocationSelected: onLocationSelected
        )
    )

    init(
        windowUUID: WindowUUID,
        selectedRegionCode: String,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        localeProvider: LocaleProvider = SystemLocaleProvider(),
        onLocationSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.windowUUID = windowUUID
        self.selectedRegionCode = selectedRegionCode
        self.themeManager = themeManager
        self.localeProvider = localeProvider
        self.onLocationSelected = onLocationSelected
        super.init(nibName: nil, bundle: nil)
        self.title = .VPN.Settings.LocationTitle
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
}
