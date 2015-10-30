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
#if MOZ_CHANNEL_AURORA
    public static let BuildChannel = AppBuildChannel.Aurora
#elseif MOZ_CHANNEL_RELEASE
    public static let BuildChannel = AppBuildChannel.Release
#else
    public static let BuildChannel = AppBuildChannel.Developer
#endif

#if MOZ_CHANNEL_DEBUG
    public static let IsDebug = true
#else
    public static let IsDebug = false
#endif

    public static let IsRunningTest = NSClassFromString("XCTestCase") != nil
}
