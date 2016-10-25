/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


class NightlyAppDelegate: AppDelegate {

    override func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        BuddyBuildSDK.setup()
        super.application(application, willFinishLaunchingWithOptions: launchOptions)
        return true
    }
}
