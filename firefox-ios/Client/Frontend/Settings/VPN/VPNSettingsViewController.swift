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
    private let localeProvider: LocaleProvider
    private lazy var hostingController = UIHostingController(rootView: makeRootView())

    init(
        windowUUID: WindowUUID,
        prefs: Prefs,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) {
        self.windowUUID = windowUUID
        self.prefs = prefs
        self.themeManager = themeManager
        self.localeProvider = localeProvider
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

    private func locationsTapped() {
        let controller = VPNLocationsViewController(
            windowUUID: windowUUID,
            selectedRegionCode: selectedRegionCode,
            themeManager: themeManager,
            localeProvider: localeProvider,
            onLocationSelected: { [weak self] regionCode in
                self?.locationSelected(regionCode)
            }
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    private var selectedRegionCode: String {
        prefs.stringForKey(PrefsKeys.VPNSettings.selectedRegionCode) ?? VPNServerManager.recommendedCountryCode
    }

    private func locationSelected(_ regionCode: String) {
        prefs.setString(regionCode, forKey: PrefsKeys.VPNSettings.selectedRegionCode)
        hostingController.rootView = makeRootView()
    }

    private func makeRootView() -> VPNSettingsViewContainer {
        let locationName: String = selectedRegionCode == VPNServerManager.recommendedCountryCode
            ? .VPN.Settings.LocationRecommended
            : localeProvider.localizedRegionName(for: selectedRegionCode)
        return VPNSettingsViewContainer(
            windowUUID: windowUUID,
            themeManager: themeManager,
            isVPNEnabled: prefs.boolForKey(PrefsKeys.VPNSettings.isEnabled) ?? false,
            locationName: locationName,
            onLocationsTapped: { [weak self] in
                self?.locationsTapped()
            },
            onVPNToggled: { [prefs = self.prefs] isEnabled in
                prefs.setBool(isEnabled, forKey: PrefsKeys.VPNSettings.isEnabled)
            },
            onLearnMoreTapped: { [weak self] in
                self?.learnMoreTapped()
            }
        )
    }
}
