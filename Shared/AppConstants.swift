/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public enum AppBuildChannel: String {
    case release = "release"
    case beta = "beta"
    case developer = "developer"
}

public struct AppConstants {
    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil || ProcessInfo.processInfo.arguments.contains(LaunchArguments.Test)

    public static let SkipIntro = ProcessInfo.processInfo.arguments.contains(LaunchArguments.SkipIntro)
    public static let ClearProfile = ProcessInfo.processInfo.arguments.contains(LaunchArguments.ClearProfile)

    public static let FxAiOSClientId = "1b1a3e44c54fbb58"

    /// Build Channel.
    public static let BuildChannel: AppBuildChannel = {
        #if MOZ_CHANNEL_RELEASE
            return AppBuildChannel.release
        #elseif MOZ_CHANNEL_BETA
            return AppBuildChannel.beta
        #elseif MOZ_CHANNEL_FENNEC
            return AppBuildChannel.developer
        #endif
    }()

    public static let scheme: String = {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return "unknown"
        }

        let scheme = identifier.replacingOccurrences(of: "org.mozilla.ios.", with: "")
        if scheme == "FirefoxNightly.enterprise" {
            return "FirefoxNightly"
        }
        return scheme
    }()

    /// Whether we just mirror (false) or actively do a full bookmark merge and upload (true).
    public static var shouldMergeBookmarks = false

    /// Should we try to sync (no merging) the Mobile Folder (if shouldMergeBookmarks is false).
    public static let MOZ_SIMPLE_BOOKMARKS_SYNCING: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Should we send a repair request to other clients when the bookmarks buffer validation fails.
    public static let MOZ_BOOKMARKS_REPAIR_REQUEST: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Flag indiciating if we are running in Debug mode or not.
    public static let isDebug: Bool = {
        #if MOZ_CHANNEL_FENNEC
            return true
        #else
            return false
        #endif
    }()

    /// Enables/disables the availability of No Image Mode.
    public static let MOZ_NO_IMAGE_MODE: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Enables support for International Domain Names (IDN)
    /// Disabled because of https://bugzilla.mozilla.org/show_bug.cgi?id=1312294
    public static let MOZ_PUNYCODE: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    ///  Enables/disables deep linking form fill for FxA
    public static let MOZ_FXA_DEEP_LINK_FORM_FILL: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return true
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Toggles reporting our ad-hoc bookmark sync ping
    public static let MOZ_ADHOC_SYNC_REPORTING: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Toggles the ability to add a custom search engine
    public static let MOZ_CUSTOM_SEARCH_ENGINE: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    ///  Enables/disables push notificatuibs for FxA
    public static let MOZ_FXA_PUSH: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    ///  Toggle the feature that shows the blue 'Open copied link' banner
    public static let MOZ_CLIPBOARD_BAR: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()

    /// Toggle the use of Leanplum.
    public static let MOZ_ENABLE_LEANPLUM: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_FENNEC
            return false
        #else
            return false
        #endif
    }()

    ///  Toggle the feature that shows updated FxA preferences cell
    public static let MOZ_SHOW_FXA_AVATAR: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()
}
