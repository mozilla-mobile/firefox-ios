// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class UpdateViewModel: OnboardingViewModelProtocol,
                       FeatureFlaggable,
                       AppVersionUpdateCheckerProtocol {
    // MARK: - Properties
    var profile: Profile
    var hasSyncableAccount: Bool?
    var availableCards: [OnboardingCardViewController]
    var isDismissable: Bool
    var telemetryUtility: OnboardingTelemetryProtocol
    let windowUUID: WindowUUID
    private var cardModels: [OnboardingCardInfoModelProtocol]

    var shouldShowSingleCard: Bool {
        return availableCards.count == 1
    }

    // If the feature has cards available and is not clean install
    var shouldShowFeature: Bool {
        return !cardModels.isEmpty && !isFreshInstall
    }

    var isFreshInstall: Bool {
        return profile.prefs.stringForKey(PrefsKeys.AppVersion.Latest) == nil
    }

    // MARK: - Initializer
    init(
        profile: Profile,
        model: OnboardingViewModel,
        telemetryUtility: OnboardingTelemetryProtocol,
        windowUUID: WindowUUID
    ) {
        self.profile = profile
        self.telemetryUtility = telemetryUtility
        self.cardModels = model.cards
        self.isDismissable = model.isDismissable
        self.availableCards = []
        self.windowUUID = windowUUID
    }

    // MARK: - Methods
    func shouldShowUpdateSheet(force: Bool = false,
                               appVersion: String = AppInfo.appVersion) -> Bool {
        guard !force else { return true }

        guard shouldShowFeature else {
            saveAppVersion(for: appVersion)
            return false
        }

        // If it's fresh install, we don't show the update onboarding
        guard !isFreshInstall else {
            saveAppVersion(for: appVersion)
            return false
        }

        // Version number saved in user prefs is not the same as current version
        guard !isMajorVersionUpdate(using: profile, and: appVersion) else {
            saveAppVersion(for: appVersion)
            return true
        }

        return false
    }

    // Function added to wait for AccountManager initialization to get
    // if the user is Sign in with Sync Account to decide which cards to show
    func hasSyncableAccount(completion: @escaping () -> Void) {
        hasSyncableAccount = profile.hasAccount()
        ensureMainThread {
            completion()
        }
    }

    func hasSyncableAccount() async -> Bool {
        let hasSync = profile.hasAccount()
        hasSyncableAccount = hasSync
        return hasSync
    }

    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate, for window: WindowUUID) {
        availableCards.removeAll()
        for cardModel in cardModels {
            // If it's a sync sign in card and we're already signed in, don't add
            // the card to the available cards.
            if (cardModel.buttons.primary.action == .syncSignIn || cardModel.buttons.secondary?.action == .syncSignIn)
                && hasSyncableAccount ?? false {
                break
            }

            if cardModel.cardType == .multipleChoice {
            availableCards.append(OnboardingMultipleChoiceCardViewController(
                viewModel: cardModel,
                delegate: delegate,
                windowUUID: window))
            } else {
                availableCards.append(OnboardingBasicCardViewController(
                    viewModel: cardModel,
                    delegate: delegate,
                    windowUUID: window))
            }
        }
    }

    private func saveAppVersion(for appVersion: String) {
        profile.prefs.setString(appVersion, forKey: PrefsKeys.AppVersion.Latest)
    }
}
