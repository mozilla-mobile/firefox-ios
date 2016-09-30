/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SafariServices
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MainViewControllerDelegate, IntroViewControllerDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // If one of the toggles isn't enabled or disabled, this is the first launch. Load the list.
        if Settings.getBool(Settings.KeyBlockAds) == nil {
            Settings.registerDefaults()
        }

        reloadContentBlocker()

        LocalWebServer.sharedInstance.start()

        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = MainViewController()
        mainViewController.delegate = self
        let rootViewController = UINavigationController(rootViewController: mainViewController)
        rootViewController.isNavigationBarHidden = true
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        if !(Settings.getBool(Settings.KeyIntroDone) ?? false) {
            let introViewController = IntroViewController()
            introViewController.delegate = self
            rootViewController.present(introViewController, animated: true, completion: nil)
        }

        displaySplashAnimation()

        return true
    }

    func introViewControllerWillDismiss(_ introViewController: IntroViewController) {
        Settings.set(true, forKey: Settings.KeyIntroDone)
    }

    func mainViewControllerDidToggleList(_ mainViewController: MainViewController) {
        reloadContentBlocker()
    }

    fileprivate func displaySplashAnimation() {
        let splashView = UIView(frame: (window?.frame)!)
        splashView.backgroundColor = UIConstants.Colors.Background
        let logoImage = UIImageView(image: UIImage(named: "Icon"))
        splashView.addSubview(logoImage)
        logoImage.snp.makeConstraints { make in
            make.center.equalTo(splashView)
        }

        window?.addSubview(splashView)

        let animationDuration = 0.25
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            logoImage.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
            }, completion: { success in
                UIView.animate(withDuration: animationDuration, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                    splashView.alpha = 0
                    logoImage.layer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
                    }, completion: { success in
                        splashView.removeFromSuperview()
                })
        })

    }

    fileprivate func reloadContentBlocker() {
        let identifier = AppInfo.ContentBlockerBundleIdentifier
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
            if let error = error {
                NSLog("Failed to reload \(identifier): \(error.localizedDescription)")
            }
        }
    }
}
