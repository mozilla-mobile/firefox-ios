// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

public struct WKWebviewParameters {
    /// A boolean value customizable with a user preference indicating whether JavaScript can
    /// open windows without user interaction.
    var blockPopups: Bool

    /// A boolean value indicating if we have a persitent webview data store.
    var isPrivate: Bool

    /// The type of pull refresh that is going to be instantiated and displayed by the webview.
    var pullRefreshType: EnginePullRefreshViewType

    public init(blockPopups: Bool,
                isPrivate: Bool,
                pullRefreshType: EnginePullRefreshViewType = UIRefreshControl.self) {
        self.blockPopups = blockPopups
        self.isPrivate = isPrivate
        self.pullRefreshType = pullRefreshType
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
        if #available(iOS 15.4, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }
        if parameters.isPrivate {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        } else {
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }

        configuration.setURLSchemeHandler(WKInternalSchemeHandler(),
                                          forURLScheme: WKInternalSchemeHandler.scheme)
        return DefaultEngineConfiguration(pullRefreshType: parameters.pullRefreshType,
                                          webViewConfiguration: configuration)
    }
}
