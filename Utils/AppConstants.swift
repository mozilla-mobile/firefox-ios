/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public enum AppBuildChannel {
    case Release
    case Beta
    case Nightly
    case Fennec
    case Aurora
    case Unknown
}

public struct AppConstants {
    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil

    // True if this process is executed as part of a Fastlane Snapshot test
    public static let IsRunningFastlaneSnapshot = NSProcessInfo.processInfo().arguments.contains("FASTLANE_SNAPSHOT")

    /// Build Channel.
    public static let BuildChannel: AppBuildChannel = {
        #if MOZ_CHANNEL_RELEASE
            return AppBuildChannel.Release
        #elseif MOZ_CHANNEL_BETA
            return AppBuildChannel.Beta
        #elseif MOZ_CHANNEL_NIGHTLY
            return AppBuildChannel.Nightly
        #elseif MOZ_CHANNEL_FENNEC
            return AppBuildChannel.Fennec
        #elseif MOZ_CHANNEL_AURORA
            return AppBuildChannel.Aurora
        #else
            return AppBuildChannel.Unknown
        #endif
    }()

    /// Whether we just mirror (false) or actively merge and upload (true).
    public static let shouldMergeBookmarks = false

    /// Flag indiciating if we are running in Debug mode or not.
    public static let isDebug: Bool = {
        #if MOZ_CHANNEL_FENNEC
            return true
        #else
            return false
        #endif
    }()

    /// Enables/disables the new Menu functionality
    public static let MOZ_MENU: Bool = {
        #if MOZ_CHANNEL_RELEASE
            return false
        #elseif MOZ_CHANNEL_BETA
            return false
        #elseif MOZ_CHANNEL_NIGHTLY
            return true
        #elseif MOZ_CHANNEL_FENNEC
            return true
        #else
            return true
        #endif
    }()
}
