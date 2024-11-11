// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage
import TabDataStore
@testable import Client

class DependencyHelperMock {
    func bootstrapDependencies(
        injectedTabManager: TabManager? = nil,
        injectedMicrosurveyManager: MicrosurveyManager? = nil,
        injectedPocketManager: PocketManagerProvider? = nil
    ) {
        AppContainer.shared.reset()

        let profile: Client.Profile = BrowserProfile(
            localName: "profile"
        )
        AppContainer.shared.register(service: profile)

        let diskImageStore: DiskImageStore = DefaultDiskImageStore(
            files: profile.files,
            namespace: TabManagerConstants.tabScreenshotNamespace,
            quality: UIConstants.ScreenshotQuality)
        AppContainer.shared.register(service: diskImageStore)

        let windowUUID = WindowUUID.XCTestDefaultUUID
        let windowManager: WindowManager = MockWindowManager(wrappedManager: WindowManagerImplementation())
        let tabManager: TabManager =
        injectedTabManager ?? TabManagerImplementation(profile: profile,
                                                       uuid: ReservedWindowUUID(uuid: windowUUID, isNew: false),
                                                       windowManager: windowManager)

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider)

        let themeManager: ThemeManager = MockThemeManager()
        AppContainer.shared.register(service: themeManager)

        let ratingPromptManager = RatingPromptManager(profile: profile)
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        AppContainer.shared.register(service: windowManager)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: windowUUID)

        let microsurveyManager: MicrosurveyManager = injectedMicrosurveyManager ?? MockMicrosurveySurfaceManager()
        AppContainer.shared.register(service: microsurveyManager)

        let pocketManager: PocketManagerProvider = injectedPocketManager ?? MockPocketManager()
        AppContainer.shared.register(service: pocketManager)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        AppContainer.shared.reset()
    }
}
