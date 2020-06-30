/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SDWebImage
import XCGLogger

private let log = Logger.browserLogger

class TestAppDelegate: AppDelegate {

    lazy var dirForTestProfile = { return "\(self.appRootDir())/profile.testProfile" }()

    override func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }

        var profile: BrowserProfile
        let launchArguments = ProcessInfo.processInfo.arguments

        launchArguments.forEach { arg in
            if arg.starts(with: LaunchArguments.ServerPort) {
                let portString = arg.replacingOccurrences(of: LaunchArguments.ServerPort, with: "")
                if let port = Int(portString) {
                    AppInfo.webserverPort = port
                } else {
                    fatalError("Failed to set web server port override.")
                }
            }

            if arg.starts(with: LaunchArguments.LoadDatabasePrefix) {
                if launchArguments.contains(LaunchArguments.ClearProfile) {
                    fatalError("Clearing profile and loading a test database is not a supported combination.")
                }

                // Grab the name of file in the bundle's test-fixtures dir, and copy it to the runtime app dir.
                let filename = arg.replacingOccurrences(of: LaunchArguments.LoadDatabasePrefix, with: "")
                let input = URL(fileURLWithPath: Bundle(for: TestAppDelegate.self).path(forResource: filename, ofType: nil, inDirectory: "test-fixtures")!)
                try? FileManager.default.createDirectory(atPath: dirForTestProfile, withIntermediateDirectories: false, attributes: nil)
                let output = URL(fileURLWithPath: "\(dirForTestProfile)/browser.db")

                let enumerator = FileManager.default.enumerator(atPath: dirForTestProfile)
                let filePaths = enumerator?.allObjects as! [String]
                filePaths.filter { $0.contains(".db") }.forEach { item in
                    try! FileManager.default.removeItem(at: URL(fileURLWithPath: "\(dirForTestProfile)/\(item)"))
                }

                try! FileManager.default.copyItem(at: input, to: output)
            }
        }

        if launchArguments.contains(LaunchArguments.ClearProfile) {
            // Use a clean profile for each test session.
            log.debug("Deleting all files in 'Documents' directory to clear the profile")
            profile = BrowserProfile(localName: "testProfile", syncDelegate: application.syncDelegate, clear: true)
        } else {
            profile = BrowserProfile(localName: "testProfile", syncDelegate: application.syncDelegate)
        }

        // Don't show the ETP Coversheet New page.
        if launchArguments.contains(LaunchArguments.SkipETPCoverSheet) {
            profile.prefs.setString(ETPCoverSheetShowType.DoNotShow.rawValue, forKey: PrefsKeys.KeyETPCoverSheetShowType)
        }
        
        // Don't show the What's New page.
        if launchArguments.contains(LaunchArguments.SkipWhatsNew) {
            profile.prefs.setInt(1, forKey: PrefsKeys.KeyLastVersionNumber)
        }

        // Skip the intro when requested by for example tests or automation
        if launchArguments.contains(LaunchArguments.SkipIntro) {
            profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        }

        if launchArguments.contains(LaunchArguments.StageServer) {
            profile.prefs.setInt(1, forKey: PrefsKeys.UseStageServer)
        }

        self.profile = profile
        return profile
    }

    override func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // If the app is running from a XCUITest reset all settings in the app
        if ProcessInfo.processInfo.arguments.contains(LaunchArguments.ClearProfile) {
            resetApplication()
        }

        Tab.ChangeUserAgent.clear()

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    /**
     Use this to reset the application between tests.
     **/
    func resetApplication() {
        log.debug("Wiping everything for a clean start.")

        // Clear image cache
        SDImageCache.shared.clearDisk()
        SDImageCache.shared.clearMemory()

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
                log.debug("Couldn't delete some document contents.")
            }
        }
    }

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Speed up the animations to 100 times as fast.
        defer { application.keyWindow?.layer.speed = 100.0 }
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
}
