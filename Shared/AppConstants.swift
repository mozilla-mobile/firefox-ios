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

    /// Whether we just mirror (false) or actively merge and upload (true).
    public static var shouldMergeBookmarks = false

    /// Flag indiciating if we are running in Debug mode or not.
    public static let isDebug: Bool = {
        #if MOZ_CHANNEL_FENNEC
            return true
        #else
            return false
        #endif
    }()

    ///  Enables/disables the notification bar that appears on the status bar area
    public static let MOZ_STATUS_BAR_NOTIFICATION: Bool = {
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
    
    /// Enables/disables the availability of No Image Mode.
    public static let MOZ_NO_IMAGE_MODE: Bool = {
        return true
    }()

    /// Enables/disables the availability of Night Mode.
    public static let MOZ_NIGHT_MODE: Bool = {
        return true
    }()
    
    ///  Enables/disables the top tabs for iPad
    public static let MOZ_TOP_TABS: Bool = {
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

    /// Toggles the ability to reorder tabs in the tab tray
    public static let MOZ_REORDER_TAB_TRAY: Bool = {
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

    /// Enables the injection of the experimental page-metadata-parser into the WKWebView for
    /// extracting metadata content from web pages
    public static let MOZ_CONTENT_METADATA_PARSING: Bool = {
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

    ///  Enables/disables the activity stream for iPhone
    public static let MOZ_AS_PANEL: Bool = {
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
}
