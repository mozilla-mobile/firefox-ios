// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
@testable import Client

class DependencyHelperMock {
    func bootstrapDependencies(
        injectedWindowManager: WindowManager? = nil,
        injectedTabManager: TabManager? = nil,
        injectedMicrosurveyManager: MicrosurveyManager? = nil,
        injectedMerinoManager: MerinoManagerProvider? = nil
    ) {
        AppContainer.shared.reset()

        let profile: Profile = BrowserProfile(
            localName: "profile"
        )
        AppContainer.shared.register(service: profile as Profile)

        let diskImageStore: DiskImageStore = DefaultDiskImageStore(
            files: profile.files,
            namespace: TabManagerConstants.tabScreenshotNamespace,
            quality: UIConstants.ScreenshotQuality)
        AppContainer.shared.register(service: diskImageStore as DiskImageStore)

        let windowUUID = WindowUUID.XCTestDefaultUUID
        let windowManager: WindowManager = injectedWindowManager ?? MockWindowManager(
            wrappedManager: WindowManagerImplementation()
        )

        var tabManager: TabManager!

        let appSessionProvider: AppSessionProvider = AppSessionManager()
        AppContainer.shared.register(service: appSessionProvider as AppSessionProvider)

        // FIXME: FXIOS-13151 We need to handle main actor synchronized state in this setup method used across all unit tests
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                tabManager = injectedTabManager ?? MockTabManager()
                AppContainer.shared.register(service: MockThemeManager() as ThemeManager)

                let searchEnginesManager = SearchEnginesManager(
                    prefs: profile.prefs,
                    files: profile.files,
                    engineProvider: MockSearchEngineProvider()
                )
                AppContainer.shared.register(service: searchEnginesManager)
            }
        } else {
            DispatchQueue.main.sync {
                tabManager = injectedTabManager ??  MockTabManager()
                AppContainer.shared.register(service: MockThemeManager() as ThemeManager)

                let searchEnginesManager = SearchEnginesManager(
                    prefs: profile.prefs,
                    files: profile.files,
                    engineProvider: MockSearchEngineProvider()
                )
                AppContainer.shared.register(service: searchEnginesManager)
            }
        }

        let downloadQueue = DownloadQueue()
        AppContainer.shared.register(service: downloadQueue)

        AppContainer.shared.register(service: windowManager as WindowManager)
        windowManager.newBrowserWindowConfigured(AppWindowInfo(tabManager: tabManager), uuid: windowUUID)

        let microsurveyManager: MicrosurveyManager = injectedMicrosurveyManager ?? MockMicrosurveySurfaceManager()
        AppContainer.shared.register(service: microsurveyManager as MicrosurveyManager)

        let merinoManager: MerinoManagerProvider = injectedMerinoManager ?? MockMerinoManager()
        AppContainer.shared.register(service: merinoManager as MerinoManagerProvider)

        let documentLogger = DocumentLogger(logger: MockLogger())
        AppContainer.shared.register(service: documentLogger)

        let gleanUsageReportingMetricsService: GleanUsageReportingMetricsService =
        MockGleanUsageReportingMetricsService(profile: profile)
        AppContainer.shared.register(service: gleanUsageReportingMetricsService)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }

    func reset() {
        AppContainer.shared.reset()
    }
}
