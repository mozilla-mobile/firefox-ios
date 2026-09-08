// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Supplies the countries backing the VPN location picker. `VPNServerlist` is the production
/// implementation; the seam keeps `VPNSettingsModel` testable without a Remote Settings service.
///
/// Deliberately not `@MainActor`: reading the collection hits Remote Settings storage, so the
/// call needs to hop off the main actor rather than merely being `async` on it.
protocol VPNLocationProviding: Sendable {
    func listCountries() async -> [VPNServerlist.Country]
}

extension VPNServerlist: VPNLocationProviding {}

/// Backs both the built-in VPN settings screen and the location picker pushed from it. A single
/// instance is shared between the two so a pick on the second screen updates the first.
@MainActor
final class VPNSettingsModel: ObservableObject {
    struct Location: Identifiable, Equatable {
        let code: String
        let name: String

        var id: String { code }
    }

    /// Country codes in the serverlist are ISO 3166 alpha-2, so the display name comes from
    /// `Locale` — that keeps it localized, unlike the (English) name on the record itself.
    static func displayName(for code: String, fallback: String? = nil) -> String {
        guard code != VPNServerlist.recommendedCountryCode else {
            return .Settings.VPN.LocationSection.RecommendedTitle
        }
        return Locale.current.localizedString(forRegionCode: code) ?? fallback ?? code
    }

    let windowUUID: WindowUUID

    @Published private(set) var isVPNOn: Bool
    @Published private(set) var locations: [Location] = []
    @Published private(set) var selectedLocationCode: String

    let description: String = {
        String(format: .Settings.VPN.Description, AppName.shortName.rawValue)
    }()

    let recommendedDescription: String = {
        String(format: .Settings.VPN.LocationSection.RecommendedDescription, AppName.shortName.rawValue)
    }()

    var isRecommendedSelected: Bool {
        return selectedLocationCode == VPNServerlist.recommendedCountryCode
    }

    /// Derived from the persisted code alone, so the settings screen never has to load the
    /// country list just to label its location row.
    var selectedLocationName: String {
        return Self.displayName(for: selectedLocationCode)
    }

    private let prefs: Prefs
    private let locationProvider: VPNLocationProviding?
    private let injectedVPNManager: VPNManaging?
    private let userPreferences: UserFeaturePreferring
    private let settingsTelemetry: SettingsTelemetry
    private let logger: Logger
    private var hasLoadedLocations = false

    /// The `VPNManager` is only registered on iOS 17, where `ProxyConfiguration` is available.
    private var vpnManager: VPNManaging? {
        if let injectedVPNManager { return injectedVPNManager }
        guard #available(iOS 17.0, *) else { return nil }
        return AppContainer.shared.resolve()
    }

    init(
        prefs: Prefs,
        windowUUID: WindowUUID,
        locationProvider: VPNLocationProviding?,
        vpnManager: VPNManaging? = nil,
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        settingsTelemetry: SettingsTelemetry = SettingsTelemetry(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.locationProvider = locationProvider
        self.injectedVPNManager = vpnManager
        self.userPreferences = userPreferences
        self.settingsTelemetry = settingsTelemetry
        self.logger = logger

        isVPNOn = userPreferences.getPreferenceFor(.vpnFeature)
        selectedLocationCode = prefs.stringForKey(PrefsKeys.Settings.vpnLocation)
            ?? VPNServerlist.recommendedCountryCode
    }

    /// Fetched once per model, off the main actor, and only by the location picker — the
    /// settings screen labels its row from the persisted code instead. An empty result clears
    /// the flag so a failed fetch is retried the next time the picker is opened.
    ///
    /// The "Recommended" entry is surfaced as its own pinned row, so it is dropped from the
    /// country list here rather than in the view.
    func loadLocations() async {
        guard !hasLoadedLocations, let locationProvider else { return }
        hasLoadedLocations = true

        let countries = await locationProvider.listCountries()
        hasLoadedLocations = !countries.isEmpty
        locations = countries
            .filter { $0.code != VPNServerlist.recommendedCountryCode }
            .map { Location(code: $0.code, name: Self.displayName(for: $0.code, fallback: $0.name)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Flips the toggle optimistically, then republishes whatever state the `VPNManager` settled
    /// on so a failed start reverts the row.
    func toggleVPN(to newValue: Bool) async {
        guard isVPNOn != newValue else {
            logger.log("Not toggling the VPN, toggle value is unchanged", level: .warning, category: .settings)
            return
        }

        guard let vpnManager else {
            logger.log("Toggled the VPN setting but no VPNManager is registered", level: .warning, category: .settings)
            return
        }

        isVPNOn = newValue
        if newValue {
            await vpnManager.start()
        } else {
            await vpnManager.stop()
        }
        isVPNOn = userPreferences.getPreferenceFor(.vpnFeature)

        settingsTelemetry.changedSetting(
            PrefsKeys.Settings.vpnFeature,
            to: String(isVPNOn),
            from: String(!isVPNOn)
        )
    }

    /// TODO: FXIOS-16373 Only persists the pick for now — the `VPNManager` still connects to its
    /// hardcoded server and does not read this preference.
    func selectLocation(code: String) {
        guard selectedLocationCode != code else { return }

        let previousCode = selectedLocationCode
        selectedLocationCode = code
        prefs.setString(code, forKey: PrefsKeys.Settings.vpnLocation)

        settingsTelemetry.changedSetting(
            PrefsKeys.Settings.vpnLocation,
            to: code,
            from: previousCode
        )
    }
}
