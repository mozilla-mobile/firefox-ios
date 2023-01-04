// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public enum AppName: String, CustomStringConvertible {
    case shortName = "Firefox"

    public var description: String {
        return self.rawValue
    }
}

public enum AppBuildChannel: String {
    case release = "release"
    case beta = "beta"
    case developer = "developer"

    // Used for unknown cases
    case other = "other"
}

public enum KVOConstants: String {
    case loading = "loading"
    case estimatedProgress = "estimatedProgress"
    case URL = "URL"
    case title = "title"
    case canGoBack = "canGoBack"
    case canGoForward = "canGoForward"
    case contentSize = "contentSize"
}

public struct KeychainKey {
    public static let fxaPushRegistration = "account.push-registration"
    public static let apnsToken = "apnsToken"
}

public struct AppConstants {
    // Any type of tests (UI and Unit)
    public static let isRunningTest = NSClassFromString("XCTestCase") != nil
    || AppConstants.isRunningUITests
    || AppConstants.isRunningPerfTests

    // Unit tests only
    public static let isRunningUnitTest = NSClassFromString("XCTestCase") != nil
    && !AppConstants.isRunningUITests
    && !AppConstants.isRunningPerfTests

    // Only UI tests
    public static let isRunningUITests = ProcessInfo.processInfo.arguments.contains(LaunchArguments.Test)

    // Only performance tests
    public static let isRunningPerfTests = ProcessInfo.processInfo.arguments.contains(LaunchArguments.PerformanceTest)

    public static let FxAiOSClientId = "1b1a3e44c54fbb58"

    /// Build Channel.
    public static let BuildChannel: AppBuildChannel = {
        #if MOZ_CHANNEL_RELEASE
            return AppBuildChannel.release
        #elseif MOZ_CHANNEL_BETA
            return AppBuildChannel.beta
        #elseif MOZ_CHANNEL_FENNEC
            return AppBuildChannel.developer
        #else
            return AppBuildChannel.other
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

    public static let PrefSendUsageData = "settings.sendUsageData"
    public static let PrefStudiesToggle = "settings.studiesToggle"

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

    /// The maximum length of a URL stored by Firefox. Shared with Places on desktop.
    public static let DB_URL_LENGTH_MAX = 65536

    /// The maximum length of a page title stored by Firefox. Shared with Places on desktop.
    public static let DB_TITLE_LENGTH_MAX = 4096

    /// The maximum length of a bookmark description stored by Firefox. Shared with Places on desktop.
    public static let DB_DESCRIPTION_LENGTH_MAX = 1024

    /// Fixed short version for nightly builds
    public static let NIGHTLY_APP_VERSION = "9000"

    /// Time that needs to pass before polling FxA for send tabs again, 86_400_000 milliseconds is 1 day
    public static let FXA_COMMANDS_INTERVAL = 86_400_000

    /// The maximum number of times we should attempt to migrated the History to Application Services Places DB
    public static let MAX_HISTORY_MIGRATION_ATTEMPT = 5

    /// The maximum size of the places DB in bytes
    public static let DB_SIZE_LIMIT_IN_BYTES: UInt32 = 75 * 1024 * 1024 // corresponds to 75MiB (in bytes)
}
