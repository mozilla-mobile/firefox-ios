// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
@testable import Client

class DependencyHelperMock {
    func bootstrapDependencies() {
        AppContainer.shared.reset()

        let profile: Client.Profile = BrowserProfile(
            localName: "profile",
            syncDelegate: UIApplication.shared.syncDelegate
        )
        AppContainer.shared.register(service: profile)

        let tabManager: TabManager = TabManager(
            profile: profile,
            imageStore: DiskImageStore(
                files: profile.files,
                namespace: "TabManagerScreenshots",
                quality: UIConstants.ScreenshotQuality)
        )
        AppContainer.shared.register(service: tabManager)

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider)

        let themeManager: ThemeManager = DefaultThemeManager()
        AppContainer.shared.register(service: themeManager)

        let ratingPromptManager: RatingPromptManager = RatingPromptManager(profile: profile)
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue: DownloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }
}
