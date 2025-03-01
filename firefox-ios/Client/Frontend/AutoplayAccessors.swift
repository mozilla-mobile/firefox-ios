// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit

/// Accessors to find what should happen when the user opens a web page with media that will autoplay.
struct AutoplayAccessors {
    static let autoplayPrefKey = PrefsKeys.AutoplayMediaKey
    static let defaultSetting = AutoplayAction.allowAudioAndVideo

    static func getAutoplayAction(_ prefs: Prefs?) -> AutoplayAction {
        guard let raw = prefs?.stringForKey(autoplayPrefKey) else { return defaultSetting }

        let option = AutoplayAction(rawValue: raw) ?? defaultSetting
        return option
    }

    static func getMediaTypesRequiringUserActionForPlayback(_ prefs: Prefs?) -> WKAudiovisualMediaTypes {
        // https://developer.apple.com/documentation/webkit/wkaudiovisualmediatypes
        switch getAutoplayAction(prefs) {
        case AutoplayAction.allowAudioAndVideo:
            // To indicate that no user gestures are required to play media, use an empty set of
            // audio/visual media types, indicated by the empty array literal, [].
            return []
        case AutoplayAction.blockAudio:
            // Media types that contain audio require a user gesture to begin playing
            return WKAudiovisualMediaTypes.audio
        case AutoplayAction.blockAudioAndVideo:
            // All media types require a user gesture to begin playing.
            return WKAudiovisualMediaTypes.all
        }
    }
}

/// Enum to encode what should happen when the user opens a web page with media that will autoplay.
enum AutoplayAction: String {
    case allowAudioAndVideo
    case blockAudio
    case blockAudioAndVideo

    var settingTitle: String {
        switch self {
        case .allowAudioAndVideo:
            return .Settings.Autoplay.AllowAudioAndVideo
        case .blockAudio:
            return .Settings.Autoplay.BlockAudio
        case .blockAudioAndVideo:
            return .Settings.Autoplay.BlockAudioAndVideo
        }
    }
}
