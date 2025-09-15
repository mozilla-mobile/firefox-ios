// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class ResetTermsOfServiceAcceptancePage: HiddenSetting, FeatureFlaggable {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    // Only show this debug setting when Terms Of Service feature is enabled
    override var hidden: Bool {
        return !featureFlags.isFeatureEnabled(.tosFeature, checking: .buildAndUser)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        let tosAccepted = settings.profile?.prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1
        let status = tosAccepted ? "accepted" : "not accepted"

        return NSAttributedString(string: "Reset onboarding ToS accept (\(status))",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let prefs = settings.profile?.prefs else { return }

        // Reset onboarding Terms of Service preferences
        // This allows testing the Terms of Use bottom sheet after onboarding acceptance
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAccepted)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedVersion)
        prefs.removeObjectForKey(PrefsKeys.TermsOfServiceAcceptedDate)

        settingsDelegate?.askedToReload()
    }
}
