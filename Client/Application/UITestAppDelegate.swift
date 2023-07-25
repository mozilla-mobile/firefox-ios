// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Kingfisher
import MozillaAppServices
import SQLite

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
        let dirForTestProfile = self.dirForTestProfile

        launchArguments.forEach { arg in
            if arg.starts(with: LaunchArguments.ServerPort) {
                let portString = arg.replacingOccurrences(of: LaunchArguments.ServerPort, with: "")
                if let port = Int(portString) {
                    AppInfo.webserverPort = port
                } else {
                    fatalError("Failed to set web server port override.")
                }
            }
            
//            if arg.starts(with: LaunchArguments.PerfHistory) {
//                // Assuming you want the same logic for copying a DB to the test profile
//                let filename = arg.replacingOccurrences(of: LaunchArguments.PerfHistory, with: "")
//                let input = URL(fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(forResource: filename,
//                                                                                              ofType: nil,
//                                                                                              inDirectory: "test-fixtures")!)
//                try? FileManager.default.createDirectory(atPath: dirForTestProfile, withIntermediateDirectories: false, attributes: nil)
//                let output = URL(fileURLWithPath: "\(dirForTestProfile)/places.db")
//
//                let enumerator = FileManager.default.enumerator(atPath: dirForTestProfile)
//                let filePaths = enumerator?.allObjects as! [String]
//                filePaths.filter { $0.contains(".db") }.forEach { item in
//                    try? FileManager.default.removeItem(at: URL(fileURLWithPath: "\(dirForTestProfile)/\(item)"))
//                }
//
//                try! FileManager.default.copyItem(at: input, to: output)
//
//                // Your Python script seeding logic here
//
//                // Given that you're running this in an XCTest environment, it's important to mention again that
//                // you might not have direct access to run an external script for security reasons.
//                // However, if you still want to proceed, you'd run the Process class here.
//                let process = Process()
//                process.launchPath = "/usr/bin/env"
//                process.arguments = ["python3", "\(input)/generate-test-db.py"]
//
//                let pipe = Pipe()
//                process.standardOutput = pipe
//
//                process.launch()
//                process.waitUntilExit()
//
//                let data = pipe.fileHandleForReading.readDataToEndOfFile()
//                let output = String(data: data, encoding: .utf8)
//                print(output ?? "")
//            }

            
            if arg.starts(with: LaunchArguments.LoadDatabasePrefix) {
                if launchArguments.contains(LaunchArguments.ClearProfile) {
                    fatalError("Clearing profile and loading a test database is not a supported combination.")
                }

                // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
                let filename = arg.replacingOccurrences(of: LaunchArguments.LoadDatabasePrefix, with: "")
                let input = URL(fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(forResource: filename,
                                                                                          ofType: nil,
                                                                                          inDirectory: "test-fixtures")!)
                print("your filename is \(filename)")
                print("your input is \(input)")
                
                var db: Connection!
                let historyVisits = Table("moz_historyvisits")
                let visitDate = Expression<Int>("visit_date")
                let rowid = Expression<Int>("rowid")
                let dbPath = Bundle(for: UITestAppDelegate.self).path(forResource: "testHistoryDatabase500-places", ofType: "db", inDirectory: "test-fixtures")!
                
                do {
                    let path = Bundle(for: type(of: self)).path(forResource: "testHistoryDatabase500-places", ofType: "db", inDirectory: "test-fixtures")!
                    db = try Connection(path, readonly: false)
                } catch {
                    fatalError("Failed to establish SQLite connection: \(error)")
                    return
                }
                // 2. Update the `visit_date`:
                let times = [
                    (0, Date().millisecondsSince1970),
                    (1, Date().addingTimeInterval(-25 * 3600).millisecondsSince1970),
                    (2, Date().addingTimeInterval(-6 * 24 * 3600).millisecondsSince1970),
                    (3, Date().addingTimeInterval(-30 * 24 * 3600).millisecondsSince1970),
                    (4, Date().addingTimeInterval(-31 * 24 * 3600).millisecondsSince1970)
                ]
                for (index, timeValue) in times.enumerated() {
                    let lowerBound = index * 100
                    let upperBound = lowerBound + 99
                    print("Type of visitDate: \(type(of: visitDate))")
                    print("Type of timeValue: \(type(of: timeValue))")
                    print("timeValue is: \(timeValue) \(timeValue.0) \(timeValue.1)")
                    do {
                        try db.run(historyVisits.filter(rowid >= lowerBound && rowid <= upperBound).update(visitDate <- timeValue.1))
                    } catch {
                        fatalError("Failed to update visit_date for rowid between \(lowerBound) and \(upperBound): \(error)")
                    }
                }
                
                // 3. Close the SQLite connection:
                db = nil
                
                try? FileManager.default.createDirectory(atPath: dirForTestProfile, withIntermediateDirectories: false, attributes: nil)
                let output = URL(fileURLWithPath: "\(dirForTestProfile)/places.db")

                let enumerator = FileManager.default.enumerator(atPath: dirForTestProfile)
                let filePaths = enumerator?.allObjects as! [String]
                filePaths.filter { $0.contains(".db") }.forEach { item in
                    try? FileManager.default.removeItem(at: URL(fileURLWithPath: "\(dirForTestProfile)/\(item)"))
                }

                try! FileManager.default.copyItem(at: input, to: output)

                // Tests currently load a browserdb history, we make sure we migrate it everytime
                UserDefaults.standard.setValue(false, forKey: PrefsKeys.PlacesHistoryMigrationSucceeded)
            }

            if arg.starts(with: LaunchArguments.LoadTabsStateArchive) {
                let tabDirectory = "\(self.appRootDir())/profile.profile"
                if launchArguments.contains(LaunchArguments.ClearProfile) {
                    fatalError("Clearing profile and loading a \(LegacyTabManagerStoreImplementation.storePath) is not a supported combination.")
                }

                // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
                let filenameArchive = arg.replacingOccurrences(of: LaunchArguments.LoadTabsStateArchive, with: "")
                let input = URL(fileURLWithPath: Bundle(for: UITestAppDelegate.self).path(forResource: filenameArchive,
                                                                                          ofType: nil,
                                                                                          inDirectory: "test-fixtures")!)
                try? FileManager.default.createDirectory(atPath: tabDirectory, withIntermediateDirectories: false, attributes: nil)
                let outputDir = URL(fileURLWithPath: "\(tabDirectory)/window-data")
                let outputFile = URL(fileURLWithPath: "\(tabDirectory)/window-data/window-44BA0B7D-097A-484D-8358-91A6E374451D")
                let enumerator = FileManager.default.enumerator(atPath: "\(tabDirectory)/window-data")
                let filePaths = enumerator?.allObjects as? [String]
                filePaths?.filter { $0.contains("window-") }.forEach { item in
                    try! FileManager.default.removeItem(at: URL(fileURLWithPath: "\(tabDirectory)/window-data/\(item)"))
                }

                try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
                try! FileManager.default.copyItem(at: input, to: outputFile)
            }
        }

        if launchArguments.contains(LaunchArguments.ClearProfile) {
            // Use a clean profile for each test session.
            profile = BrowserProfile(localName: "testProfile", sendTabDelegate: application.sendTabDelegate, clear: true)
        } else {
            profile = BrowserProfile(localName: "testProfile", sendTabDelegate: application.sendTabDelegate)
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

        if launchArguments.contains(LaunchArguments.TurnOffTabGroupsInUserPreferences) {
            profile.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.TabTrayGroups)
        }

        if launchArguments.contains(LaunchArguments.SkipSponsoredShortcuts) {
            profile.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
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

        self.profile = profile
        return profile
    }

    override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
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
        let docContents = try! manager.contentsOfDirectory(atPath: rootPath)
        for content in docContents {
            do {
                try manager.removeItem(at: documents.appendingPathComponent(content))
            } catch {
                // Couldn't delete some document contents.
            }
        }
    }

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Speed up the animations to 100 times as fast.
        defer { UIWindow.keyWindow?.layer.speed = 100.0 }

        loadExperiment()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func appRootDir() -> String {
        var rootPath = ""
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }
        return rootPath
    }

    // MARK: - Private
    private func loadExperiment() {
        let argument = ProcessInfo.processInfo.arguments.first { string in
            string.starts(with: LaunchArguments.LoadExperiment)
        }

        guard let arg = argument else { return }

        let experimentName = arg.replacingOccurrences(of: LaunchArguments.LoadExperiment, with: "")
        let fileURL = Bundle.main.url(forResource: experimentName, withExtension: "json")
        if let fileURL = fileURL {
            do {
                let fileContent = try String(contentsOf: fileURL)
                let features = HardcodedNimbusFeatures(with: ["messaging": fileContent])
                features.connect(with: FxNimbus.shared)
            } catch {
            }
        }
    }
}

extension Date {
    var millisecondsSince1970: Int {
        return Int(self.timeIntervalSince1970 * 1000.0)
    }
}
