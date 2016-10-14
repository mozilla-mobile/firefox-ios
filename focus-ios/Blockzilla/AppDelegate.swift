/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()

        // Re-register the blocking lists at startup in case they've changed.
        Utils.reloadSafariContentBlocker()

        LocalWebServer.sharedInstance.start()

        window = UIWindow(frame: UIScreen.main.bounds)
        let browserViewController = BrowserViewController()
        let rootViewController = UINavigationController(rootViewController: browserViewController)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        URLProtocol.registerClass(LocalContentBlocker.self)

        displaySplashAnimation()

        return true
    }

    fileprivate func displaySplashAnimation() {
        let splashView = UIView(frame: (window?.frame)!)
        splashView.backgroundColor = UIConstants.colors.background
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
}

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
