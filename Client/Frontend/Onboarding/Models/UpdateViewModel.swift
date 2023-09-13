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
        telemetryUtility: OnboardingTelemetryProtocol
    ) {
        self.profile = profile
        self.telemetryUtility = telemetryUtility
        self.cardModels = model.cards
        self.isDismissable = model.isDismissable
        self.availableCards = []
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
        profile.hasSyncAccount { result in
            self.hasSyncableAccount = result
            ensureMainThread {
                completion()
            }
        }
    }

    func hasSyncableAccount() async -> Bool {
        return await withCheckedContinuation { continuation in
            profile.hasSyncAccount { hasSync in
                self.hasSyncableAccount = hasSync
                continuation.resume(returning: hasSync)
            }
        }
    }

    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate) {
        availableCards.removeAll()
        for cardModel in cardModels {
            // If it's a sync sign in card and we're already signed in, don't add
            // the card to the available cards.
            if (cardModel.buttons.primary.action == .syncSignIn || cardModel.buttons.secondary?.action == .syncSignIn)
                && hasSyncableAccount ?? false {
                break
            }

            availableCards.append(OnboardingCardViewController(
                viewModel: cardModel,
                delegate: delegate))
        }
    }

    private func saveAppVersion(for appVersion: String) {
        profile.prefs.setString(appVersion, forKey: PrefsKeys.AppVersion.Latest)
    }
}
