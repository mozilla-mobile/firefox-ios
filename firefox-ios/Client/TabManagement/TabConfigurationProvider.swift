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
        configuration(from: profile, isPrivate: false)
    }

    // A WKWebViewConfiguration used for private mode tabs
    var privateConfiguration: WKEngineConfiguration {
        configuration(from: profile, isPrivate: true)
    }

    private let configurationProvider = DefaultWKEngineConfigurationProvider()
    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
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

    private func configuration(from profile: Profile, isPrivate: Bool) -> WKEngineConfiguration {
        let blockPopups = profile.prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true
        let autoPlay = AutoplayAccessors.getMediaTypesRequiringUserActionForPlayback(profile.prefs)
        let parameters = WKWebViewParameters(
            blockPopups: blockPopups,
            isPrivate: isPrivate,
            autoPlay: autoPlay,
            schemeHandler: InternalSchemeHandler()
        )
        let engineConfiguration = configurationProvider.createConfiguration(parameters: parameters)

        // Register the reader-mode scheme handler alongside the internal:// one.
        // The handler picks disk vs memory cache per request based on
        // the WKWebView's data store, so a single handler instance is correct for both
        // normal and private tabs.
        let webViewConfig = engineConfiguration.webViewConfiguration
        if webViewConfig.urlSchemeHandler(forURLScheme: ReaderModeSchemeHandler.scheme) == nil {
            webViewConfig.setURLSchemeHandler(
                ReaderModeSchemeHandler(profile: profile),
                forURLScheme: ReaderModeSchemeHandler.scheme
            )
        }
        return engineConfiguration
    }
}
