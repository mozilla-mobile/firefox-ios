/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.backgroundColor = UIColor.whiteColor()

        self.window.rootViewController = BrowserViewController()

        self.window.makeKeyAndVisible()
        return true
    }

    func application(application: UIApplication, applicationWillTerminate app: UIApplication) {
    }
}
