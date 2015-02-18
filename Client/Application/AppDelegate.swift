/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Alamofire

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

        checkForAuroraUpdate()

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

/// Everything below is for the Aurora version check. There is no conditional compilation in Swift so this code is only
/// executed when our bundle identifier is FennecAurora.

private let AuroraBundleIdentifier = "org.mozilla.ios.FennecAurora"
private let AuroraPropertyListURL = "https://pvtbuilds.mozilla.org/ios/FennecAurora.plist"
private let AuroraDownloadPageURL = "https://pvtbuilds.mozilla.org/ios/index.html"

extension AppDelegate: UIAlertViewDelegate {
    private func checkForAuroraUpdate() {
        if isAuroraChannel() {
            if let localVersion = localVersion() {
                fetchLatestAuroraVersion() { version in
                    if let remoteVersion = version {
                        if localVersion.compare(remoteVersion, options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending {
                            let alert = UIAlertView(title: "New version available", message: "There is a new version available of Firefox Aurora. Tap OK to go to the download page.", delegate: self, cancelButtonTitle: "Not Now", otherButtonTitles: "OK")
                            alert.show()
                        }
                    }
                }
            }
        }
    }

    private func isAuroraChannel() -> Bool {
        return NSBundle.mainBundle().bundleIdentifier == AuroraBundleIdentifier
    }

    private func localVersion() -> NSString? {
        return NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey) as? String
    }

    private func fetchLatestAuroraVersion(completionHandler: NSString? -> Void) {
        Alamofire.request(.GET, AuroraPropertyListURL).responsePropertyList({ (_, _, object, _) -> Void in
            if let plist = object as? NSDictionary {
                if let items = plist["items"] as? NSArray {
                    if let item = items[0] as? NSDictionary {
                        if let metadata = item["metadata"] as? NSDictionary {
                            if let remoteVersion = metadata["bundle-version"] as? String {
                                completionHandler(remoteVersion)
                                return
                            }
                        }
                    }
                }
            }
            completionHandler(nil)
        })
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(NSURL(string: AuroraDownloadPageURL)!)
        }
    }
}
