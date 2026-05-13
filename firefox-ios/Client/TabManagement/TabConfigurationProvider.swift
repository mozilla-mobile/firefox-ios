// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine
import Shared
import WebKit

@MainActor
class TabConfigurationProvider {
    // A WKWebViewConfiguration used for normal tabs
    var configuration: WKEngineConfiguration {
        configuration(from: prefs, isPrivate: false)
    }

    // A WKWebViewConfiguration used for private mode tabs
    var privateConfiguration: WKEngineConfiguration {
        configuration(from: prefs, isPrivate: true)
    }

    private let configurationProvider = DefaultWKEngineConfigurationProvider()
    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
    }

    func configuration(isPrivate: Bool) -> WKEngineConfiguration {
        if isPrivate {
            privateConfiguration
        } else {
            configuration
        }
    }

    func updateAllowsPopups(_ allowsPopups: Bool) {
        configuration.webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowsPopups
        privateConfiguration.webViewConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowsPopups
    }

    func updateMediaTypesRequiringUserActionForPlayback(_ mediaType: WKAudiovisualMediaTypes) {
        configuration.webViewConfiguration.mediaTypesRequiringUserActionForPlayback = mediaType
        privateConfiguration.webViewConfiguration.mediaTypesRequiringUserActionForPlayback = mediaType
    }

    private func configuration(from prefs: Prefs, isPrivate: Bool) -> WKEngineConfiguration {
        let blockPopups = prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true
        let autoPlay = AutoplayAccessors.getMediaTypesRequiringUserActionForPlayback(prefs)
        let parameters = WKWebViewParameters(
            blockPopups: blockPopups,
            isPrivate: isPrivate,
            autoPlay: autoPlay,
            schemeHandler: InternalSchemeHandler()
        )
        let engineConfiguration = configurationProvider.createConfiguration(parameters: parameters)

        // Register the reader-mode scheme handler alongside the internal:// one.
        // DefaultWKEngineConfigurationProvider only wires a single scheme handler today;
        // this is the temporary additional registration until WKWebViewParameters supports
        // multiple handlers.
        let webViewConfig = engineConfiguration.webViewConfiguration
        if webViewConfig.urlSchemeHandler(forURLScheme: ReaderModeSchemeHandler.scheme) == nil {
            webViewConfig.setURLSchemeHandler(ReaderModeSchemeHandler(),
                                              forURLScheme: ReaderModeSchemeHandler.scheme)
        }
        return engineConfiguration
    }
}
