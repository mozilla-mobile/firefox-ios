// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import MozillaAppServices

@objc(UnitTestAppDelegate)
final class UnitTestAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /// Initialize app services ( including NSS ). Must be called before any other calls to rust components.
        /// This needs to be called early on, otherwise stuff like enc/dec fails.
        MozillaAppServices.initialize()
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Remove any cached scene configurations to ensure that
        // TestingAppDelegate.application(_:configurationForConnecting:options:) is called
        // and TestingSceneDelegate will be used when running unit tests.
        // NOTE: THIS IS PRIVATE API AND MAY BREAK IN THE FUTURE!
        for sceneSession in application.openSessions {
            application.perform(Selector(("_removeSessionFromSessionSet:")), with: sceneSession)
        }
        UserDefaults.standard.setValue(true, forKey: "_FennecLaunchedUnitTestDelegate")
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = UnitTestSceneDelegate.self
        sceneConfiguration.storyboard = nil

        return sceneConfiguration
    }
}
