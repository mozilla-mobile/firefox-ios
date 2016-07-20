/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebImage
import XCGLogger

private let log = Logger.browserLogger

class TestAppDelegate: AppDelegate {
    override func getProfile(application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }

        let profile = BrowserProfile(localName: "testProfile", app: application)
        if NSProcessInfo.processInfo().arguments.contains("RESET_FIREFOX") {
            // Use a clean profile for each test session.
            _ = try? profile.files.removeFilesInDirectory()
            profile.prefs.clearAll()

            // Don't show the What's New page.
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Skip the first run UI except when we are running Fastlane Snapshot tests
            if !AppConstants.IsRunningFastlaneSnapshot {
                profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
            }
        }

        self.profile = profile
        return profile
    }

    override func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // If the app is running from a XCUITest reset all settings in the app
        if NSProcessInfo.processInfo().arguments.contains("RESET_FIREFOX") {
            resetApplication()
        }

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }

    /**
     Use this to reset the application between tests.
     **/
    func resetApplication() {
        log.debug("Wiping everything for a clean start.")

        // Clear image cache
        SDImageCache.sharedImageCache().clearDisk()
        SDImageCache.sharedImageCache().clearMemory()

        // Clear the cookie/url cache
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }

        // Clear the documents directory
        var rootPath: String = ""
        if let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier(), url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(sharedContainerIdentifier), path = url.path {
            rootPath = path
        } else {
            rootPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0])
        }
        let manager = NSFileManager.defaultManager()
        let documents = NSURL(fileURLWithPath: rootPath)
        let docContents = try! manager.contentsOfDirectoryAtPath(rootPath)
        for content in docContents {
            do {
                try manager.removeItemAtURL(documents.URLByAppendingPathComponent(content))
            } catch {
                log.debug("Couldn't delete some document contents.")
            }
        }
    }

}