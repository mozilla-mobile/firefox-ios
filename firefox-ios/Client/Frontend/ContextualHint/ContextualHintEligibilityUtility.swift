// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Public interface for contextual hint consumers
protocol ContextualHintEligibilityUtilityProtocol {
    func canPresent(_ hint: ContextualHintType) -> Bool
}

struct ContextualHintEligibilityUtility: ContextualHintEligibilityUtilityProtocol,
                                         ContextualHintPrefsKeysProvider,
                                         SearchBarLocationProvider {
    var profile: Profile
    var device: UIDeviceInterface
    // For contextual hints shown in Homepage that can overlap with keyboard being raised by user interaction
    private var overlayState: OverlayStateProtocol?
    var isCFRToolbarFeatureEnabled: Bool

    init(with profile: Profile,
         overlayState: OverlayStateProtocol?,
         device: UIDeviceInterface = UIDevice.current,
         isCFRToolbarFeatureEnabled: Bool = false) {
        self.profile = profile
        self.overlayState = overlayState
        self.device = device
        self.isCFRToolbarFeatureEnabled = isCFRToolbarFeatureEnabled
    }

    /// Determine if this hint is eligible to present, outside of Nimbus flag settings.
    func canPresent(_ hintType: ContextualHintType) -> Bool {
        guard !isInOverlayMode else { return false }

        var hintTypeShouldBePresented = false

        switch hintType {
        case .dataClearance:
            hintTypeShouldBePresented = true
        case .jumpBackIn:
            hintTypeShouldBePresented = canJumpBackInBePresented
        case .jumpBackInSyncedTab:
            hintTypeShouldBePresented = canPresentJumpBackInSyncedTab
        case .toolbarLocation:
            hintTypeShouldBePresented = isSearchBarLocationFeatureEnabled
        case .menuRedesign:
            hintTypeShouldBePresented = true
        case .inactiveTabs:
            hintTypeShouldBePresented = true
        case .shoppingExperience:
            return canPresentShoppingCFR
        case .navigation:
            hintTypeShouldBePresented = true
        }

        return hintTypeShouldBePresented //&& !hasAlreadyBeenPresented(hintType) // -> enable it
    }

    // MARK: - Private helpers

    private var isInOverlayMode: Bool {
        guard overlayState != nil else { return false }

        return overlayState?.inOverlayMode ?? false
    }

    /// If device is iPhone we present JumpBackIn and SyncTab CFRs only after Toolbar CFR has been
    /// presented if the feature is enabled. If the Toolbar CFR flag is disabled or the device
    /// is iPad (toolbar CFR is not presented on iPad) we bypass it
    private var shouldCheckToolbarHasShown: Bool {
        guard device.userInterfaceIdiom != .pad,
              isCFRToolbarFeatureEnabled else { return true }

        return profile.prefs.boolForKey(CFRPrefsKeys.toolbarOnboardingKey.rawValue) ?? false
    }

    /// Determine if the CFR for Jump Back In is presentable.
    ///
    /// It's presentable on these conditions:
    /// - the Toolbar CFR has already been presented or the CFR toolbar flag is disabled
    /// - the JumpBackInSyncedTab CFR has NOT been presented already
    /// - the JumpBackIn CFR has NOT been presented yet
    private var canJumpBackInBePresented: Bool {
        guard shouldCheckToolbarHasShown,
              !hasHintBeenConfigured(.jumpBackInSyncedTab),
              !hasAlreadyBeenPresented(.jumpBackInSyncedTab)
        else { return false }

        return true
    }

    /// Determine if the CFR for SyncedTab in JumpBackIn is presentable.
    ///
    /// The context hint is presentable when certain conditions are met:
    /// - A synced tab appears in Jump Back In
    /// - The Toolbar CFR has already been presented or the CFR toolbar flag is disabled
    /// - This CFR hasn't already been presented
    /// - The Home Tab Banner isn't being displayed (not specified by Product,
    ///   but the CFR might show when the anchor point isn't on screen)
    private var canPresentJumpBackInSyncedTab: Bool {
        return shouldCheckToolbarHasShown
    }

    /// Determine if the Shopping CFRs should present.
    /// There are 2 types of CFRs.
    ///
    /// - Shopping CFR-1: The user has not opted in for the Shopping Experience.
    /// - Shopping CFR-2: The user has opted in for the Shopping Experience.
    private var canPresentShoppingCFR: Bool {
        guard !hasAlreadyBeenPresented(.shoppingExperience) else {
            // Retrieve the counter for shopping onboarding CFRs
            let shoppingOnboardingKey = PrefsKeys.ContextualHints.shoppingOnboardingCFRsCounterKey.rawValue
            let cfrCounter = profile.prefs.intForKey(shoppingOnboardingKey) ?? 1
            // Check if the user has opted in for Shopping Experience
            let hasOptedIn = profile.prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
            // Retrieve the last timestamp for Fakespot CFRs
            let lastTimestamp = profile.prefs.timestampForKey(PrefsKeys.FakespotLastCFRTimestamp)
            // Check if 12 hours have passed since the last timestamp
            let hasTimePassed = lastTimestamp != nil ? Date.hasTimePassedBy(
                hours: 12,
                lastTimestamp: lastTimestamp!
            ) : false

            if cfrCounter <= 2, !hasOptedIn, hasTimePassed {
                // - Display CFR-1
                profile.prefs.setInt(
                    cfrCounter + 1,
                    forKey: PrefsKeys.ContextualHints.shoppingOnboardingCFRsCounterKey.rawValue
                )
                profile.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.FakespotLastCFRTimestamp)
                return true
            } else if cfrCounter < 4, hasOptedIn, hasTimePassed {
                // - Display CFR-2
                profile.prefs.setInt(4, forKey: PrefsKeys.ContextualHints.shoppingOnboardingCFRsCounterKey.rawValue)
                return true
            }
            return false
        }
        // - Display CFR-1
        profile.prefs.setInt(1, forKey: PrefsKeys.ContextualHints.shoppingOnboardingCFRsCounterKey.rawValue)
        profile.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.FakespotLastCFRTimestamp)
        return true
    }

    private func hasAlreadyBeenPresented(_ hintType: ContextualHintType) -> Bool {
        guard let contextualHintData = profile.prefs.boolForKey(prefsKey(for: hintType)) else { return false }

        return contextualHintData
    }

    /// In cases where hints need to be made aware of each other, this will inform of configured ones.
    ///
    /// Hints are configured when the anchor point is visible on screen. Sometimes, multiple hints can become
    /// configured and be eligible to present together. One hint can affect whether or not another should be
    /// presented, but currently hints are unaware of each other.
    ///
    /// With this method, if `hintA` needs to be aware of `hintB`, `hintA` can query for whether `hintB`
    /// has been configured. Then, `hintA` can react accordingly.
    ///
    /// This is a workaround for hints becoming aware of each other until we have a proper CFR system in place.
    private func hasHintBeenConfigured(_ hintType: ContextualHintType) -> Bool {
        var hintConfigured = false

        switch hintType {
        case .jumpBackIn:
            guard let jumpBackInConfigured = profile.prefs.boolForKey(
                CFRPrefsKeys.jumpBackInConfiguredKey.rawValue
            ) else { return false }

            hintConfigured = jumpBackInConfigured
        case .jumpBackInSyncedTab:
            guard let syncedTabConfigured = profile.prefs.boolForKey(
                CFRPrefsKeys.jumpBackInSyncedTabConfiguredKey.rawValue
            ) else { return false }

            hintConfigured = syncedTabConfigured
        default: break
        }

        return hintConfigured
    }
}
