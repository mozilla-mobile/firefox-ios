// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Contains application information necessary for BrowserKit functionalities.
public struct BrowserKitInformation: Sendable {
    public static let shared = BrowserKitInformation(buildChannel: AppConstants.buildChannel,
                                                     nightlyAppVersion: AppConstants.nightlyAppVersion,
                                                     sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)

    public let buildChannel: AppBuildChannel
    public let nightlyAppVersion: String
    public let sharedContainerIdentifier: String
}
