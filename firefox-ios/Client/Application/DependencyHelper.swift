// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import Shared
import Common
import TabDataStore

class DependencyHelper {
    func bootstrapDependencies() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // Fatal error here so we can gather info as this would cause a crash down the line anyway
            fatalError("Failed to register any dependencies")
        }

        let profile: Profile = appDelegate.profile
        AppContainer.shared.register(service: profile)

        let diskImageStore: DiskImageStore =
        DefaultDiskImageStore(files: profile.files,
                              namespace: TabManagerConstants.tabScreenshotNamespace,
                              quality: UIConstants.ScreenshotQuality)
        AppContainer.shared.register(service: diskImageStore)

        let appSessionProvider: AppSessionProvider = appDelegate.appSessionManager
        AppContainer.shared.register(service: appSessionProvider)

        let ratingPromptManager: RatingPromptManager = appDelegate.ratingPromptManager
        AppContainer.shared.register(service: ratingPromptManager)

        let downloadQueue: DownloadQueue = appDelegate.appSessionManager.downloadQueue
        AppContainer.shared.register(service: downloadQueue)

        let windowManager: WindowManager = appDelegate.windowManager
        AppContainer.shared.register(service: windowManager)

        let themeManager: ThemeManager = appDelegate.themeManager
        AppContainer.shared.register(service: themeManager)

        let microsurveyManager: MicrosurveyManager = MicrosurveySurfaceManager()
        AppContainer.shared.register(service: microsurveyManager)

        let pocketManager: PocketManagerProvider = PocketManager(
            pocketAPI: PocketProvider(prefs: profile.prefs)
        )
        AppContainer.shared.register(service: pocketManager)

        // Tell the container we are done registering
        AppContainer.shared.bootstrap()
    }
}
