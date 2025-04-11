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

    /// A value indicating the user preference for audio visual media types
    var autoPlay: WKAudiovisualMediaTypes

    /// FXIOS-TODO - Allow Client to pass down it's own scheme handler for now, this will be internal later on
    var schemeHandler: SchemeHandler

    public init(blockPopups: Bool,
                isPrivate: Bool,
                autoPlay: WKAudiovisualMediaTypes,
                schemeHandler: SchemeHandler) {
        self.blockPopups = blockPopups
        self.isPrivate = isPrivate
        self.autoPlay = autoPlay
        self.schemeHandler = schemeHandler
    }
}

/// Provider to get a configured `WKEngineConfiguration`
/// Only one configuration provider per window should exists in the application.
public protocol WKEngineConfigurationProvider {
    func createConfiguration(parameters: WKWebviewParameters) -> WKEngineConfiguration
}

/// FXIOS-TODO - This will be internal when the WebEngine is fully integrated in Firefox iOS
public struct DefaultWKEngineConfigurationProvider: WKEngineConfigurationProvider {
    private static let normalSessionsProcessPool = WKProcessPool()
    private static let privateSessionsProcessPool = WKProcessPool()

    public func createConfiguration(parameters: WKWebviewParameters) -> WKEngineConfiguration {
        let configuration = WKWebViewConfiguration()

        // Since our app creates multiple web views, we assign the same WKProcessPool object to web views that
        // may safely share a process space
        configuration.processPool = parameters.isPrivate
        ? DefaultWKEngineConfigurationProvider.privateSessionsProcessPool
        : DefaultWKEngineConfigurationProvider.normalSessionsProcessPool

        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !parameters.blockPopups
        configuration.mediaTypesRequiringUserActionForPlayback = parameters.autoPlay
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true

        // TODO: FXIOS-8086 - Evaluate if ignoresViewportScaleLimits is still needed
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        if #available(iOS 15.4, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }
        configuration.websiteDataStore = parameters.isPrivate
        ? WKWebsiteDataStore.nonPersistent()
        : WKWebsiteDataStore.default()

        configuration.setURLSchemeHandler(parameters.schemeHandler,
                                          forURLScheme: parameters.schemeHandler.scheme)
        return DefaultEngineConfiguration(webViewConfiguration: configuration)
    }
}
