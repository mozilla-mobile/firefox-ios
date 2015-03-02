/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Alamofire
import MessageUI

#if MOZ_CHANNEL_AURORA
/*
 A workaround for an issue with MFMailComposerViewController:
http://stackoverflow.com/questions/25604552/i-have-real-misunderstanding-with-mfmailcomposeviewcontroller-in-swift-ios8-in

 Also, MFMailComposeViewController doesn't work in the iOS 8 simulator.
*/
private var mailComposer: MFMailComposeViewController!
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow!
    var profile: Profile!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Setup a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        setupWebServer()

        // Start the keyboard helper to monitor and cache keyboard state.
        KeyboardHelper.defaultHelper.startObserving()

        profile = BrowserProfile(localName: "profile")

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window.backgroundColor = UIColor.whiteColor()

        let controller = BrowserViewController()
        controller.profile = profile
        self.window.rootViewController = controller
        self.window.makeKeyAndVisible()

#if MOZ_CHANNEL_AURORA
        mailComposer = MFMailComposeViewController()
        checkForAuroraUpdate()
        registerFeedbackNotification()
#endif

        return true
    }

#if MOZ_CHANNEL_AURORA
    var naggedAboutAuroraUpdate = false
    func applicationDidBecomeActive(application: UIApplication) {
        if !naggedAboutAuroraUpdate {
            checkForAuroraUpdate()
        }
    }

    func application(application: UIApplication, applicationWillTerminate app: UIApplication) {
        unregisterFeedbackNotification()
    }
    
    func applicationWillResignActive(application: UIApplication) {
        unregisterFeedbackNotification()
    }

    private func registerFeedbackNotification() {
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationUserDidTakeScreenshotNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                // Render the entire screen into a snapshot to attach to the email
                let mainScreen = UIScreen.mainScreen()
                let snapshot = mainScreen.snapshotViewAfterScreenUpdates(true)
                UIGraphicsBeginImageContext(mainScreen.bounds.size)
                snapshot.layer.renderInContext(UIGraphicsGetCurrentContext())
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                self.sendFeedbackMailWithImage(image)
        }
    }
    
    private func unregisterFeedbackNotification() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationUserDidTakeScreenshotNotification, object: nil)
    }
#endif

    private func setupWebServer() {
        let server = WebServer.sharedInstance
        // Register our fonts, which we want to expose to web content that we present in the WebView
        server.registerMainBundleResourcesOfType("ttf", module: "fonts")
        // TODO: In the future let other modules register specific resources here. Unfortunately you cannot add
        // more handlers after start() has been called, so we need to organize it all here at app startup time.
        server.start()
    }
}


#if MOZ_CHANNEL_AURORA
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
                            self.naggedAboutAuroraUpdate = true
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
    
extension AppDelegate: MFMailComposeViewControllerDelegate {
    func sendFeedbackMailWithImage(image: UIImage) {
        let appVersion = NSBundle.mainBundle()
            .objectForInfoDictionaryKey("CFBundleShortVersionString") as String
        let buildNumber = NSBundle.mainBundle()
            .objectForInfoDictionaryKey(kCFBundleVersionKey) as String
        
        if (MFMailComposeViewController.canSendMail()) {
            mailComposer.mailComposeDelegate = self
            mailComposer.setSubject("Feedback on iOS client version v\(appVersion) (\(buildNumber))")
            mailComposer.setToRecipients(["ios-feedback@mozilla.com"])
            
            let imageData = UIImagePNGRepresentation(image)
            mailComposer.addAttachmentData(imageData, mimeType: "image/png", fileName: "feedback.png")
            self.window.rootViewController?.presentViewController(mailComposer,
                animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!,
        didFinishWithResult result: MFMailComposeResult, error: NSError!) {
            controller.dismissViewControllerAnimated(true, completion: { () -> Void in
                mailComposer = nil
                mailComposer = MFMailComposeViewController()
            })
    }
}
#endif
