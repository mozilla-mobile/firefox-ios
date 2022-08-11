/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class UpdateViewModel: InformationContainerModel {

    let profile: Profile
    static let prefsKey: String = PrefsKeys.KeyLastVersionNumber

    // The list below is for the version(s) we would like to show the coversheet for.
    let supportedAppVersion = ["22.0", "104.0"]

    var hasSingleCard: Bool {
        return enabledCards.count == 1
    }
    var enabledCards: [IntroViewModel.InformationCards] {
        if hasSyncAccount {
            return [.updateWelcome]
        }

        return [.updateWelcome, .updateSignSync]
    }

    var isCleanInstall: Bool {
        return profile.prefs.stringForKey(LatestAppVersionProfileKey)?
            .components(separatedBy: ".").first == nil
    }

    var hasSyncAccount: Bool {
        return profile.hasSyncableAccount()
    }

    init(profile: Profile) {
        self.profile = profile
    }

    func shouldShowUpdateSheet(appVersion: String = AppInfo.appVersion) -> Bool {
        // Only shown if is not clean install and is a supported version
        guard !isCleanInstall, supportedAppVersion.contains(appVersion) else {
            saveAppVersion(for: appVersion)
            return false
        }

        // we check if there is a version number already saved
        guard let savedVersion =  profile.prefs.stringForKey(UpdateViewModel.prefsKey) else {
            saveAppVersion(for: appVersion)
            return true
        }

        // Version number saved in user prefs is not the same as current version
        if savedVersion != appVersion {
            saveAppVersion(for: appVersion)
        }

        return savedVersion != appVersion
    }

    func getInfoModel(currentCard: IntroViewModel.InformationCards) -> InfoModelProtocol? {
        switch currentCard {
        case .updateWelcome:
            return CoverSheetInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcome),
                                       title: .Upgrade.WelcomeTitle,
                                       description: .Upgrade.WelcomeDescription,
                                       primaryAction: .Upgrade.WelcomeAction,
                                       secondaryAction: nil,
                                       a11yIdRoot: AccessibilityIdentifiers.Upgrade.welcomeCard)
        case .updateSignSync:
            return CoverSheetInfoModel(image: UIImage(named: ImageIdentifiers.onboardingSync),
                                       title: .Upgrade.SyncSignTitle,
                                       description: .Upgrade.SyncSignDescription,
                                       primaryAction: .Upgrade.SyncAction,
                                       secondaryAction: .Onboarding.LaterAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Upgrade.signSyncCard)
        default:
            return nil
        }
    }

    func getCardViewModel(index: Int) -> OnboardingCardProtocol? {
        let currentCard = enabledCards[index]
        guard let infoModel = getInfoModel(currentCard: currentCard) else { return nil }

        return OnboardingCardViewModel(cardType: currentCard,
                                       infoModel: infoModel)
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

    private func saveAppVersion(for appVersion: String) {
        profile.prefs.setString(appVersion, forKey: UpdateViewModel.prefsKey)
    }
}
