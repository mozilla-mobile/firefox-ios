// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockAppSessionManager: AppSessionProvider {
    var launchSessionProvider: LaunchSessionProviderProtocol
    var downloadQueue: DownloadQueue

    init(
        launchSessionProvider: LaunchSessionProviderProtocol = MockLaunchSessionProvider(),
        downloadQueue: DownloadQueue = DownloadQueue()
    ) {
        self.launchSessionProvider = launchSessionProvider
        self.downloadQueue = downloadQueue
    }
}
