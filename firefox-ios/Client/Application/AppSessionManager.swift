// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol AppSessionProvider {
    var launchSessionProvider: LaunchSessionProviderProtocol { get set }
    var downloadQueue: DownloadQueue { get }
}

/// `AppSessionManager` exists to track, mutate and (sometimes) persist session related properties. Each category of
/// items can be its own `Provider`.
///
/// DO NOT treat this as your go to solution for session property management. It will turn this
/// session manager into a smörgåsbord of countless properties. Consider all options before adding
/// it here, but if it makes sense, go for it.
struct AppSessionManager: AppSessionProvider {
    var launchSessionProvider: LaunchSessionProviderProtocol
    var downloadQueue: DownloadQueue

    init(
        launchSessionProvider: LaunchSessionProvider = LaunchSessionProvider(),
        downloadQueue: DownloadQueue = DownloadQueue()
    ) {
        self.launchSessionProvider = launchSessionProvider
        self.downloadQueue = downloadQueue
    }
}
