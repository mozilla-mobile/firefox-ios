// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebEngine
import Shared
import WebKit

@MainActor
class TabConfigurationProvider {
    // A WKWebViewConfiguration used for normal tabs
    lazy var configuration: WKEngineConfiguration = {
        return configuration(from: prefs, isPrivate: false)
    }()

    // A WKWebViewConfiguration used for private mode tabs
    lazy var privateConfiguration: WKEngineConfiguration = {
        return configuration(from: prefs, isPrivate: true)
    }()

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
            schemeHandler: WKInternalSchemeHandler()
        )
        return configurationProvider.createConfiguration(parameters: parameters)
    }
}
