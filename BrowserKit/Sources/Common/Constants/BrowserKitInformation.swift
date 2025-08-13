// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Contains application information necessary for BrowserKit functionalities.
/// FIXME: FXIOS-13125 We should be able to mark this Sendable without mutable state
public class BrowserKitInformation: @unchecked Sendable {
    // FIXME: FXIOS-13125 Shared state for the app should not be stored in the Common package.
    public static let shared = BrowserKitInformation()

    public var buildChannel: AppBuildChannel?
    public var nightlyAppVersion: String?
    public var sharedContainerIdentifier: String?

    public func configure(buildChannel: AppBuildChannel,
                          nightlyAppVersion: String,
                          sharedContainerIdentifier: String) {
        self.buildChannel = buildChannel
        self.nightlyAppVersion = nightlyAppVersion
        self.sharedContainerIdentifier = sharedContainerIdentifier
    }
}
