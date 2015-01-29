/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!
    var profile: Profile!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Setup a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        setupWebServer()

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

    private func setupWebServer() {
        let server = WebServer.sharedInstance
        // Register our fonts, which we want to expose to web content that we present in the WebView
        server.registerMainBundleResourcesOfType("ttf", module: "fonts")
        // TODO: In the future let other modules register specific resources here. Unfortunately you cannot add
        // more handlers after start() has been called, so we need to organize it all here at app startup time.
        server.start()
    }
}
