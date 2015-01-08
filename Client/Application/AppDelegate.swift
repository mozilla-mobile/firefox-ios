/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!
    var profile: Profile!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        profile = RESTAccountProfile(localName: "profile", credential: NSURLCredential(), logoutCallback: { (profile) -> () in
            // Nothing to do
        })

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.backgroundColor = UIColor.whiteColor()

        let controller = BrowserViewController()
        controller.profile = profile
        self.window.rootViewController = controller
        self.window.makeKeyAndVisible()

        return true
    }

    func application(application: UIApplication, applicationWillTerminate app: UIApplication) {
    }
}
