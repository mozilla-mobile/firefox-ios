// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

public struct WKWebviewParameters {
    /// A boolean value customizable with a user preference indicating whether JavaScript can open windows without user interaction.
    var blockPopups: Bool

    /// A boolean value indicating if we have a persitent webview data store.
    var isPrivate: Bool

    public init(blockPopups: Bool, isPrivate: Bool) {
        self.blockPopups = blockPopups
        self.isPrivate = isPrivate
    }
}

/// Provider to get a configured `WKEngineConfiguration`
protocol WKEngineConfigurationProvider {
    func createConfiguration() -> WKEngineConfiguration
}

struct DefaultWKEngineConfigurationProvider: WKEngineConfigurationProvider {
    private let parameters: WKWebviewParameters

    init(parameters: WKWebviewParameters) {
        self.parameters = parameters
    }

    func createConfiguration() -> WKEngineConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !parameters.blockPopups
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true
        if parameters.isPrivate {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        } else {
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }

        configuration.setURLSchemeHandler(WKInternalSchemeHandler(),
                                          forURLScheme: WKInternalSchemeHandler.scheme)
        return DefaultEngineConfiguration(webViewConfiguration: configuration)
    }
}
