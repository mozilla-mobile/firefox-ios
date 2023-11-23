// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Contains application information necessary for BrowserKit functionalities.
// BrowserKit should stay agnostic of the application it's used in, and so the
// client should pass down this information on setup of the application.
public class BrowserKitInformation {
    public static var shared = BrowserKitInformation()

    public var buildChannel: AppBuildChannel!
    public var nightlyAppVersion: String!
    public var sharedContainerIdentifier: String!

    public func configure(buildChannel: AppBuildChannel,
                          nightlyAppVersion: String,
                          sharedContainerIdentifier: String) {
        self.buildChannel = buildChannel
        self.nightlyAppVersion = nightlyAppVersion
        self.sharedContainerIdentifier = sharedContainerIdentifier
    }
}
