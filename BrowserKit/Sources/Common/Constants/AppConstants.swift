// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

public enum AppBuildChannel: String {
    case release = "release"
    case beta = "beta"
    case developer = "developer"

    // Used for unknown cases
    case other = "other"
}

// TODO: FXIOS-5698 Implement injection into BrowserKit for AppConstants and AppInfo
open class AppConstants {
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

    /// Fixed short version for nightly builds
    public static let NIGHTLY_APP_VERSION = "9000"
}
