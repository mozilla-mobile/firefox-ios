// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class SwitchFakespotProduction: HiddenSetting, FeatureFlaggable {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        let toNewStatus = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI) ? "prod" : "staging"
        return NSAttributedString(string: "Switch FakespotEndpoint to \(toNewStatus)",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let useStagingAPI = featureFlags.isCoreFeatureEnabled(.useStagingFakespotAPI)
        let channels = useStagingAPI ? [AppBuildChannel.release] : [.developer, .beta]
        featureFlags.set(feature: .useStagingFakespotAPI, toChannels: channels)

        settingsDelegate?.askedToReload()
    }
}
