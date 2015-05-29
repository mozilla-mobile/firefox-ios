/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import AVFoundation

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var browserViewController: BrowserViewController!

    let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Set the Firefox UA for browsing.
        setUserAgent()

        // Start the keyboard helper to monitor and cache keyboard state.
        KeyboardHelper.defaultHelper.startObserving()

        let profile = getProfile(application)

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        setUpWebServer(profile)

        // for aural progress bar: play even with silent switch on, and do not stop audio from other apps (like music)
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error: nil)

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()

        browserViewController = BrowserViewController(profile: profile)

        // Add restoration class, the factory that will return the ViewController we 
        // will restore with.
        browserViewController.restorationIdentifier = NSStringFromClass(BrowserViewController.self)
        browserViewController.restorationClass = AppDelegate.self

        self.window!.rootViewController = browserViewController
        self.window!.backgroundColor = AppConstants.AppBackgroundColor

        NSNotificationCenter.defaultCenter().addObserverForName(FSReadingListAddReadingListItemNotification, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, url = userInfo["URL"] as? NSURL, absoluteString = url.absoluteString {
                let title = (userInfo["Title"] as? String) ?? ""
                profile.readingList?.createRecordWithURL(absoluteString, title: title, addedBy: UIDevice.currentDevice().name)
            }
        }

        return true
    }

    func getProfile(application: UIApplication) -> Profile {
        return BrowserProfile(localName: "profile", app: application)
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        self.window!.makeKeyAndVisible()
        return true
    }

    private func setUpWebServer(profile: Profile) {
        let server = WebServer.sharedInstance
        ReaderModeHandlers.register(server, profile: profile)
        ErrorPageHelper.register(server)
        server.start()
    }

    private func setUserAgent() {
        let currentiOSVersion = UIDevice.currentDevice().systemVersion
        let lastiOSVersion = NSUserDefaults.standardUserDefaults().stringForKey("LastDeviceSystemVersionNumber")
        var firefoxUA = NSUserDefaults.standardUserDefaults().stringForKey("UserAgent")
        if firefoxUA == nil
            || lastiOSVersion != currentiOSVersion {
            let webView = UIWebView()

            NSUserDefaults.standardUserDefaults().setObject(currentiOSVersion,forKey: "LastDeviceSystemVersionNumber")
            let userAgent = webView.stringByEvaluatingJavaScriptFromString("navigator.userAgent")!

            // Extract the WebKit version and use it as the Safari version.
            let webKitVersionRegex = NSRegularExpression(pattern: "AppleWebKit/([^ ]+) ", options: nil, error: nil)!
            let match = webKitVersionRegex.firstMatchInString(userAgent, options: nil, range: NSRange(location: 0, length: count(userAgent)))
            if match == nil {
                println("Error: Unable to determine WebKit version")
                return
            }
            let webKitVersion = (userAgent as NSString).substringWithRange(match!.rangeAtIndex(1))

            // Insert "FxiOS/<version>" before the Mobile/ section.
            let mobileRange = (userAgent as NSString).rangeOfString("Mobile/")
            if mobileRange.location == NSNotFound {
                println("Error: Unable to find Mobile section")
                return
            }

            let mutableUA = NSMutableString(string: userAgent)
            mutableUA.insertString("FxiOS/\(appVersion) ", atIndex: mobileRange.location)
            firefoxUA = "\(mutableUA) Safari/\(webKitVersion)"
            NSUserDefaults.standardUserDefaults().setObject(firefoxUA, forKey: "UserAgent")
        }
        NSUserDefaults.standardUserDefaults().registerDefaults(["UserAgent": firefoxUA!])

        SDWebImageDownloader.sharedDownloader().setValue(firefoxUA, forHTTPHeaderField: "User-Agent")
    }
}

extension AppDelegate: UIApplicationDelegate {
    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(application: UIApplication, shouldRestoreApplicationState code: NSCoder) -> Bool {
        return true
    }
}

extension AppDelegate: UIViewControllerRestoration {
    class func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        // There is only one restorationIdentifier in circulation.
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            return appDelegate.window!.rootViewController
        }
        return nil
    }
}
