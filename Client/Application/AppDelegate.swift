// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.backgroundColor = UIColor.whiteColor()

        let accountManager = AccountManager()

        let loginViewController = LoginViewController()
        loginViewController.accountManager = accountManager

        let tabBarViewController = TabBarViewController(nibName: "TabBarViewController", bundle: nil)
        tabBarViewController.accountManager = accountManager

        accountManager.loginCallback = {
            // Show the tab controller once the user logs in.
            self.window.rootViewController = tabBarViewController
        }
        accountManager.logoutCallback = {
            // Show the login controller once the user logs out.
            self.window.rootViewController = loginViewController
        }

        if (accountManager.isLoggedIn()) {
            self.window.rootViewController = tabBarViewController
        } else {
            let loginViewController = loginViewController
            self.window.rootViewController = loginViewController
        }

        self.window.makeKeyAndVisible()
        return true
    }
}
