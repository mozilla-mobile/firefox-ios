/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public enum AppBuildChannel {
    case Developer
    case Aurora
    case Release
}

public struct AppConstants {

    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil


    /// Build Channel.
    public static let BuildChannel: AppBuildChannel = {
#if MOZ_CHANNEL_AURORA
    return AppBuildChannel.Aurora
#elseif MOZ_CHANNEL_RELEASE
    return AppBuildChannel.Release
#else
    return AppBuildChannel.Developer
#endif
    }()


    /// Flag indiciating if we are running in Debug mode or not.
    public static let isDebug: Bool = {
#if MOZ_CHANNEL_DEBUG
    return true
#else
    return false
#endif
    }()


    /// Enables/disables the Login manager UI by hiding the 'Logins' setting item.
    public static let MOZ_LOGIN_MANAGER: Bool = {
#if MOZ_CHANNEL_AURORA
    return true
#elseif MOZ_CHANNEL_RELEASE
    return true
#else
    return true
#endif
    }()
}
