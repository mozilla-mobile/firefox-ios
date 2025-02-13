// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// Provider to get a configured `WKEngineConfiguration`
protocol WKEngineConfigurationProvider {
    func createConfiguration() -> WKEngineConfiguration
}

struct DefaultWKEngineConfigurationProvider: WKEngineConfigurationProvider {
    func createConfiguration() -> WKEngineConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        // TODO: FXIOS-11324 Configure KeyBlockPopups
//        let blockPopups = prefs?.boolForKey(PrefsKeys.KeyBlockPopups) ?? true
//        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !blockPopups
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true
        // TODO: FXIOS-11324 Configure isPrivate
//        if isPrivate {
//            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
//        } else {
//            configuration.websiteDataStore = WKWebsiteDataStore.default()
//        }

        configuration.setURLSchemeHandler(WKInternalSchemeHandler(),
                                          forURLScheme: WKInternalSchemeHandler.scheme)
        return DefaultEngineConfiguration(webViewConfiguration: configuration)
    }
}
