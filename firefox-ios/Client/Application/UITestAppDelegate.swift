// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Kingfisher

import class MozillaAppServices.HardcodedNimbusFeatures

class UITestAppDelegate: AppDelegate, FeatureFlaggable {
    lazy var dirForTestProfile = { return "\(self.appRootDir())/profile.testProfile" }()

    private var internalProfile: Profile?

    override var profile: Profile {
        get {
            getProfile(UIApplication.shared)
        }
        set {
            internalProfile = newValue
        }
    }

    func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.internalProfile {
            return profile
        }

        var profile: BrowserProfile
        let launchArguments = ProcessInfo.processInfo.arguments

        launchArguments.forEach { arg in
            if arg.starts(with: LaunchArguments.ServerPort) {
                configureWebserverPort(arg)
            }

            if arg.starts(with: LaunchArguments.LoadDatabasePrefix) {
                configureDatabase(arg, launchArguments: launchArguments)
            }

            if arg.starts(with: LaunchArguments.LoadTabsStateArchive) {
                let tabDirectory = "\(self.appRootDir())/profile.profile"
                if launchArguments.contains(LaunchArguments.ClearProfile) {
                    fatalError("Clearing profile and loading tabs, not a supported combination.")
                }

                // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
                let filenameArchive = arg.replacingOccurrences(of: LaunchArguments.LoadTabsStateArchive, with: "")
                let input = URL(
                    fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(
                        forResource: filenameArchive,
                        ofType: nil,
                        inDirectory: "test-fixtures"
                    )!
                )
                try? FileManager.default.createDirectory(
                    atPath: tabDirectory,
                    withIntermediateDirectories: false,
                    attributes: nil
                )
                let outputDir = URL(fileURLWithPath: "\(tabDirectory)/window-data")
                let outputFile = URL(
                    fileURLWithPath: "\(tabDirectory)/window-data/window-44BA0B7D-097A-484D-8358-91A6E374451D"
                )
                let enumerator = FileManager.default.enumerator(atPath: "\(tabDirectory)/window-data")
                let filePaths = enumerator?.allObjects as? [String]
                filePaths?.filter { $0.contains("window-") }.forEach { item in
                    do {
                        try FileManager.default.removeItem(
                            at: URL(fileURLWithPath: "\(tabDirectory)/window-data/\(item)")
                        )
                    } catch {
                        fatalError("Could not remove items at \(tabDirectory)/window-data/\(item): \(error)")
                    }
                }

                try? FileManager.default.createDirectory(
                    at: outputDir,
                    withIntermediateDirectories: true
                )

                do {
                    try FileManager.default.copyItem(at: input, to: outputFile)
                } catch {
                    fatalError("Could not copy items at from \(input) to \(outputFile): \(error)")
                }
            }
        }

        if launchArguments.contains(LaunchArguments.ClearProfile) {
            // Use a clean profile for each test session.
            profile = BrowserProfile(
                localName: "testProfile",
                fxaCommandsDelegate: application.fxaCommandsDelegate,
                clear: true
            )
        } else {
            profile = BrowserProfile(
                localName: "testProfile",
                fxaCommandsDelegate: application.fxaCommandsDelegate
            )
        }

        if launchArguments.contains(LaunchArguments.SkipAddingGoogleTopSite) {
            profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)
        }

        // Don't show the Contextual hint for jump back in section.
        if launchArguments.contains(LaunchArguments.SkipContextualHints) {
            PrefsKeys.ContextualHints.allCases.forEach {
                profile.prefs.setBool(true, forKey: $0.rawValue)
            }
        }

        if launchArguments.contains(LaunchArguments.SkipSponsoredShortcuts) {
            profile.prefs.setBool(false, forKey: PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts)
        }

        // Don't show the What's New page.
        if launchArguments.contains(LaunchArguments.SkipWhatsNew) {
            profile.prefs.setInt(1, forKey: PrefsKeys.AppVersion.Latest)
        }

        if launchArguments.contains(LaunchArguments.SkipDefaultBrowserOnboarding) {
            profile.prefs.setBool(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
        }

        // Skip the intro when requested by for example tests or automation
        if launchArguments.contains(LaunchArguments.SkipIntro) {
            IntroScreenManager(prefs: profile.prefs).didSeeIntroScreen()
        }

        if launchArguments.contains(LaunchArguments.StageServer) {
            profile.prefs.setInt(1, forKey: PrefsKeys.UseStageServer)
        }

        if launchArguments.contains(LaunchArguments.FxAChinaServer) {
            profile.prefs.setInt(1, forKey: PrefsKeys.KeyEnableChinaSyncService)
        }

        if launchArguments.contains(LaunchArguments.DisableAnimations) {
            UIView.setAnimationsEnabled(false)
        }

        if launchArguments.contains(LaunchArguments.SkipSplashScreenExperiment) {
            profile.prefs.setBool(true, forKey: PrefsKeys.splashScreenShownKey)
        }

        if launchArguments.contains(LaunchArguments.ResetMicrosurveyExpirationCount) {
            // String is pulled from our "evergreen" messages configurations 
            // that are displayed via the Nimbus Messaging system.
            let microsurveyID = "homepage-microsurvey-message"
            UserDefaults.standard.set(nil, forKey: "\(GleanPlumbMessageStore.rootKey)\(microsurveyID)")
        }

        self.profile = profile
        return profile
    }

    private func configureWebserverPort(_ arg: String) {
        let portString = arg.replacingOccurrences(of: LaunchArguments.ServerPort, with: "")
        if let port = Int(portString) {
            AppInfo.webserverPort = port
        } else {
            fatalError("Failed to set web server port override.")
        }
    }

    private func configureDatabase(_ arg: String, launchArguments: [String]) {
        if launchArguments.contains(LaunchArguments.ClearProfile) {
            fatalError("Clearing profile and loading a test database is not a supported combination.")
        }

        // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
        let filename = arg.replacingOccurrences(of: LaunchArguments.LoadDatabasePrefix, with: "")
        let input = URL(
            fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(
                forResource: filename,
                ofType: nil,
                inDirectory: "test-fixtures"
            )!
        )
        try? FileManager.default.createDirectory(
            atPath: dirForTestProfile,
            withIntermediateDirectories: false,
            attributes: nil
        )
        let output = URL(fileURLWithPath: "\(dirForTestProfile)/places.db")

        let enumerator = FileManager.default.enumerator(atPath: dirForTestProfile)
        let filePaths = enumerator?.allObjects as! [String]
        filePaths.filter { $0.contains(".db") }.forEach { item in
            try? FileManager.default.removeItem(
                at: URL(fileURLWithPath: "\(dirForTestProfile)/\(item)")
            )
        }

        do {
            try FileManager.default.copyItem(at: input, to: output)
        } catch {
            fatalError("Could not copy items from \(input) to \(output): \(error)")
        }

        // Tests currently load a browserdb history, we make sure we migrate it everytime
        UserDefaults.standard.setValue(false, forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
    }

    fileprivate func configureTabs(_ arg: String, launchArguments: [String]) {
        let tabDirectory = "\(self.appRootDir())/profile.profile"
        if launchArguments.contains(LaunchArguments.ClearProfile) {
            fatalError("Clearing profile and loading tabs, not a supported combination.")
        }

        // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
        let filenameArchive = arg.replacingOccurrences(of: LaunchArguments.LoadTabsStateArchive, with: "")
        let input = URL(
            fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(
                forResource: filenameArchive,
                ofType: nil,
                inDirectory: "test-fixtures"
            )!
        )
        try? FileManager.default.createDirectory(
            atPath: tabDirectory,
            withIntermediateDirectories: false,
            attributes: nil
        )
        let outputDir = URL(fileURLWithPath: "\(tabDirectory)/window-data")
        let outputFile = URL(
            fileURLWithPath: "\(tabDirectory)/window-data/window-44BA0B7D-097A-484D-8358-91A6E374451D"
        )
        let enumerator = FileManager.default.enumerator(atPath: "\(tabDirectory)/window-data")
        let filePaths = enumerator?.allObjects as? [String]
        filePaths?.filter { $0.contains("window-") }.forEach { item in
            do {
                try FileManager.default.removeItem(
                    at: URL(fileURLWithPath: "\(tabDirectory)/window-data/\(item)")
                )
            } catch {
                fatalError("Could not remove items at \(tabDirectory)/window-data/\(item): \(error)")
            }
        }

        try? FileManager.default.createDirectory(
            at: outputDir,
            withIntermediateDirectories: true
        )

        do {
            try FileManager.default.copyItem(at: input, to: outputFile)
        } catch {
            fatalError("Could not copy items at from \(input) to \(outputFile): \(error)")
        }
    }

    override func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // If the app is running from a XCUITest reset all settings in the app
        if ProcessInfo.processInfo.arguments.contains(LaunchArguments.ClearProfile) {
            resetApplication()
        }

        Tab.ChangeUserAgent.clear()

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    /// Use this to reset the application between tests.
    func resetApplication() {
        // Clear image cache - Kingfisher
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache()

        // Clear the cookie/url cache
        URLCache.shared.removeAllCachedResponses()
        let storage = HTTPCookieStorage.shared
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }

        // Clear the documents directory
        let rootPath = appRootDir()
        let manager = FileManager.default
        let documents = URL(fileURLWithPath: rootPath)
        do {
            let docContents = try manager.contentsOfDirectory(atPath: rootPath)
            for content in docContents {
                do {
                    try manager.removeItem(at: documents.appendingPathComponent(content))
                } catch {
                    // Couldn't delete some document contents.
                }
            }
        } catch {
            fatalError("Could not retrieve documents at \(rootPath): \(error)")
        }
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Speed up the animations to 100 times as fast.
        defer { UIWindow.keyWindow?.layer.speed = 100.0 }

        loadExperiment()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func appRootDir() -> String {
        var rootPath = ""
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: sharedContainerIdentifier
        ) {
            rootPath = url.path
        } else {
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }
        return rootPath
    }

    // MARK: - Private
    private func loadExperiment() {
        let argumentExperimentFile = ProcessInfo.processInfo.arguments.first { string in
            string.starts(with: LaunchArguments.LoadExperiment)
        }

        let argumentFeatureName = ProcessInfo.processInfo.arguments.first { string in
            string.starts(with: LaunchArguments.ExperimentFeatureName)
        }

        guard let argumentExperimentFile, let argumentFeatureName else { return }

        let experimentFeatureName = argumentFeatureName.replacingOccurrences(of: LaunchArguments.ExperimentFeatureName,
                                                                             with: "")
        let experimentFileName = argumentExperimentFile.replacingOccurrences(of: LaunchArguments.LoadExperiment,
                                                                             with: "")
        let fileURL = Bundle.main.url(forResource: experimentFileName, withExtension: "json")
        if let fileURL = fileURL {
            do {
                let fileContent = try String(contentsOf: fileURL)
                let features = HardcodedNimbusFeatures(with: [experimentFeatureName: fileContent])
                features.connect(with: FxNimbus.shared)
            } catch {
            }
        }
    }
}
