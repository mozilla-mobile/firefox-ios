/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SafariServices
import UIKit

private let ContentBlockerBundleIdentifier = "org.mozilla.ios.Focus.ContentBlocker"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MainViewControllerDelegate, IntroViewControllerDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // If one of the toggles isn't enabled or disabled, this is the first launch. Load the list.
        if Settings.getBool(Settings.KeyBlockAds) == nil {
            Settings.registerDefaults()
            reloadContentBlocker()
        }

        LocalWebServer.sharedInstance.start()

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let mainViewController = MainViewController()
        mainViewController.delegate = self
        let rootViewController = UINavigationController(rootViewController: mainViewController)
        rootViewController.navigationBarHidden = true
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        if !(Settings.getBool(Settings.KeyIntroDone) ?? false) {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            rootViewController.presentViewController(introViewController, animated: true, completion: nil)
        }

        displaySplashAnimation()

        return true
    }

    func introViewControllerWillDismiss(introViewController: IntroViewController) {
        Settings.set(true, forKey: Settings.KeyIntroDone)
    }

    func mainViewControllerDidToggleList(mainViewController: MainViewController) {
        reloadContentBlocker()
    }

    private func displaySplashAnimation() {
        let splashView = UIView(frame: (window?.frame)!)
        splashView.backgroundColor = UIConstants.Colors.Background
        let logoImage = UIImageView(image: UIImage(named: "Icon"))
        splashView.addSubview(logoImage)
        logoImage.snp_makeConstraints { make in
            make.center.equalTo(splashView)
        }

        window?.addSubview(splashView)

        let animationDuration = 0.25
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: .CurveEaseInOut, animations: {
            logoImage.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
            }, completion: { success in
                UIView.animateWithDuration(animationDuration, delay: 0.0, options: .CurveEaseInOut, animations: {
                    splashView.alpha = 0
                    logoImage.layer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
                    }, completion: { success in
                        splashView.removeFromSuperview()
                })
        })

    }

    private func reloadContentBlocker() {
        SFContentBlockerManager.reloadContentBlockerWithIdentifier(ContentBlockerBundleIdentifier, completionHandler: { (error) -> Void in
            if let error = error {
                NSLog("Failed to reload \(ContentBlockerBundleIdentifier): \(error.description)")
            }
        })
    }
}