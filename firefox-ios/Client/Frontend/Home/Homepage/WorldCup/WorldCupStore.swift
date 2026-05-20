// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Common

/// Public surface for the World Cup feature's preferences and feature flags.
protocol WorldCupStoreProtocol {
    /// Whether the feature is enabled via Nimbus.
    var isFeatureEnabled: Bool { get }

    /// Whether the feature flag is enabled and the preference for the homepage section is enabled
    var isFeatureEnabledAndSectionEnabled: Bool { get }

    /// The country id (ISO code) the user has selected, if any.
    var selectedTeam: String? { get }

    /// Returns true when we are within the milestone 2 window — i.e. the
    /// milestone 2 enable date has been reached.
    var isMilestone2: Bool { get }

    /// Saves the world cup section selection in the preference
    func setIsHomepageSectionEnabled(_ isEnabled: Bool)

    /// Persists the user's selected team.
    func setSelectedTeam(countryId: String?)
}

/// A Store for all the preferences and feature flags related to the WorldCup feature.
struct WorldCupStore: WorldCupStoreProtocol, FeatureFlaggable {
    private var iso8601Formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }

    let profile: Profile
    let nimbusFeature: FeatureHolder<WorldCupWidgetFeature>
    let dateProvider: DateProvider

    init(
        profile: Profile = AppContainer.shared.resolve(),
        nimbusFeature: FeatureHolder<WorldCupWidgetFeature> = FxNimbus.shared.features.worldCupWidgetFeature,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.profile = profile
        self.nimbusFeature = nimbusFeature
        self.dateProvider = dateProvider
    }

    var isFeatureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.worldCupWidget)
    }

    var isFeatureEnabledAndSectionEnabled: Bool {
        return isFeatureEnabled && isHomepageSectionEnabled
    }

    private var isHomepageSectionEnabled: Bool {
        return profile.prefs.boolForKey(PrefsKeys.HomepageSettings.WorldCupSection) ?? true
    }

    var selectedTeam: String? {
        return profile.prefs.stringForKey(PrefsKeys.Homepage.WorldCupSelectedCountry)
    }

    var isMilestone2: Bool {
        return true
        guard let enableDate = milestone2EnableDate else { return false }
        return dateProvider.now() >= enableDate
    }

    private var milestone2EnableDate: Date? {
        let dateString = nimbusFeature.value().milestone2EnableDate
        return iso8601Formatter.date(from: dateString)
    }

    func setIsHomepageSectionEnabled(_ isEnabled: Bool) {
        profile.prefs.setBool(isEnabled, forKey: PrefsKeys.HomepageSettings.WorldCupSection)
    }

    func setSelectedTeam(countryId: String?) {
        profile.prefs.setObject(countryId, forKey: PrefsKeys.Homepage.WorldCupSelectedCountry)
    }
}
