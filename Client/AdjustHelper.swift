// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Adjust
import Shared

private let log = Logger.browserLogger

final class AdjustHelper {

    private static let adjustAppTokenKey = "AdjustAppToken"
    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    func setupAdjust() {
        guard let config = getConfig() else { return }

        // Always initialize Adjust if we have a config - otherwise we cannot enable/disable it later. Their SDK must be
        // initialized through appDidFinishLaunching otherwise it will be in a bad state.
        Adjust.appDidLaunch(config)
        AdjustHelper.setEnabled(shouldEnable())
    }

    /// This is called from the Settings screen. The setting SendAnonymousUsageData screen will remember the choice in the
    /// profile and then use this method to disable or enable Adjust.
    static func setEnabled(_ enabled: Bool) {
        Adjust.setEnabled(enabled)

        if !enabled {
            Adjust.gdprForgetMe()
        }
    }

    private func getConfig() -> ADJConfig? {
        let bundle = AppInfo.applicationBundle
        guard let appToken = bundle.object(forInfoDictionaryKey: AdjustHelper.adjustAppTokenKey) as? String, !appToken.isEmpty else {
            log.debug("Adjust - Not enabling Adjust; Not configured in Info.plist")
            return nil
        }

        let isProd = FeatureFlagsManager.shared.isFeatureActiveForBuild(.adjustEnvironmentProd)
        let environment = isProd ? ADJEnvironmentProduction : ADJEnvironmentSandbox
        let config = ADJConfig(appToken: appToken, environment: environment)
        config?.logLevel = isProd ? ADJLogLevelSuppress : ADJLogLevelDebug
        return config
    }

    /// Return true if Adjust should be enabled. If the user has disabled the Send Anonymous Usage Data then we immediately return false.
    private func shouldEnable() -> Bool {
        return profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? false
    }
}
