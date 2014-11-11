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

        var accountManager: AccountManager!
        accountManager = AccountManager(
            loginCallback: { account in
                // Show the tab controller once the user logs in.
                self.showTabBarViewController(account)
            },
            logoutCallback: {
                // Show the login controller once the user logs out.
                self.showLoginViewController(accountManager)
            })

        if let account = accountManager.getAccount() {
            // The user is already logged in, so go straight to the tab controller.
            showTabBarViewController(account)
        } else {
            // The user is not logged in, so show the login screen.
            showLoginViewController(accountManager)
        }

        self.window.makeKeyAndVisible()
        return true
    }

    func showTabBarViewController(account: Account) {
        let tabBarViewController = TabBarViewController(nibName: "TabBarViewController", bundle: nil)
        tabBarViewController.account = account
        self.window.rootViewController = tabBarViewController
    }

    func showLoginViewController(accountManager: AccountManager) {
        let loginViewController = LoginViewController()
        loginViewController.accountManager = accountManager
        self.window.rootViewController = loginViewController
    }
}
