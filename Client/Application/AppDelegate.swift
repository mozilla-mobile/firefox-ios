// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let tabBarViewController = TabBarViewController(nibName: "TabBarViewController", bundle: nil)
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.rootViewController = tabBarViewController
        self.window.backgroundColor = UIColor.whiteColor()
        self.window.makeKeyAndVisible()
        return true
    }
}
