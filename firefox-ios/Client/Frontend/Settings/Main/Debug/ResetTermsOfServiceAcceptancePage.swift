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
        // Check TermsOfUseAccepted (migrated from TermsOfServiceAccepted)
        let touAccepted = settings.profile?.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        let status = touAccepted ? "accepted" : "not accepted"

        return NSAttributedString(string: "Reset ToU accept (\(status))",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard let prefs = settings.profile?.prefs else { return }

        // Reset Terms of Use preferences
        // This allows testing the Terms of Use bottom sheet after acceptance
        prefs.removeObjectForKey(PrefsKeys.TermsOfUseAccepted)
        prefs.removeObjectForKey(PrefsKeys.TermsOfUseAcceptedVersion)
        prefs.removeObjectForKey(PrefsKeys.TermsOfUseAcceptedDate)

        settingsDelegate?.askedToReload()
    }
}
