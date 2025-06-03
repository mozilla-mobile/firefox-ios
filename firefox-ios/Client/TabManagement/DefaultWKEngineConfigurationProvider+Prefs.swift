// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine
import Shared

extension DefaultWKEngineConfigurationProvider {
    @MainActor
    func configuration(from prefs: Prefs, isPrivate: Bool) -> WKEngineConfiguration {
        let blockPopups = prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true
        let autoPlay = AutoplayAccessors.getMediaTypesRequiringUserActionForPlayback(prefs)
        let parameters = WKWebViewParameters(
            blockPopups: blockPopups,
            isPrivate: isPrivate,
            autoPlay: autoPlay,
            schemeHandler: WKInternalSchemeHandler()
        )
        return createConfiguration(parameters: parameters)
    }
}
