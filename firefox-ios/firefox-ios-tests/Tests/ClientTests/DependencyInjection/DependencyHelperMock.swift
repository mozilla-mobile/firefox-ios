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
            localName: "profile"
        )
        AppContainer.shared.register(service: profile)

        let tabManager: TabManager = TabManagerImplementation(
            profile: profile,
            imageStore: DefaultDiskImageStore(
                files: profile.files,
                namespace: "TabManagerScreenshots",
                quality: UIConstants.ScreenshotQuality),
            uuid: .defaultSingleWindowUUID
        )

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider)

        let themeManager: ThemeManager = MockThemeManager()
        AppContainer.shared.register(service: themeManager)

        let ratingPromptManager = RatingPromptManager(profile: profile)
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()

        // Register TabManager with Redux for the current app scene
        // Hardcoded UUID here is temporary; will be removed once PR #17661 is merged
        let defaultSceneUUID = UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!
        store.dispatch(TabManagerAction.tabManagerDidConnectToScene(tabManager))
    }

    func reset() {
        AppContainer.shared.reset()
    }
}
