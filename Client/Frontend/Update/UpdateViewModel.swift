/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class UpdateViewModel: OnboardingViewModelProtocol, FeatureFlaggable {

    let profile: Profile
    static let prefsKey: String = PrefsKeys.KeyLastVersionNumber

    var shouldShowSingleCard: Bool {
        return enabledCards.count == 1
    }

    var enabledCards: [IntroViewModel.InformationCards] {
        if profile.hasSyncableAccount() {
            return [.updateWelcome]
        }

        return [.updateWelcome, .updateSignSync]
    }

    // If the feature is enabled and is not clean install
    var shouldShowFeature: Bool {
        return featureFlags.isFeatureEnabled(.upgradeOnboarding, checking: .buildOnly) && profile.prefs.stringForKey(LatestAppVersionProfileKey) != nil
    }

    init(profile: Profile) {
        self.profile = profile
    }

    func shouldShowUpdateSheet(force: Bool = false,
                               appVersion: String = AppInfo.appVersion) -> Bool {
        guard !force else { return true }

        guard shouldShowFeature else {
            saveAppVersion(for: appVersion)
            return false
        }

        // we check if there is a version number already saved
        guard let savedVersion = profile.prefs.stringForKey(UpdateViewModel.prefsKey) else {
            saveAppVersion(for: appVersion)
            return true
        }

        // Version number saved in user prefs is not the same as current version
        if savedVersion != appVersion {
            saveAppVersion(for: appVersion)
            return true
        }

        return false
    }

    func positionForCard(cardType: IntroViewModel.InformationCards) -> Int? {
        return enabledCards.firstIndex(of: cardType)
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: enabledCards[index].telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }

    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingModelProtocol? {
        switch cardType {
        case .updateWelcome:
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcome),
                                       title: .Upgrade.WelcomeTitle,
                                       description: .Upgrade.WelcomeDescription,
                                       primaryAction: .Upgrade.WelcomeAction,
                                       secondaryAction: nil,
                                       a11yIdRoot: AccessibilityIdentifiers.Upgrade.welcomeCard)
        case .updateSignSync:
            return OnboardingInfoModel(image: nil,
                                       title: .Upgrade.SyncSignTitle,
                                       description: .Upgrade.SyncSignDescription,
                                       primaryAction: .Upgrade.SyncAction,
                                       secondaryAction: .Onboarding.LaterAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Upgrade.signSyncCard)
        case .welcome, .wallpapers, .signSync:
            // Cases not supported by the upgrade screen
            return nil
        }
    }

    private func saveAppVersion(for appVersion: String) {
        profile.prefs.setString(appVersion, forKey: UpdateViewModel.prefsKey)
    }
}
