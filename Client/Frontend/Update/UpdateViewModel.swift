/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

protocol InformationContainerModel {
    var enabledCards: [IntroViewModel.InformationCards] { get }
}

extension InformationContainerModel {
    func getNextIndex(currentIndex: Int, goForward: Bool) -> Int? {
        if goForward && currentIndex + 1 < enabledCards.count {
            return currentIndex + 1
        }

        if !goForward && currentIndex > 0 {
            return currentIndex - 1
        }

        return nil
    }
}

class UpdateViewModel: InformationContainerModel {

    var startBrowsing: (() -> Void)?
    let profile: Profile
    static let prefsKey: String = PrefsKeys.KeyLastVersionNumber

    // The list below is for the version(s) we would like to show the coversheet for.
    let supportedAppVersion = ["22.0, 104.0"]

    var enabledCards: [IntroViewModel.InformationCards] {
        if hasSyncAccount {
            return [.welcome]
        }

        return [.welcome, .signSync]
    }

    var isCleanInstall: Bool {
        return profile.prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first == nil
    }

    var hasSyncAccount: Bool {
        return profile.hasSyncableAccount()
    }

    init(profile: Profile) {
        self.profile = profile
    }

    func getCardViewModel(index: Int) -> OnboardingCardProtocol? {
        let currentCard = enabledCards[index]

        switch currentCard {
        case .welcome:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: ImageIdentifiers.onboardingWelcome),
                                           title: .CardTitleWelcome,
                                           description: .Onboarding.IntroDescriptionPart2,
                                           primaryAction: .Onboarding.IntroAction,
                                           secondaryAction: nil,
                                           a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case .signSync:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: ImageIdentifiers.onboardingSync),
                                           title: .Onboarding.SyncTitle,
                                           description: .Onboarding.SyncDescription,
                                           primaryAction: .Onboarding.SyncAction,
                                           secondaryAction: .WhatsNew.RecentButtonTitle,
                                           a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard)
        default:
            return nil
        }
    }

    func shouldShowUpdateSheet(appVersion: String = AppInfo.appVersion) -> Bool {
        // Only shown if is not clean install and is a supported version
        guard !isCleanInstall, !supportedAppVersion.contains(appVersion) else {
            saveAppVersion(for: appVersion)
            return false
        }

        // we check if there is a version number already saved
        guard let savedVersion =  profile.prefs.stringForKey(UpdateViewModel.prefsKey) else {
            // Save version and show page
            saveAppVersion(for: appVersion)
            return true
        }

        // Version number saved in user prefs is not the same as current version
        if savedVersion != appVersion {
            saveAppVersion(for: appVersion)
        }

        return savedVersion != appVersion
    }

    private func saveAppVersion(for appVersion: String) {
        profile.prefs.setString(appVersion, forKey: UpdateViewModel.prefsKey)
    }
}
