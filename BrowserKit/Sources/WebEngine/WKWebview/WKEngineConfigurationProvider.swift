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
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true

        return DefaultEngineConfiguration(webViewConfiguration: configuration)
    }
}
